// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

library PreCompiledLib {
    function bn128Add(
        uint256 ax,
        uint256 ay,
        uint256 bx,
        uint256 by
    ) internal returns (uint256[2] memory result) {
        uint256[4] memory input;
        input[0] = ax;
        input[1] = ay;
        input[2] = bx;
        input[3] = by;
        assembly {
            let success := call(gas(), 0x06, 0, input, 0x80, result, 0x40)
            switch success
            case 0 {
                revert(0, 0)
            }
        }
    }

    function bn128ScalarMul(
        uint256 x,
        uint256 y,
        uint256 scalar
    ) internal returns (uint256[2] memory result) {
        uint256[3] memory input;
        input[0] = x;
        input[1] = y;
        input[2] = scalar;
        assembly {
            let success := call(gas(), 0x07, 0, input, 0x60, result, 0x40)
            switch success
            case 0 {
                revert(0, 0)
            }
        }
    }
}
