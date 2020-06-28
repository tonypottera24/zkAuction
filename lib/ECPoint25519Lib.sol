// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import {UIntLib} from "./UIntLib.sol";

struct ECPointExt {
    uint256 x;
    uint256 y;
    uint256 z;
    uint256 t;
}

library ECPointLib {
    using UIntLib for uint256;

    uint256 constant p = 2**255 - 19;
    uint256 constant q = 2**252 + 27742317777372353535851937790883648493;
    uint256 constant d = 37095705934669439343138083508754565189542113879843219016388785533085940283555;
    uint256 constant Gx = 15112221349535400772501151409588531511454012693041857206046113283949847762202;
    uint256 constant Gy = 46316835694926478169428394003475163141307993866256225615783033603165251855960;

    function zero() internal pure returns (ECPointExt memory) {
        return ECPointExt(0, 1, 1, 0);
    }

    function g() internal pure returns (ECPointExt memory) {
        return ECPointExt(Gx, Gy, 1, Gx.mul(Gy, p));
    }

    function z() internal pure returns (ECPointExt memory) {
        return scalar(g(), 2);
    }

    function equals(ECPointExt memory pt1, ECPointExt memory pt2)
        internal
        pure
        returns (bool)
    {
        if (isNotSet(pt1) && isNotSet(pt2)) return true;
        if (isNotSet(pt1) || isNotSet(pt2)) return false;
        return
            pt1.x.div(pt1.z, p).equals(pt2.x.div(pt2.z, p), p) &&
            pt1.y.div(pt1.z, p).equals(pt2.y.div(pt2.z, p), p);
    }

    function isSet(ECPointExt memory pt) internal pure returns (bool) {
        if (
            pt.x.isNotZero(p) ||
            pt.y.isNotZero(p) ||
            pt.z.isNotZero(p) ||
            pt.t.isNotZero(p)
        ) return true;
        return false;
    }

    function isNotSet(ECPointExt memory pt) internal pure returns (bool) {
        if (
            pt.x.isZero(p) && pt.y.isZero(p) && pt.z.isZero(p) && pt.t.isZero(p)
        ) return true;
        return false;
    }

    function isZero(ECPointExt memory pt) internal pure returns (bool) {
        if (isNotSet(pt)) return false;
        if (pt.x.isZero(p) && pt.y.equals(pt.z, p) && pt.y.isZero(p) == false)
            return true;
        return false;
    }

    function pack(ECPointExt memory pt) internal pure returns (bytes memory) {
        if (isNotSet(pt)) return abi.encodePacked(uint256(0), uint256(0));
        return abi.encodePacked(pt.x, pt.y, pt.z, pt.t);
    }

    function neg(ECPointExt memory pt)
        internal
        pure
        returns (ECPointExt memory)
    {
        if (isNotSet(pt)) return pt;
        return scalar(pt, q - 1);
    }

    function add(ECPointExt memory pt1, ECPointExt memory pt2)
        internal
        pure
        returns (ECPointExt memory)
    {
        // add-2008-hwcd, strongly unified.
        if (isNotSet(pt1)) return pt2;
        if (isNotSet(pt2)) return pt1;
        uint256 A = pt1.x.mul(pt2.x, p);
        uint256 B = pt1.y.mul(pt2.y, p);
        uint256 C = pt1.t.mul(d, p).mul(pt2.t, p);
        uint256 D = pt1.z.mul(pt2.z, p);
        uint256 e = pt1.x.add(pt1.y, p).mul(pt2.x.add(pt2.y, p), p);
        uint256 E = e.sub(A, p).sub(B, p);
        uint256 F = D.sub(C, p);
        uint256 G = D.add(C, p);
        uint256 H = B.add(A, p);
        uint256 X3 = E.mul(F, p);
        uint256 Y3 = G.mul(H, p);
        uint256 T3 = E.mul(H, p);
        uint256 Z3 = F.mul(G, p);
        return ECPointExt(X3, Y3, Z3, T3);
    }

    function sub(ECPointExt memory pt1, ECPointExt memory pt2)
        internal
        pure
        returns (ECPointExt memory)
    {
        if (isNotSet(pt2)) return pt1;
        return add(pt1, neg(pt2));
    }

    function double(ECPointExt memory pt)
        internal
        pure
        returns (ECPointExt memory)
    {
        // dbl-2008-hwcd
        if (isNotSet(pt)) return pt;
        uint256 A = pt.x.mul(pt.x, p);
        uint256 B = pt.y.mul(pt.y, p);
        uint256 C = uint256(2).mul(pt.z.mul(pt.z, p), p);
        uint256 D = A.neg(p);
        uint256 e = pt.x.add(pt.y, p);
        uint256 E = e.mul(e, p).sub(A, p).sub(B, p);
        uint256 G = D.add(B, p);
        uint256 F = G.sub(C, p);
        uint256 H = D.sub(B, p);
        uint256 X3 = E.mul(F, p);
        uint256 Y3 = G.mul(H, p);
        uint256 T3 = E.mul(H, p);
        uint256 Z3 = F.mul(G, p);
        return ECPointExt(X3, Y3, Z3, T3);
    }

    function scalar(ECPointExt memory _pt, uint256 _k)
        internal
        pure
        returns (ECPointExt memory)
    {
        if (isNotSet(_pt)) return _pt;
        ECPointExt memory pt = _pt;
        uint256 k = _k.mod(q);
        ECPointExt memory result = zero();
        while (k > 0) {
            if (k & 1 == 1) result = add(result, pt);
            pt = double(pt);
            k >>= 1;
        }
        return result;
    }
}
