import logging
from fastecdsa.curve import Curve
from fastecdsa.point import Point
from dataclasses import dataclass, field

BN128 = Curve(
    'BN128',
    21888242871839275222246405745257275088696311157297823662689037894645226208583,  # p
    0,  # a
    3,  # b
    21888242871839275222246405745257275088548364400416034343698204186575808495617,  # q
    1,  # gx
    2,  # gy
    b'\x2A\x86\x48\xCE\x3D\x03\x01\x07'
)


@dataclass
class ECPoint:
    x: int
    y: int
    pt: Point = field(init=False, repr=False)

    def __post_init__(self):
        if self.x == 0 and self.y == 0:
            self.pt = Point.IDENTITY_ELEMENT
        else:
            self.pt = Point(self.x, self.y, BN128)

    @classmethod
    def from_point(cls, pt: Point):
        assert(pt.x >= 0 and pt.y >= 0)
        return cls(pt.x, pt.y)

    def pack(self):
        return self.x.to_bytes(32, byteorder='big') + self.y.to_bytes(32, byteorder='big')

    def __add__(self, other):
        return ECPoint.from_point(self.pt + other.pt)

    def __sub__(self, other):
        return ECPoint.from_point(self.pt - other.pt)

    def __mul__(self, scalar: int):
        if self.pt == Point.IDENTITY_ELEMENT:
            return ECPoint.from_point(Point.IDENTITY_ELEMENT)
        return ECPoint.from_point(self.pt * scalar)

    def __eq__(self, other):
        return self.pt == other.pt


ECPoint.G = ECPoint.from_point(BN128.G)
ECPoint.Z = ECPoint.G * 2
ECPoint.q = BN128.q
