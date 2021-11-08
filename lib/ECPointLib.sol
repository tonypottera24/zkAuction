// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {UIntLib} from "./UIntLib.sol";
import {EllipticCurve} from "./EllipticCurve.sol";

struct ECPoint {
    uint256 x;
    uint256 y;
    uint256 z;
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

    function identityElement() internal pure returns (ECPoint memory) {
        return ECPoint(0, 1, 0);
    }

    function g() internal pure returns (ECPoint memory) {
        return ECPoint(GX, GY, 1);
    }

    function z() internal pure returns (ECPoint memory) {
        return scalar(g(), 2);
    }

    function isEmpty(ECPoint memory pt) internal pure returns (bool) {
        return pt.z.isZero();
    }

    function isIdentityElement(ECPoint memory pt) internal pure returns (bool) {
        return pt.z.equals(0);
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
        if (isIdentityElement(pt1)) return isIdentityElement(pt2);
        if (isIdentityElement(pt2)) return isIdentityElement(pt1);

        uint256[4] memory zs; // z1^2, z1^3, z2^2, z2^3
        zs[0] = mulmod(pt1.z, pt1.z, PP);
        zs[1] = mulmod(pt1.z, zs[0], PP);
        zs[2] = mulmod(pt2.z, pt2.z, PP);
        zs[3] = mulmod(pt2.z, zs[2], PP);

        // u1, s1, u2, s2
        zs = [
            mulmod(pt1.x, zs[2], PP),
            mulmod(pt1.y, zs[3], PP),
            mulmod(pt2.x, zs[0], PP),
            mulmod(pt2.y, zs[1], PP)
        ];

        return zs[0] == zs[2] && zs[1] == zs[3];
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

    function pack(ECPoint memory pt) internal pure returns (bytes memory) {
        (uint256 x, uint256 y) = EllipticCurve.toAffine(pt.x, pt.y, pt.z, PP);
        return abi.encodePacked(x, y);
    }

    function inv(ECPoint memory pt) internal pure returns (ECPoint memory) {
        if (isIdentityElement(pt)) return identityElement();
        return ECPoint(pt.x, (PP - pt.y) % PP, pt.z);
    }

    function add(ECPoint memory pt1, ECPoint memory pt2)
        internal
        pure
        returns (ECPoint memory)
    {
        if (isIdentityElement(pt1)) return pt2;
        if (isIdentityElement(pt2)) return pt1;
        (uint256 x, uint256 y, uint256 z) = EllipticCurve.jacAdd(
            pt1.x,
            pt1.y,
            pt1.z,
            pt2.x,
            pt2.y,
            pt2.z,
            AA,
            PP
        );
        return ECPoint(x, y, z);
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
        return add(pt1, inv(pt2));
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
        if (isIdentityElement(pt)) return pt;
        if (k % QQ == 0) return identityElement();
        (uint256 x, uint256 y, uint256 z) = EllipticCurve.jacMul(
            k % QQ,
            pt.x,
            pt.y,
            pt.z,
            AA,
            PP
        );
        return ECPoint(x, y, z);
    }
}
