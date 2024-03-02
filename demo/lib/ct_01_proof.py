from lib.ec_point import ECPoint
import random
from web3 import Web3
from dataclasses import dataclass


@dataclass
class Ct01Proof:
    aa0: ECPoint
    aa1: ECPoint
    bb0: ECPoint
    bb1: ECPoint
    c0: int
    c1: int
    rrr0: int
    rrr1: int

    @classmethod
    def gen(cls, v: int, a: ECPoint, b: ECPoint, r: int, y: ECPoint):
        n = pow(2, 256)
        if v == 0:
            # 1. Simulate the v = 1 proof.
            c1 = random.randrange(0, n)
            rrr1 = random.randrange(1, ECPoint.q)

            bb = b - ECPoint.Z
            aa1 = ECPoint.G * rrr1 - a * c1
            bb1 = y * rrr1 - bb * c1

            # 2. Setup the v = 0 proof.
            rr0 = random.randrange(1, ECPoint.q)
            aa0 = ECPoint.G * rr0
            bb0 = y * rr0

            # 3. Create the challenge for v = 0 proof.
            c = Web3.solidity_keccak(['bytes'], [
                y.pack() + a.pack() + b.pack() + aa0.pack() + bb0.pack() + aa1.pack() + bb1.pack()])
            c = int.from_bytes(c, byteorder='big') % n
            c0 = (c - c1) % n

            # 4. Compute the v = 0 proof.
            rrr0 = (rr0 + c0 * r % ECPoint.q) % ECPoint.q
        else:  # v == 1
            # 1. Simulate the v = 0 proof.
            c0 = random.randrange(0, n)
            rrr0 = random.randrange(1, ECPoint.q)

            aa0 = ECPoint.G * rrr0 - a * c0
            bb0 = y * rrr0 - b * c0

            # 2. Setup the v = 1 proof.
            rr1 = random.randrange(1, ECPoint.q)
            aa1 = ECPoint.G * rr1
            bb1 = y * rr1

            # 3. Create the challenge for v = 1 proof.
            c = Web3.solidity_keccak(['bytes'], [
                y.pack() + a.pack() + b.pack() + aa0.pack() + bb0.pack() + aa1.pack() + bb1.pack()])
            c = int.from_bytes(c, byteorder='big') % n
            c1 = (c - c0) % n

            # 4. Compute the v = 0 proof.
            rrr1 = (rr1 + c1 * r % ECPoint.q) % ECPoint.q

        # 5. proof \pi
        assert(ECPoint.G * rrr0 == aa0 + a * c0)
        assert(ECPoint.G * rrr1 == aa1 + a * c1)
        assert(y * rrr0 == bb0 + b * c0)
        assert(y * rrr1 == bb1 + (b - ECPoint.Z) * c1)
        c = Web3.solidity_keccak(['bytes'], [y.pack(
        ) + a.pack() + b.pack() + aa0.pack() + bb0.pack() + aa1.pack() + bb1.pack()])
        c = int.from_bytes(c, byteorder='big') % n
        assert((c0 + c1) % n == c % n)
        return cls(aa0, aa1, bb0, bb1, c0, c1, rrr0, rrr1)