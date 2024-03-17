from lib.ct_01_proof import Ct01Proof
from random import randrange
from lib.same_dl_proof import SameDLProof
from lib.ec_point import ECPoint
from dataclasses import dataclass, field


@dataclass
class Ct:
    u: ECPoint
    c: ECPoint
    t: int = field(repr=False, default=None)
    r: int = field(repr=False, default=None)

    def __post_init__(self):
        if type(self.u) is tuple:
            self.u = ECPoint(*self.u)
        if type(self.c) is tuple:
            self.c = ECPoint(*self.c)

    @classmethod
    def from_zt(cls, t: int, y: ECPoint):
        r = randrange(1, ECPoint.q)
        u = ECPoint.G * r
        zt = ECPoint.Z * t
        c = zt + y * r
        return cls(u, c, t=t, r=r)

    def __add__(self, other):
        return Ct(
            self.u + other.u, self.c + other.c, t=(self.t + other.t) % ECPoint.q, r=(self.r + other.r) % ECPoint.q
        )

    def __sub__(self, other):
        return Ct(
            self.u - other.u,
            self.c - other.c,
            t=(self.t - other.t + ECPoint.q) % ECPoint.q,
            r=(self.r - other.r + ECPoint.q) % ECPoint.q,
        )

    def __mul__(self, scalar: int):
        u = self.u * scalar
        c = self.c * scalar
        if self.r:
            return Ct(u, c, t=(self.t * scalar) % ECPoint.q, r=(self.r * scalar) % ECPoint.q)
        else:
            return Ct(u, c)

    def gen_01_proof(self, y: ECPoint):
        return Ct01Proof.gen(self.t, self.u, self.c, self.r, y)

    def gen_decrypt_msg(self, x: int):
        ux = self.u * x
        pi = SameDLProof.gen(self.u, ECPoint.G, x)
        return ux, pi
