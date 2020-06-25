// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";
import {Auctioneer} from "./AuctioneerListLib.sol";
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
    using BigNumberLib for BigNumber.instance;
    using CtLib for Ct;
    using CtLib for Ct[];
    using SameDLProofLib for SameDLProof;
    using CtSameDLProofLib for CtSameDLProof;

    function stageU(Bid01Proof storage pi, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        return
            pi.u.isNotSet(p) &&
            pi.uu.isNotSet(p) &&
            pi.v.isNotSet(p) &&
            pi.vv.isNotSet(p) &&
            pi.a.isNotSet(p) &&
            pi.aa.isNotSet(p);
    }

    function stageV(Bid01Proof storage pi, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        return
            pi.u.isSet(p) &&
            pi.uu.isSet(p) &&
            pi.v.isNotSet(p) &&
            pi.vv.isNotSet(p) &&
            pi.a.isNotSet(p) &&
            pi.aa.isNotSet(p);
    }

    function stageA(Bid01Proof storage pi, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        return
            pi.u.isSet(p) && pi.uu.isSet(p) && pi.v.isSet(p) && pi.vv.isSet(p);
    }

    function stageA(Bid01Proof[] storage pi, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < pi.length; i++) {
            if (stageA(pi[i], p) == false) return false;
        }
        return true;
    }

    function stageAIsDecByA(
        Bid01Proof storage pi,
        uint256 auctioneer_i,
        BigNumber.instance storage p
    ) internal view returns (bool) {
        return
            stageA(pi, p) &&
            pi.a.isDecByA(auctioneer_i, p) &&
            pi.aa.isDecByA(auctioneer_i, p);
    }

    function stageAIsDecByA(
        Bid01Proof[] storage pi,
        uint256 auctioneer_i,
        BigNumber.instance storage p
    ) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (stageAIsDecByA(pi[i], auctioneer_i, p) == false) return false;
        }
        return true;
    }

    function stageACompleted(
        Bid01Proof storage pi,
        BigNumber.instance storage p
    ) internal view returns (bool) {
        return
            pi.u.isSet(p) &&
            pi.uu.isSet(p) &&
            pi.v.isSet(p) &&
            pi.vv.isSet(p) &&
            pi.a.isFullDec(p) &&
            pi.aa.isFullDec(p);
    }

    function stageACompleted(
        Bid01Proof[] storage pi,
        BigNumber.instance storage p
    ) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (stageACompleted(pi[i], p) == false) return false;
        }
        return true;
    }

    function setU(
        Bid01Proof storage pi,
        Ct memory bidU,
        BigNumber.instance memory zInv,
        BigNumber.instance storage p
    ) internal {
        require(stageU(pi, p), "Not in stageU.");
        require(bidU.isNotDec(p), "bidU not been decrypted yet.");
        (pi.u, pi.uu) = (bidU, bidU.mul(zInv, p));
    }

    function setU(
        Bid01Proof[] storage pi,
        Ct[] memory bidU,
        BigNumber.instance memory zInv,
        BigNumber.instance storage p
    ) internal {
        require(pi.length == bidU.length, "pi, bidU must have same length.");
        for (uint256 i = 0; i < pi.length; i++) {
            setU(pi[i], bidU[i], zInv, p);
        }
    }

    function setV(
        Bid01Proof storage pi,
        Ct memory ctV,
        Ct memory ctVV,
        CtSameDLProof memory piSDL,
        BigNumber.instance storage p,
        BigNumber.instance storage q
    ) internal {
        require(stageV(pi, p), "Not in stageV.");
        require(
            ctV.isNotDec(p) && ctVV.isNotDec(p),
            "ctV and ctVV must not be decrypted yet."
        );
        require(
            piSDL.valid(pi.u, pi.uu, ctV, ctVV, p, q),
            "Same discrete log verification failed."
        );
        (pi.v, pi.vv) = (ctV, ctVV);
        (pi.a, pi.aa) = (ctV, ctVV);
    }

    function setV(
        Bid01Proof[] storage pi,
        Ct[] memory ctV,
        Ct[] memory ctVV,
        CtSameDLProof[] memory piSDL,
        BigNumber.instance storage p,
        BigNumber.instance storage q
    ) internal {
        require(
            pi.length == ctV.length &&
                pi.length == ctVV.length &&
                pi.length == piSDL.length,
            "pi, ctV, ctVV, piSDL must have same length."
        );
        for (uint256 i = 0; i < pi.length; i++) {
            setV(pi[i], ctV[i], ctVV[i], piSDL[i], p, q);
        }
    }

    function setA(
        Bid01Proof storage pi,
        Auctioneer storage auctioneer,
        BigNumber.instance memory uxV,
        BigNumber.instance memory uxVInv,
        SameDLProof memory piVSDL,
        BigNumber.instance storage g,
        BigNumber.instance storage p,
        BigNumber.instance storage q
    ) internal {
        require(stageA(pi, p), "Not in stageA.");
        pi.a = pi.a.decrypt(auctioneer, uxV, uxVInv, piVSDL, g, p, q);
    }

    function setA(
        Bid01Proof[] storage pi,
        Auctioneer storage auctioneer,
        BigNumber.instance[] memory uxV,
        BigNumber.instance[] memory uxVInv,
        SameDLProof[] memory piVSDL,
        BigNumber.instance storage g,
        BigNumber.instance storage p,
        BigNumber.instance storage q
    ) internal {
        require(
            pi.length == uxV.length &&
                pi.length == uxVInv.length &&
                pi.length == piVSDL.length,
            "pi, uxV, uxVInv, piSDL must have same length."
        );
        for (uint256 i = 0; i < pi.length; i++) {
            setA(pi[i], auctioneer, uxV[i], uxVInv[i], piVSDL[i], g, p, q);
        }
    }

    function setAA(
        Bid01Proof storage pi,
        Auctioneer storage auctioneer,
        BigNumber.instance memory uxVV,
        BigNumber.instance memory uxVVInv,
        SameDLProof memory piVVSDL,
        BigNumber.instance storage g,
        BigNumber.instance storage p,
        BigNumber.instance storage q
    ) internal {
        require(stageA(pi, p), "Not in stageA.");
        pi.aa = pi.aa.decrypt(auctioneer, uxVV, uxVVInv, piVVSDL, g, p, q);
    }

    function setAA(
        Bid01Proof[] storage pi,
        Auctioneer storage auctioneer,
        BigNumber.instance[] memory uxVV,
        BigNumber.instance[] memory uxVVInv,
        SameDLProof[] memory piVVSDL,
        BigNumber.instance storage g,
        BigNumber.instance storage p,
        BigNumber.instance storage q
    ) internal {
        require(
            pi.length == uxVV.length &&
                pi.length == uxVVInv.length &&
                pi.length == piVVSDL.length,
            "pi, uxVV, uxVVInv, piSDL must have same length."
        );
        for (uint256 i = 0; i < pi.length; i++) {
            setAA(pi[i], auctioneer, uxVV[i], uxVVInv[i], piVVSDL[i], g, p, q);
        }
    }

    function valid(Bid01Proof storage pi, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        if (stageACompleted(pi, p) == false) return false;
        return pi.a.c.isOne(p) || pi.aa.c.isOne(p);
    }

    function valid(Bid01Proof[] storage pi, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i], p) == false) return false;
        }
        return true;
    }
}
