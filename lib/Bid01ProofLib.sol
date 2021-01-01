// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {ECPointExt, ECPointLib} from "./ECPointLib.sol";
import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {Ct, CtLib} from "./CtLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";
import {CtSameDLProof, CtSameDLProofLib} from "./CtSameDLProofLib.sol";

struct Bid01Proof {
    Ct ctU;
    Ct ctUU;
    Ct ctV;
    Ct ctVV;
    Ct ctA;
    Ct ctAA;
}

library Bid01ProofLib {
    using ECPointLib for ECPointExt;
    using CtLib for Ct;
    using CtLib for Ct[];
    using SameDLProofLib for SameDLProof;
    using CtSameDLProofLib for CtSameDLProof;

    function stageU(Bid01Proof storage pi) internal view returns (bool) {
        return
            pi.ctU.isNotSet() &&
            pi.ctUU.isNotSet() &&
            pi.ctV.isNotSet() &&
            pi.ctVV.isNotSet() &&
            pi.ctA.isNotSet() &&
            pi.ctAA.isNotSet();
    }

    function stageV(Bid01Proof storage pi) internal view returns (bool) {
        return
            pi.ctU.isNotSet() == false &&
            pi.ctUU.isNotSet() == false &&
            pi.ctV.isNotSet() &&
            pi.ctVV.isNotSet() &&
            pi.ctA.isNotSet() &&
            pi.ctAA.isNotSet();
    }

    function stageA(Bid01Proof storage pi) internal view returns (bool) {
        return
            pi.ctU.isNotSet() == false &&
            pi.ctUU.isNotSet() == false &&
            pi.ctV.isNotSet() == false &&
            pi.ctVV.isNotSet() == false;
    }

    function stageA(Bid01Proof[] storage pi) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (stageA(pi[i]) == false) return false;
        }
        return true;
    }

    function setU(Bid01Proof storage pi, Ct memory bidU) internal {
        require(stageU(pi), "Not in stageU.");
        (pi.ctU, pi.ctUU) = (bidU, bidU.subZ());
    }

    function setU(Bid01Proof[] storage pi, Ct[] memory bidU) internal {
        require(pi.length == bidU.length, "pi, bidU must have same length.");
        for (uint256 i = 0; i < pi.length; i++) {
            setU(pi[i], bidU[i]);
        }
    }

    function setV(
        Bid01Proof storage pi,
        Ct memory ctV,
        Ct memory ctVV,
        CtSameDLProof memory piSDL
    ) internal {
        require(stageV(pi), "Not in stageV.");
        require(
            piSDL.valid(pi.ctU, pi.ctUU, ctV, ctVV),
            "Same discrete log verification failed."
        );
        (pi.ctV, pi.ctVV) = (ctV, ctVV);
        (pi.ctA, pi.ctAA) = (ctV, ctVV);
    }

    function setV(
        Bid01Proof[] storage pi,
        Ct[] memory ctV,
        Ct[] memory ctVV,
        CtSameDLProof[] memory piSDL
    ) internal {
        for (uint256 i = 0; i < pi.length; i++) {
            setV(pi[i], ctV[i], ctVV[i], piSDL[i]);
        }
    }

    function setA(
        Bid01Proof storage pi,
        Bidder storage bidder,
        ECPointExt memory uxV,
        SameDLProof memory piVSDL,
        ECPointExt memory uxVV,
        SameDLProof memory piVVSDL
    ) internal {
        require(stageA(pi), "Not in stageA.");
        pi.ctA = pi.ctA.decrypt(bidder, uxV, piVSDL);
        pi.ctAA = pi.ctAA.decrypt(bidder, uxVV, piVVSDL);
    }

    function setA(
        Bid01Proof[] storage pi,
        Bidder storage bidder,
        ECPointExt[] memory uxV,
        SameDLProof[] memory piVSDL,
        ECPointExt[] memory uxVV,
        SameDLProof[] memory piVVSDL
    ) internal {
        for (uint256 i = 0; i < pi.length; i++) {
            setA(pi[i], bidder, uxV[i], piVSDL[i], uxVV[i], piVVSDL[i]);
        }
    }

    function valid(Bid01Proof storage pi) internal view returns (bool) {
        if (stageA(pi) == false) return false;
        return pi.ctA.c.isIdentityElement() || pi.ctAA.c.isIdentityElement();
    }

    function valid(Bid01Proof[] storage pi) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i]) == false) return false;
        }
        return true;
    }
}
