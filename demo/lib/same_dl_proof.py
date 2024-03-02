from random import randrange
from web3 import Web3
from lib.ec_point import ECPoint
from dataclasses import dataclass


@dataclass
class SameDLProof:
    grr1: ECPoint
    grr2: ECPoint
    rrr: int

    @classmethod
    def gen(cls, g1: ECPoint, g2: ECPoint, x: int):
        y1, y2 = g1 * x, g2 * x
        rr = randrange(1, ECPoint.q)
        grr1, grr2 = g1 * rr, g2 * rr
        c = Web3.solidity_keccak(['bytes'], [g1.pack() + g2.pack() + y1.pack() + y2.pack() + grr1.pack() + grr2.pack()])
        c = int.from_bytes(c, byteorder='big') % ECPoint.q
        rrr = (rr + (c * x) % ECPoint.q) % ECPoint.q

        assert(g1 * rrr == grr1 + y1 * c)
        assert(g2 * rrr == grr2 + y2 * c)

        return cls(grr1, grr2, rrr)
