// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {ECPointExt, ECPointLib} from "./ECPointLib.sol";
import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {Ct, CtLib} from "./CtLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";
import {CtSameDLProof, CtSameDLProofLib} from "./CtSameDLProofLib.sol";

struct Bid01Proof {
    Ct u;
    Ct uu;
    Ct v;
    Ct vv;
    Ct a;
    Ct aa;
}

library Bid01ProofLib {
    using ECPointLib for ECPointExt;
    using CtLib for Ct;
    using CtLib for Ct[];
    using SameDLProofLib for SameDLProof;
    using CtSameDLProofLib for CtSameDLProof;

    function stageU(Bid01Proof storage pi) internal view returns (bool) {
        return
            pi.u.isNotSet() &&
            pi.uu.isNotSet() &&
            pi.v.isNotSet() &&
            pi.vv.isNotSet() &&
            pi.a.isNotSet() &&
            pi.aa.isNotSet();
    }

    function stageV(Bid01Proof storage pi) internal view returns (bool) {
        return
            pi.u.isSet() &&
            pi.uu.isSet() &&
            pi.v.isNotSet() &&
            pi.vv.isNotSet() &&
            pi.a.isNotSet() &&
            pi.aa.isNotSet();
    }

    function stageA(Bid01Proof storage pi) internal view returns (bool) {
        return pi.u.isSet() && pi.uu.isSet() && pi.v.isSet() && pi.vv.isSet();
    }

    function stageA(Bid01Proof[] storage pi) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (stageA(pi[i]) == false) return false;
        }
        return true;
    }

    function stageAIsDecByB(Bid01Proof storage pi, uint256 bidder_i)
        internal
        view
        returns (bool)
    {
        return
            stageA(pi) && pi.a.isDecByA(bidder_i) && pi.aa.isDecByA(bidder_i);
    }

    function stageAIsDecByB(Bid01Proof[] storage pi, uint256 bidder_i)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < pi.length; i++) {
            if (stageAIsDecByB(pi[i], bidder_i) == false) return false;
        }
        return true;
    }

    function stageACompleted(Bid01Proof storage pi)
        internal
        view
        returns (bool)
    {
        return
            pi.u.isSet() &&
            pi.uu.isSet() &&
            pi.v.isSet() &&
            pi.vv.isSet() &&
            pi.a.isFullDec() &&
            pi.aa.isFullDec();
    }

    function stageACompleted(Bid01Proof[] storage pi)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < pi.length; i++) {
            if (stageACompleted(pi[i]) == false) return false;
        }
        return true;
    }

    function setU(Bid01Proof storage pi, Ct memory bidU) internal {
        require(stageU(pi), "Not in stageU.");
        require(bidU.isNotDec(), "bidU not been decrypted yet.");
        (pi.u, pi.uu) = (bidU, bidU.subZ());
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
            ctV.isNotDec() && ctVV.isNotDec(),
            "ctV and ctVV must not be decrypted yet."
        );
        require(
            piSDL.valid(pi.u, pi.uu, ctV, ctVV),
            "Same discrete log verification failed."
        );
        (pi.v, pi.vv) = (ctV, ctVV);
        (pi.a, pi.aa) = (ctV, ctVV);
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
        pi.a = pi.a.decrypt(bidder, uxV, piVSDL);
        pi.aa = pi.aa.decrypt(bidder, uxVV, piVVSDL);
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
        if (stageACompleted(pi) == false) return false;
        return pi.a.c.isIdentityElement() || pi.aa.c.isIdentityElement();
    }

    function valid(Bid01Proof[] storage pi) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i]) == false) return false;
        }
        return true;
    }
}
