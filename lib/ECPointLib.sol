// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {UIntLib} from "./UIntLib.sol";
import {EllipticCurve} from "./EllipticCurve.sol";

struct ECPoint {
    uint256 x;
    uint256 y;
}

library ECPointLib {
    using UIntLib for uint256;

    uint256 public constant GX =
        48439561293906451759052585252797914202762949526041747995844080717082404635286;
    uint256 public constant GY =
        36134250956749795798585127919587881956611106672985015071877198253568414405109;
    uint256 public constant AA =
        115792089210356248762697446949407573530086143415290314195533631308867097853948;
    uint256 public constant BB =
        41058363725152142129326129780047268409114441015993725554835256314039467401291;
    uint256 public constant PP =
        115792089210356248762697446949407573530086143415290314195533631308867097853951;
    uint256 public constant QQ =
        115792089210356248762697446949407573529996955224135760342422259061068512044369;

    function zero() internal pure returns (ECPoint memory) {
        return ECPoint(0, 1);
    }

    function g() internal pure returns (ECPoint memory) {
        return ECPoint(GX, GY);
    }

    function z() internal pure returns (ECPoint memory) {
        return scalar(g(), 2);
    }

    function isEmpty(ECPoint memory pt) internal pure returns (bool) {
        return pt.x.isZero() && pt.y.isZero();
    }

    function isEmpty(ECPoint[] memory pt) internal pure returns (bool) {
        for (uint256 i = 0; i < pt.length; i++) {
            if (isEmpty(pt[i]) == false) return false;
        }
        return true;
    }

    function equals(ECPoint memory pt1, ECPoint memory pt2)
        internal
        pure
        returns (bool)
    {
        return pt1.x == pt2.x && pt1.y == pt2.y;
    }

    function equals(ECPoint[] memory pt1, ECPoint[] memory pt2)
        internal
        pure
        returns (bool)
    {
        if (pt1.length != pt2.length) return false;
        for (uint256 i = 0; i < pt1.length; i++) {
            if (equals(pt1[i], pt2[i]) == false) return false;
        }
        return true;
    }

    function isIdentityElement(ECPoint memory pt) internal pure returns (bool) {
        return pt.x == 0 && pt.y == 1;
    }

    function pack(ECPoint memory pt) internal pure returns (bytes memory) {
        return abi.encodePacked(pt.x, pt.y);
    }

    function add(ECPoint memory pt1, ECPoint memory pt2)
        internal
        pure
        returns (ECPoint memory)
    {
        (uint256 x, uint256 y) = EllipticCurve.ecAdd(
            pt1.x,
            pt1.y,
            pt2.x,
            pt2.y,
            AA,
            PP
        );
        return ECPoint(x, y);
    }

    function add(ECPoint[] memory pt1, ECPoint[] memory pt2)
        internal
        pure
        returns (ECPoint[] memory)
    {
        require(pt1.length == pt2.length, "a.length != b.length");
        ECPoint[] memory result = new ECPoint[](pt1.length);
        for (uint256 i = 0; i < pt1.length; i++) {
            result[i] = add(pt1[i], pt2[i]);
        }
        return result;
    }

    function sub(ECPoint memory pt1, ECPoint memory pt2)
        internal
        pure
        returns (ECPoint memory)
    {
        (uint256 x, uint256 y) = EllipticCurve.ecSub(
            pt1.x,
            pt1.y,
            pt2.x,
            pt2.y,
            AA,
            PP
        );
        return ECPoint(x, y);
    }

    function subG(ECPoint memory pt) internal pure returns (ECPoint memory) {
        return sub(pt, g());
    }

    function subZ(ECPoint memory pt) internal pure returns (ECPoint memory) {
        return sub(pt, z());
    }

    function scalar(ECPoint memory pt, uint256 k)
        internal
        pure
        returns (ECPoint memory)
    {
        (uint256 x, uint256 y) = EllipticCurve.ecMul(
            k % QQ,
            pt.x,
            pt.y,
            AA,
            PP
        );
        return ECPoint(x, y);
    }
}
