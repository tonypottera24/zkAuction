#!/usr/bin/env python3

import json
import sys
from eth_typing import ChecksumAddress
from lib.ct_m_proof import CtMProof
from random import randrange
from lib.dl_proof import DLProof
from lib.same_dl_proof import SameDLProof
import time
from lib.ct import Ct
from lib.ec_point import BN128, ECPoint
from fastecdsa import keys
import logging
import argparse
from dataclasses import astuple, dataclass, field
from contract import AuctionContract


@dataclass
class Bidder:
    contract_path: str = "contract.json"
    port: int = 8545
    index: int = 1
    x: int = field(default_factory=lambda: keys.gen_private_key(BN128))
    y: ECPoint = field(init=False)
    gas_used: int = 0

    def __post_init__(self):
        logging.info(f"B{self.index}: Phase 0. Initializing...")
        with open(self.contract_path, "r") as fp:
            c = json.load(fp)
        self.contract = AuctionContract(provider_port=self.port, addr=c["addr"], abi=c["abi"])
        self.addr = self.contract.accounts[self.index]
        y = keys.get_public_key(self.x, BN128)
        self.y = ECPoint.from_point(y)
        logging.info(f"B{self.index}: Phase 0. Initializing... successed")

    def phase_1_bidder_init(self):
        logging.info(f"B{self.index}: Phase 1. Sending pk and stake...")
        pi = DLProof.gen(ECPoint.G, self.x)
        f = self.contract.functions.phase1BidderInit(astuple(self.y), astuple(pi))
        minimum_stake = self.contract.functions.minimumStake().call()
        logging.info(f"B{self.index}: Phase 1. minimum stake is {minimum_stake}")
        self.gas_used += self.contract.transact(self, f, minimum_stake)
        logging.info(f"B{self.index}: Phase 1. Sending pk and stake... successed")

    def phase_2_bidder_submit_bid(self, bid):
        logging.info(f"B{self.index}: Phase 2. Submitting bidding vector...")
        self.bid = bid
        pk = ECPoint(*self.contract.functions.pk().call())
        L = self.contract.functions.L().call()
        self.V = [Ct.from_zt((self.bid >> j) & 1, pk) for j in range(L)]
        # logging.debug(f'B{self.index}: bid {self.bid}')

        V_sol = [astuple(Vj) for Vj in self.V]
        V_01_proof_sol = [astuple(Vj.gen_01_proof(pk)) for Vj in self.V]

        self.C, self.W = Ct.from_zt(1, pk), Ct.from_zt(0, pk)
        C_sol, W_sol = astuple(self.C), astuple(self.W)
        C_proof_sol = astuple(CtMProof.gen(self.C, pk, 1))
        W_proof_sol = astuple(CtMProof.gen(self.W, pk, 0))

        f = self.contract.functions.phase2BidderSubmitBid(V_sol, V_01_proof_sol, C_sol, C_proof_sol, W_sol, W_proof_sol)
        self.gas_used += self.contract.transact(self, f)
        logging.info(f"B{self.index}: Phase 2. Submitting bidding vector... successed")

    def phase_3_zk_and(self):
        pk = ECPoint(*self.contract.functions.pk().call())
        roundJ = self.contract.functions.roundJ().call()
        logging.info(f"B{self.index}: Phase 3. round {roundJ}, ZkAnd...")

        s = self.V[roundJ].t * self.C.t

        self.S = Ct.from_zt(s, pk)
        c4 = self.C + self.V[roundJ] - (self.S + self.S)
        print(f"B{self.index}: S.t = {self.S.t}, C.t = {self.C.t}, V.t = {self.V[roundJ].t}")

        S_sol = astuple(self.S)
        pi_3_sol = astuple(self.S.gen_01_proof(pk))
        pi_4_sol = astuple(c4.gen_01_proof(pk))

        f = self.contract.functions.phase3ZkAnd(S_sol, pi_3_sol, pi_4_sol)
        self.gas_used += self.contract.transact(self, f)
        logging.info(f"B{self.index}: Phase 3. round {roundJ}, ZkAnd... successed")

    def phase_3_mix(self):
        logging.info(f"B{self.index}: Phase 3, Mix...")
        M = self.contract.functions.M().call()
        cts = [Ct(*self.contract.functions.WSTotalzM(k).call()) for k in range(M + 1)]

        mixed_ws = []
        pis = []
        for ct in cts:
            a = randrange(1, ECPoint.q)
            mixed_ws.append(ct * a)
            pis.append(SameDLProof.gen(ct.u, ct.c, a))

        mixed_ws_sols = [astuple(ct) for ct in mixed_ws]
        pi_sols = [astuple(pi) for pi in pis]

        f = self.contract.functions.phase3Mix(mixed_ws_sols, pi_sols)
        self.gas_used += self.contract.transact(self, f)
        logging.info(f"B{self.index}: Phase 3, Mix... successed")

    def phase_3_match(self):
        logging.info(f"B{self.index}: Phase 3, Match...")
        M = self.contract.functions.M().call()
        cts = [Ct(*self.contract.functions.mixedWS(k).call()) for k in range(M + 1)]
        uxs, pis = zip(*[ct.gen_decrypt_msg(self.x) for ct in cts])
        ux_sols = [astuple(ux) for ux in uxs]
        pi_sols = [astuple(pi) for pi in pis]

        f = self.contract.functions.phase3Match(ux_sols, pi_sols)
        self.gas_used += self.contract.transact(self, f)
        logging.info(f"B{self.index}: Phase 3, Match... successed")

    def phase_4_winner_decision(self):
        logging.info(f"B{self.index}: Phase 4, Winner decision...")
        pk = ECPoint(*self.contract.functions.pk().call())
        pi = CtMProof.gen(self.W, pk, 1)

        f = self.contract.functions.phase4WinnerDecision(astuple(pi))
        self.gas_used += self.contract.transact(self, f)
        logging.info(f"B{self.index}: Phase 4, Winner decision... successed")

    def phase_1_wait_until_success(self):
        logging.info(f"B{self.index}: Phase 1. Waiting for phase 1 ends...")
        while not self.contract.functions.phase1Success().call():
            t0 = self.contract.functions.timer(1).call()
            t = t0[0] + t0[1]
            dt = t - time.time()
            t = max(dt, 1) + 2
            logging.info(f"B{self.index}: Phase 1: Wait for {t:.2f} sec")
            time.sleep(t)
            # time.sleep(1)
        logging.info(f"B{self.index}: Phase 1. Waiting for phase 1 ends... successed")

    def phase_2_wait_until_success(self):
        while not self.contract.functions.phase2Success().call():
            time.sleep(1)

    def phase_3_zk_and_wait_until_success(self):
        while not self.contract.functions.phase3ZkAndSuccess().call():
            time.sleep(1)

    def phase_3_mix_wait_until_success(self):
        while not self.contract.functions.phase3MixSuccess().call():
            time.sleep(1)

    def phase_3_match_wait_until_success(self):
        while not self.contract.functions.phase3MatchSuccess().call():
            time.sleep(1)

    def phase_4_wait_until_success(self):
        while not self.contract.functions.phase4Success().call():
            time.sleep(1)

    def get_m1st_price(self):
        m1st_price_binary = []
        L = self.contract.functions.L().call()
        for j in range(L):
            m1st_price_binary.append(self.contract.functions.m1stPrice(j).call())
        return int("".join(str(b) for b in reversed(m1st_price_binary)), 2)

    def start(self, bid):
        self.phase_1_bidder_init()
        self.phase_1_wait_until_success()

        self.phase_2_bidder_submit_bid(bid)
        self.phase_2_wait_until_success()

        L = self.contract.functions.L().call()
        for roundJ in reversed(range(L)):
            assert roundJ == self.contract.functions.roundJ().call()

            self.phase_3_zk_and()
            self.phase_3_zk_and_wait_until_success()

            self.phase_3_mix()
            self.phase_3_mix_wait_until_success()

            self.phase_3_match()
            self.phase_3_match_wait_until_success()

            if not self.contract.functions.m1stPrice(roundJ).call():
                self.C -= self.S
                self.W += self.S
            else:
                self.C = self.S

        if self.W.t == 1:
            self.phase_4_winner_decision()
            logging.info(f"B{self.index} bid {self.bid} WIN, pays {self.get_m1st_price()}")
        else:
            logging.info(f"B{self.index} bid {self.bid} LOSE, M+1st price is {self.get_m1st_price()}")
        logging.info(f"B{self.index} used {self.gas_used:,} gas")


if __name__ == "__main__":
    logging.basicConfig(stream=sys.stderr, level=logging.INFO)

    parser = argparse.ArgumentParser()
    parser.add_argument("--port", help="web3 provider port", type=int, default=8545)
    parser.add_argument("-i", "--index", help="index of account", type=int, required=True)
    parser.add_argument(
        "-c",
        "--contract",
        help="contract addr and abi json",
        type=str,
        default="contract.json",
    )
    parser.add_argument("-b", "--bid", help="bidding price", type=int, required=True)
    args = parser.parse_args()

    bidder = Bidder(index=args.index, port=args.port, contract_path=args.contract)
    bidder.start(args.bid)
