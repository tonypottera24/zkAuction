// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import {UIntLib} from "./UIntLib.sol";
import {EllipticCurve} from "./EllipticCurve.sol";

struct ECPointExt {
    uint256 x;
    uint256 y;
}

library ECPointLib {
    using UIntLib for uint256;

    uint256
        public constant GX = 48439561293906451759052585252797914202762949526041747995844080717082404635286;
    uint256
        public constant GY = 36134250956749795798585127919587881956611106672985015071877198253568414405109;
    uint256
        public constant AA = 115792089210356248762697446949407573530086143415290314195533631308867097853948;
    uint256
        public constant BB = 41058363725152142129326129780047268409114441015993725554835256314039467401291;
    uint256
        public constant PP = 115792089210356248762697446949407573530086143415290314195533631308867097853951;

    function zero() internal pure returns (ECPointExt memory) {
        return ECPointExt(0, 1);
    }

    function g() internal pure returns (ECPointExt memory) {
        return ECPointExt(GX, GY);
    }

    function z() internal pure returns (ECPointExt memory) {
        return scalar(g(), 2);
    }

    function isSet(ECPointExt memory pt) internal pure returns (bool) {
        return pt.x.isNotZero(PP) || pt.y.isNotZero(PP);
    }

    function isNotSet(ECPointExt memory pt) internal pure returns (bool) {
        return isSet(pt) == false;
    }

    function equals(ECPointExt memory pt1, ECPointExt memory pt2)
        internal
        pure
        returns (bool)
    {
        if (isNotSet(pt1) && isNotSet(pt2)) return true;
        if (isNotSet(pt1) || isNotSet(pt2)) return false;
        return pt1.x.equals(pt2.x, PP) && pt1.y.equals(pt2.y, PP);
    }

    function isZero(ECPointExt memory pt) internal pure returns (bool) {
        if (isNotSet(pt)) return false;
        if (pt.x.isZero(PP) && pt.y.equals(1, PP)) return true;
        return false;
    }

    function pack(ECPointExt memory pt) internal pure returns (bytes memory) {
        return abi.encodePacked(pt.x, pt.y);
    }

    function add(ECPointExt memory pt1, ECPointExt memory pt2)
        internal
        pure
        returns (ECPointExt memory)
    {
        // add-2008-hwcd, strongly unified.
        if (isNotSet(pt1)) return pt2;
        if (isNotSet(pt2)) return pt1;
        if (isZero(pt1)) return pt2;
        if (isZero(pt2)) return pt1;
        (uint256 x, uint256 y) = EllipticCurve.ecAdd(
            pt1.x,
            pt1.y,
            pt2.x,
            pt2.y,
            AA,
            PP
        );
        return ECPointExt(x, y);
    }

    function sub(ECPointExt memory pt1, ECPointExt memory pt2)
        internal
        pure
        returns (ECPointExt memory)
    {
        if (isNotSet(pt2)) return pt1;
        if (isZero(pt2)) return pt1;
        (uint256 x, uint256 y) = EllipticCurve.ecSub(
            pt1.x,
            pt1.y,
            pt2.x,
            pt2.y,
            AA,
            PP
        );
        return ECPointExt(x, y);
    }

    function scalar(ECPointExt memory pt, uint256 k)
        internal
        pure
        returns (ECPointExt memory)
    {
        if (isNotSet(pt)) return pt;
        if (isZero(pt)) return pt;
        if (k == 0) return zero();
        (uint256 x, uint256 y) = EllipticCurve.ecMul(k, pt.x, pt.y, AA, PP);
        return ECPointExt(x, y);
    }
}
