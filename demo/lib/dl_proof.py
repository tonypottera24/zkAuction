from random import randrange
from web3 import Web3
from lib.ec_point import ECPoint
from dataclasses import dataclass


@dataclass
class DLProof:
    grr: ECPoint
    rrr: int

    @classmethod
    def gen(cls, g: ECPoint, x: int):
        y = g * x
        rr = randrange(1, ECPoint.q)
        grr = g * rr
        c = Web3.solidity_keccak(['bytes'], [g.pack() + y.pack() + grr.pack()])
        c = int.from_bytes(c, byteorder='big') % ECPoint.q
        rrr = (rr + (c * x) % ECPoint.q) % ECPoint.q

        assert(g * rrr == grr + y * c)

        return cls(grr, rrr)
