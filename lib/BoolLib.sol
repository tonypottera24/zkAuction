// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library BoolLib {
    function equals(bool a, bool b) internal pure returns (bool) {
        return a == b;
    }

    function equals(bool[] memory a, bool[] memory b)
        internal
        pure
        returns (bool)
    {
        if (a.length != b.length) return false;
        for (uint256 i = 0; i < a.length; i++) {
            if (equals(a[i], b[i]) == false) return false;
        }
        return true;
    }

    function isTrue(bool[] memory a) internal pure returns (bool) {
        if (a.length == 0) return false;
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] == false) return false;
        }
        return true;
    }
}
