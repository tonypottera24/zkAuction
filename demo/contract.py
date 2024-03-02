from dataclasses import dataclass, field
from eth_typing import ChecksumAddress
from web3 import Web3
import logging
from web3.eth import Contract
from seller import Seller
import solcx
import json
from pathlib import Path


@dataclass
class AuctionContract:
    gas_limit: int = 900_000_000_000
    timeout: int = 100_000_000
    provider_port: int = 8545
    sol_path: Path = None
    sol_class: str = "Auction"
    addr: ChecksumAddress = None
    abi: str = None
    sol_filename: str = field(init=False)
    web3: Web3 = field(init=False)
    accounts: list[ChecksumAddress] = field(init=False)

    def __post_init__(self):
        # self.web3 = Web3(Web3.HTTPProvider(f"http://127.0.0.1:{self.provider_port}", request_kwargs={'timeout': self.timeout}))
        self.web3 = Web3(
            Web3.WebsocketProvider(
                f"ws://127.0.0.1:{self.provider_port}",
                websocket_timeout=self.timeout,
                websocket_kwargs={"ping_timeout": None},
            )
        )
        if self.web3.is_connected() == False:
            logging.error("web3 connection failed.")
            exit(1)
        else:
            logging.info("web3 connected!")
        self.accounts = self.web3.eth.accounts
        if self.addr:
            self.contract = self.web3.eth.contract(address=self.addr, abi=self.abi)

    def __print_tx(self, tx_receipt, s: str):
        if tx_receipt["status"] == 0:
            logging.error(f"{s} failed, used {tx_receipt['gasUsed']:,} gas")
            logging.error(tx_receipt)
            exit(1)
        else:
            logging.debug(f"{s} success, used {tx_receipt['gasUsed']:,} gas")

    def __compile(self):
        sources = {}
        with self.sol_path.joinpath(self.sol_filename).open("r") as f:
            sources[self.sol_filename] = {"content": f.read()}
        for lib_file in self.sol_path.joinpath("lib").glob("*.sol"):
            with lib_file.open("r") as f:
                sources[f"lib/{lib_file.name}"] = {"content": f.read()}
        return solcx.compile_standard(
            {
                "language": "Solidity",
                "sources": sources,
                "settings": {
                    "outputSelection": {"*": {"*": ["metadata", "evm.bytecode", "evm.bytecode.sourceMap"]}},
                    "viaIR": True,
                    "optimizer": {
                        "enabled": True,
                    },
                },
            },
            solc_version="0.8.21",
        )

    def deploy(self, seller: Seller):
        if not self.sol_path:
            parent_path = Path(__file__).resolve().parents[1]
            self.sol_path = list(parent_path.glob("*_sol"))[0]
        self.sol_filename = f"{self.sol_class}.sol"
        compiled_sol = self.__compile()
        bytecode = compiled_sol["contracts"][self.sol_filename][self.sol_class]["evm"]["bytecode"]["object"]
        self.abi = json.loads(compiled_sol["contracts"][self.sol_filename][self.sol_class]["metadata"])["output"]["abi"]
        auction_contract = self.web3.eth.contract(abi=self.abi, bytecode=bytecode)
        tx_hash = auction_contract.constructor(seller.M, seller.L, seller.timeout, seller.minimum_stake).transact(
            {"from": seller.addr, "gas": self.gas_limit}
        )
        tx_receipt = self.web3.eth.wait_for_transaction_receipt(tx_hash, timeout=self.timeout)
        self.__print_tx(tx_receipt, "Contract created")
        # logging.debug(f"addr = {tx_receipt.contractAddress}")
        self.addr = tx_receipt.contractAddress
        self.contract = self.web3.eth.contract(address=tx_receipt.contractAddress, abi=self.abi)
        return self.addr

    @property
    def functions(self):
        return self.contract.functions

    def transact(self, bidder, function, value: int = None) -> int:
        param = {"from": bidder.addr, "gas": self.gas_limit}
        if value:
            param["value"] = value
        tx_hash = function.transact(param)
        tx_receipt = self.web3.eth.wait_for_transaction_receipt(tx_hash, timeout=self.timeout)
        self.__print_tx(tx_receipt, f"B{bidder.index}")
        return tx_receipt["gasUsed"]
