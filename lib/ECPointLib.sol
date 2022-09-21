// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import {UIntLib} from "./UIntLib.sol";
import {PreCompiledLib} from "./PreCompiledLib.sol";
// import {EllipticCurve} from "./EllipticCurve.sol";

struct ECPoint {
    uint256 x;
    uint256 y;
}

library ECPointLib {
    using UIntLib for uint256;

    uint256 public constant GX = 1;
    uint256 public constant GY = 2;

    uint256 public constant P =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    uint256 public constant Q =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // ECPoint public constant g;

    function identityElement() internal pure returns (ECPoint memory) {
        return ECPoint(0, 0);
    }

    function g() internal pure returns (ECPoint memory) {
        return ECPoint(GX, GY);
    }

    function z() internal returns (ECPoint memory) {
        return scalar(g(), 2);
    }

    function isIdentityElement(ECPoint memory pt) internal pure returns (bool) {
        return pt.x.isZero() && pt.y.isZero();
    }

    function equals(ECPoint memory pt1, ECPoint memory pt2)
        internal
        pure
        returns (bool)
    {
        return pt1.x.equals(pt2.x) && pt1.y.equals(pt2.y);
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
        return abi.encodePacked(pt.x, pt.y);
    }

    function neg(ECPoint memory pt) internal pure returns (ECPoint memory) {
        if (isIdentityElement(pt)) return identityElement();
        return ECPoint(pt.x, (P - pt.y) % P);
    }

    function add(ECPoint memory pt1, ECPoint memory pt2)
        internal
        returns (ECPoint memory)
    {
        if (isIdentityElement(pt1)) return pt2;
        if (isIdentityElement(pt2)) return pt1;
        uint256[2] memory result = PreCompiledLib.bn128Add(
            pt1.x,
            pt1.y,
            pt2.x,
            pt2.y
        );
        return ECPoint(result[0], result[1]);
    }

    function add(ECPoint[] memory pt1, ECPoint[] memory pt2)
        internal
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
        returns (ECPoint memory)
    {
        return add(pt1, neg(pt2));
    }

    function subG(ECPoint memory pt) internal returns (ECPoint memory) {
        return sub(pt, g());
    }

    function subZ(ECPoint memory pt) internal returns (ECPoint memory) {
        return sub(pt, z());
    }

    function scalar(ECPoint memory pt, uint256 k)
        internal
        returns (ECPoint memory)
    {
        if (isIdentityElement(pt)) return pt;
        if (k % Q == 0) return identityElement();
        if (k == 2) return add(pt, pt);
        uint256[2] memory result = PreCompiledLib.bn128ScalarMul(pt.x, pt.y, k);
        return ECPoint(result[0], result[1]);
    }
}
