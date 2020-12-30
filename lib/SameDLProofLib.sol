// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {ECPointExt, ECPointLib} from "./ECPointLib.sol";
import {Ct, CtLib} from "./CtLib.sol";

struct SameDLProof {
    ECPointExt t1;
    ECPointExt t2;
    uint256 r;
}

library SameDLProofLib {
    using ECPointLib for ECPointExt;

    function valid(
        SameDLProof memory pi,
        ECPointExt memory g1,
        ECPointExt memory g2,
        ECPointExt memory y1,
        ECPointExt memory y2
    ) internal pure returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                g1.pack(),
                g2.pack(),
                y1.pack(),
                y2.pack(),
                pi.t1.pack(),
                pi.t2.pack()
            )
        );
        uint256 c = uint256(digest);
        return
            pi.t1.equals(g1.scalar(pi.r).add(y1.scalar(c))) &&
            pi.t2.equals(g2.scalar(pi.r).add(y2.scalar(c)));
    }

    function valid(
        SameDLProof[] memory pi,
        ECPointExt[] memory g1,
        ECPointExt[] memory g2,
        ECPointExt[] memory y1,
        ECPointExt[] memory y2
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i], g1[i], g2[i], y1[i], y2[i]) == false) return false;
        }
        return true;
    }
}
