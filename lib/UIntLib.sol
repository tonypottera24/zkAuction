// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

library UIntLib {
    // Pre-computed constant for 2 ** 255
    uint256
        private constant U255_MAX_PLUS_1 = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function mod(uint256 a, uint256 p) internal pure returns (uint256) {
        return a % p;
    }

    function isZero(uint256 a, uint256 p) internal pure returns (bool) {
        return mod(a, p) == 0;
    }

    function isNotZero(uint256 a, uint256 p) internal pure returns (bool) {
        return isZero(a, p) == false;
    }

    function equals(
        uint256 a,
        uint256 b,
        uint256 p
    ) internal pure returns (bool) {
        return mod(a, p) == mod(b, p);
    }

    function neg(uint256 a, uint256 p) internal pure returns (uint256) {
        return p - mod(a, p);
    }

    function add(
        uint256 a,
        uint256 b,
        uint256 p
    ) internal pure returns (uint256) {
        return addmod(a, b, p);
    }

    function sub(
        uint256 a,
        uint256 b,
        uint256 p
    ) internal pure returns (uint256) {
        return addmod(a, neg(b, p), p);
    }

    function mul(
        uint256 a,
        uint256 b,
        uint256 p
    ) internal pure returns (uint256) {
        return mulmod(a, b, p);
    }

    function div(
        uint256 a,
        uint256 b,
        uint256 p
    ) internal pure returns (uint256) {
        return mulmod(a, inv(b, p), p);
    }

    function inv(uint256 _x, uint256 _pp) internal pure returns (uint256) {
        require(_x != 0 && _x != _pp && _pp != 0, "Invalid number");
        uint256 q = 0;
        uint256 newT = 1;
        uint256 r = _pp;
        uint256 t;
        while (_x != 0) {
            t = r / _x;
            (q, newT) = (newT, addmod(q, (_pp - mulmod(t, newT, _pp)), _pp));
            (r, _x) = (_x, r - t * _x);
        }
        return q;
    }

    function pow(
        uint256 _a,
        uint256 _k,
        uint256 p
    ) internal pure returns (uint256) {
        uint256 a = mod(_a, p);
        uint256 k = _k;
        uint256 result = 1;
        while (k > 0) {
            if (k & 1 == 1) result = mul(result, a, p);
            a = mul(a, a, p);
            k >>= 1;
        }
        return result;
    }
}
