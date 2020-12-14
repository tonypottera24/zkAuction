// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {ECPointExt, ECPointLib} from "./ECPointLib.sol";

struct DLProof {
    ECPointExt t;
    uint256 r;
}

library DLProofLib {
    using ECPointLib for ECPointExt;

    function valid(
        DLProof memory pi,
        ECPointExt memory g,
        ECPointExt memory y
    ) internal pure returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(g.pack(), y.pack(), pi.t.pack())
        );
        uint256 c = uint256(digest);
        return pi.t.equals(g.scalar(pi.r).add(y.scalar(c)));
    }
}
