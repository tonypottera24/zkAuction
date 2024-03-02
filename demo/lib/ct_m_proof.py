from lib.ct import Ct
from lib.same_dl_proof import SameDLProof
from lib.dl_proof import DLProof
from lib.ec_point import ECPoint
import random
from dataclasses import dataclass


@dataclass
class CtMProof:
    pi: SameDLProof

    @classmethod
    def gen(cls, ct: Ct, y: ECPoint, m: int):
        zm = ECPoint.Z * m
        pi = SameDLProof.gen(ECPoint.G, y, ct.r)
        assert(ECPoint.G * ct.r == ct.u)
        assert(y * ct.r == ct.c - zm)
        return cls(pi)
