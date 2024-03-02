#!/usr/bin/env python3

import argparse
import json
import logging
from dataclasses import dataclass
import sys


@dataclass
class Seller:
    M: int
    L: int
    timeout: list
    index: int = 0
    port: int = 8545
    minimum_stake: int = 10

    def __post_init__(self):
        from contract import AuctionContract

        self.contract = AuctionContract(provider_port=self.port)
        self.addr = self.contract.accounts[self.index]

    def deploy(self, filename="contract.json"):
        self.contract.deploy(self)
        logging.info(f"Seller: Contract addr {self.contract.addr}")
        d = {"addr": self.contract.addr, "abi": self.contract.abi}
        with open(filename, "w") as fp:
            json.dump(d, fp)

    def get_m1st_price(self):
        m1st_price_binary = []
        for j in range(self.L):
            m1st_price_binary.append(self.contract.functions.m1stPrice(j).call())
        return int("".join(str(b) for b in reversed(m1st_price_binary)), 2)


if __name__ == "__main__":
    logging.basicConfig(stream=sys.stderr, level=logging.INFO)
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", help="web3 provider port", type=int, default=8545)
    parser.add_argument("-i", "--index", help="index of account", type=int, default=0)
    parser.add_argument("-M", help="number of goods", type=int, default=1)
    parser.add_argument("-L", help="length of bidding vector", type=int, required=True)
    parser.add_argument("-s", "--stake", help="minimum stake", type=int, default=10)
    parser.add_argument("-t", "--timeout", help="timeout for each phase", type=int, default=10)
    parser.add_argument("-o", "--output", help="contract json for addr and abi", type=str, default="contract.json")
    args = parser.parse_args()

    timeout = [1, args.timeout, args.timeout, args.timeout * args.L, args.timeout]
    seller = Seller(M=args.M, L=args.L, index=args.index, port=args.port, minimum_stake=args.stake, timeout=timeout)
    seller.deploy(filename=args.output)
