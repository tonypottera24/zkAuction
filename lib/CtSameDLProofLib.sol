// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";
import {Ct, CtLib} from "./CtLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";

struct CtSameDLProof {
    SameDLProof u1;
    SameDLProof u2;
    SameDLProof c;
}

library CtSameDLProofLib {
    using BigNumberLib for BigNumber.instance;
    using CtLib for Ct;
    using CtLib for Ct[];
    using SameDLProofLib for SameDLProof;

    function valid(
        CtSameDLProof memory pi,
        Ct memory g1,
        Ct memory g2,
        Ct memory y1,
        Ct memory y2,
        BigNumber.instance storage p,
        BigNumber.instance storage q
    ) internal view returns (bool) {
        return
            pi.u1.valid(g1.u1, g2.u1, y1.u1, y2.u1, p, q) &&
            pi.u2.valid(g1.u2, g2.u2, y1.u2, y2.u2, p, q) &&
            pi.c.valid(g1.c, g2.c, y1.c, y2.c, p, q);
    }

    function valid(
        CtSameDLProof[] memory pi,
        Ct[] memory g1,
        Ct[] memory g2,
        Ct[] memory y1,
        Ct[] memory y2,
        BigNumber.instance storage p,
        BigNumber.instance storage q
    ) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i], g1[i], g2[i], y1[i], y2[i], p, q) == false)
                return false;
        }
        return true;
    }
}
