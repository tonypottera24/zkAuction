// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";
import {ECPointExt, ECPointLib} from "./ECPointLib.sol";

struct Ct {
    ECPointExt[] u;
    ECPointExt c;
}

library CtLib {
    using ECPointLib for ECPointExt;
    using ECPointLib for ECPointExt[];
    using SameDLProofLib for SameDLProof;
    using SameDLProofLib for SameDLProof[];

    function set(Ct storage ct1, Ct memory ct2) internal {
        for (uint256 i = 0; i < ct2.u.length; i++) {
            if (ct1.u.length < i + 1) ct1.u.push();
            ct1.u[i] = ct2.u[i];
        }
        ct1.c = ct2.c;
    }

    // function set(Ct[] storage ct1, Ct[] memory ct2) internal {
    //     for (uint256 i = 0; i < ct2.length; i++) {
    //         set(ct1[i], ct2[i]);
    //     }
    // }

    function isNotSet(Ct memory ct) internal pure returns (bool) {
        return ct.u.isNotSet() && ct.c.isNotSet();
    }

    function isNotSet(Ct[] memory ct) internal pure returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isNotSet(ct[i]) == false) return false;
        }
        return true;
    }

    function isNotDec(Ct memory ct) internal pure returns (bool) {
        for (uint256 i = 0; i < ct.u.length; i++) {
            if (ct.u[i].isNotSet() == true) return false;
        }
        return true;
    }

    function isNotDec(Ct[] memory ct) internal pure returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isNotDec(ct[i]) == false) return false;
        }
        return true;
    }

    function isDecByB(Ct memory ct, uint256 bidder_i)
        internal
        pure
        returns (bool)
    {
        return ct.u[bidder_i].isNotSet();
    }

    function isDecByB(Ct[] memory ct, uint256 bidder_i)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isDecByB(ct[i], bidder_i) == false) return false;
        }
        return true;
    }

    function isFullDec(Ct memory ct) internal pure returns (bool) {
        return ct.u.isNotSet();
    }

    function isFullDec(Ct[] memory ct) internal pure returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isFullDec(ct[i]) == false) return false;
        }
        return true;
    }

    function add(Ct memory ct1, Ct memory ct2)
        internal
        pure
        returns (Ct memory)
    {
        return Ct(ct1.u.add(ct2.u), ct1.c.add(ct2.c));
    }

    function subZ(Ct memory ct) internal pure returns (Ct memory) {
        return Ct(ct.u, ct.c.sub(ECPointLib.z()));
    }

    function subZ(Ct[] memory ct) internal pure returns (Ct[] memory) {
        Ct[] memory result = new Ct[](ct.length);
        for (uint256 i = 0; i < ct.length; i++) {
            result[i] = subZ(ct[i]);
        }
        return result;
    }

    function equals(Ct memory ct1, Ct memory ct2) internal pure returns (bool) {
        return ct1.u.equals(ct2.u) && ct1.c.equals(ct2.c);
    }

    function sum(Ct[] memory ct) internal pure returns (Ct memory result) {
        if (ct.length > 0) {
            result = ct[0];
            for (uint256 i = 1; i < ct.length; i++) {
                result = add(result, ct[i]);
            }
        }
    }

    function decrypt(
        Ct memory ct,
        Bidder storage bidder,
        ECPointExt memory ux,
        SameDLProof memory pi
    ) internal view returns (Ct memory) {
        require(
            ct.u[bidder.index].isNotSet() == false,
            "ct.u1 should not be zero."
        );
        require(
            pi.valid(ct.u[bidder.index], ECPointLib.g(), ux, bidder.elgamalY),
            "Same discrete log verification failed."
        );
        ct.u[bidder.index] = ECPointExt(0, 0);
        return Ct(ct.u, ct.c.sub(ux));
    }

    function decrypt(
        Ct[] memory ct,
        Bidder storage bidder,
        ECPointExt[] memory ux,
        SameDLProof[] memory pi
    ) internal view returns (Ct[] memory) {
        Ct[] memory result = new Ct[](ct.length);
        for (uint256 i = 0; i < ct.length; i++) {
            result[i] = decrypt(ct[i], bidder, ux[i], pi[i]);
        }
        return result;
    }
}
