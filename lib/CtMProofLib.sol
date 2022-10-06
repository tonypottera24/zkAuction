// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";
import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {Ct, CtLib} from "./CtLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";
import {DLProof, DLProofLib} from "./DLProofLib.sol";

struct CtMProof {
    BigNumber.instance ya;
    BigNumber.instance ctCA;
    SameDLProof piA;
    DLProof piR;
    // TODO change notation A to W. "A" is same as array a.
}

library CtMProofLib {
    using BigNumberLib for BigNumber.instance;
    using SameDLProofLib for SameDLProof;
    using DLProofLib for DLProof;

    function valid(
        CtMProof memory pi,
        BigNumber.instance memory y,
        Ct memory ct,
        BigNumber.instance memory m,
        BigNumber.instance memory zmInv
    ) internal view returns (bool) {
        require(
            BigNumberLib.z().pow(m).mul(zmInv).isIdentityElement(),
            "zmInv is invalid"
        );
        BigNumber.instance memory ctC = ct.c.mul(zmInv);
        require(pi.piA.valid(y, ctC, pi.ya, pi.ctCA), "piA failed.");
        return pi.piR.valid(pi.ya, pi.ctCA);
    }

    function valid(
        CtMProof[] memory pi,
        BigNumber.instance memory y,
        Ct[] memory ct,
        BigNumber.instance memory m,
        BigNumber.instance memory zmInv
    ) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i], y, ct[i], m, zmInv) == false) return false;
        }
        return true;
    }
}
