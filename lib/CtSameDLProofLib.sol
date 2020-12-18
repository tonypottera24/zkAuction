// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Ct, CtLib} from "./CtLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";

struct CtSameDLProof {
    SameDLProof[] u;
    SameDLProof c;
}

library CtSameDLProofLib {
    using CtLib for Ct;
    using CtLib for Ct[];
    using SameDLProofLib for SameDLProof;

    function valid(
        CtSameDLProof memory pi,
        Ct memory g1,
        Ct memory g2,
        Ct memory y1,
        Ct memory y2
    ) internal view returns (bool) {
        for (uint256 i = 0; i < pi.u.length; i++) {
            if (pi.u[i].valid(g1.u[i], g2.u[i], y1.u[i], y2.u[i]) == false) {
                return false;
            }
        }
        return pi.c.valid(g1.c, g2.c, y1.c, y2.c);
    }

    function valid(
        CtSameDLProof[] memory pi,
        Ct[] memory g1,
        Ct[] memory g2,
        Ct[] memory y1,
        Ct[] memory y2
    ) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i], g1[i], g2[i], y1[i], y2[i]) == false) return false;
        }
        return true;
    }
}
