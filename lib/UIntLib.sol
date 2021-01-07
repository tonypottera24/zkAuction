// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {ECPoint, ECPointLib} from "./ECPointLib.sol";

library UIntLib {
    // Pre-computed constant for 2 ** 255
    uint256 private constant U255_MAX_PLUS_1 =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function modP(uint256 a) internal pure returns (uint256) {
        return a % ECPointLib.PP;
    }

    function modQ(uint256 a) internal pure returns (uint256) {
        return a % ECPointLib.QQ;
    }

    function isZero(uint256 a) internal pure returns (bool) {
        return modP(a) == 0;
    }

    function equals(uint256 a, uint256 b) internal pure returns (bool) {
        return modP(a) == modP(b);
    }

    function add(
        uint256 a,
        uint256 b,
        uint256 p
    ) internal pure returns (uint256) {
        return addmod(a, b, p);
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mulmod(a, b, ECPointLib.PP);
    }

    function inv(uint256 _x) internal pure returns (uint256) {
        require(_x != 0, "Invalid number");
        uint256 q = 0;
        uint256 newT = 1;
        uint256 r = ECPointLib.PP;
        uint256 t;
        while (_x != 0) {
            t = r / _x;
            (q, newT) = (
                newT,
                addmod(
                    q,
                    (ECPointLib.PP - mulmod(t, newT, ECPointLib.PP)),
                    ECPointLib.PP
                )
            );
            (r, _x) = (_x, r - t * _x);
        }
        return q;
    }
}
