// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

import {Auctioneer} from "./AuctioneerListLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";
import {ECPointExt, ECPointLib} from "./ECPointLib.sol";

struct Ct {
    ECPointExt u1;
    ECPointExt u2;
    ECPointExt c;
}

library CtLib {
    using ECPointLib for ECPointExt;
    using SameDLProofLib for SameDLProof;
    using SameDLProofLib for SameDLProof[];

    function isSet(Ct memory ct) internal pure returns (bool) {
        return ct.u1.isSet() || ct.u2.isSet() || ct.c.isSet();
    }

    function isNotSet(Ct memory ct) internal pure returns (bool) {
        return isSet(ct) == false;
    }

    function isNotSet(Ct[] memory ct) internal pure returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isNotSet(ct[i]) == false) return false;
        }
        return true;
    }

    function isNotDec(Ct memory ct) internal pure returns (bool) {
        return ct.u1.isSet() && ct.u2.isSet() && ct.c.isSet();
    }

    function isNotDec(Ct[] memory ct) internal pure returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isNotDec(ct[i]) == false) return false;
        }
        return true;
    }

    function isPartialDec(Ct memory ct) internal pure returns (bool) {
        return
            (ct.u1.isSet() && ct.u2.isNotSet()) ||
            (ct.u1.isNotSet() && ct.u2.isSet());
    }

    function isPartialDec(Ct[] memory ct) internal pure returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isPartialDec(ct[i]) == false) return false;
        }
        return true;
    }

    function isDecByA(Ct memory ct, uint256 i) internal pure returns (bool) {
        require(i == 0 || i == 1, "i can only be 0 or 1.");
        if (i == 0) return ct.u1.isNotSet();
        else return ct.u2.isNotSet();
    }

    function isDecByA(Ct[] memory ct, uint256 auctioneer_i)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isDecByA(ct[i], auctioneer_i) == false) return false;
        }
        return true;
    }

    function isFullDec(Ct memory ct) internal pure returns (bool) {
        return ct.u1.isNotSet() && ct.u2.isNotSet();
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
        return Ct(ct1.u1.add(ct2.u1), ct1.u2.add(ct2.u2), ct1.c.add(ct2.c));
    }

    function subZ(Ct memory ct) internal pure returns (Ct memory) {
        return Ct(ct.u1, ct.u2, ct.c.sub(ECPointLib.z()));
    }

    function subZ(Ct[] memory ct) internal pure returns (Ct[] memory) {
        Ct[] memory result = new Ct[](ct.length);
        for (uint256 i = 0; i < ct.length; i++) {
            result[i] = subZ(ct[i]);
        }
        return result;
    }

    function equals(Ct memory ct1, Ct memory ct2) internal pure returns (bool) {
        return
            ct1.u1.equals(ct2.u1) &&
            ct1.u2.equals(ct2.u2) &&
            ct1.c.equals(ct2.c);
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
        Auctioneer storage a,
        ECPointExt memory ux,
        SameDLProof memory pi
    ) internal view returns (Ct memory) {
        require(a.index == 0 || a.index == 1, "a.index can only be 0 or 1");
        if (a.index == 0) {
            require(ct.u1.isSet(), "ct.u1 should not be zero.");
            require(
                pi.valid(ct.u1, ECPointLib.g(), ux, a.elgamalY),
                "Same discrete log verification failed."
            );
            return Ct(ECPointExt(0, 0), ct.u2, ct.c.sub(ux));
        } else {
            require(ct.u2.isSet(), "ct.u2 should not be zero.");
            require(
                pi.valid(ct.u2, ECPointLib.g(), ux, a.elgamalY),
                "Same discrete log verification failed."
            );
            return Ct(ct.u1, ECPointExt(0, 0), ct.c.sub(ux));
        }
    }

    function decrypt(
        Ct[] memory ct,
        Auctioneer storage a,
        ECPointExt[] memory ux,
        SameDLProof[] memory pi
    ) internal view returns (Ct[] memory) {
        Ct[] memory result = new Ct[](ct.length);
        for (uint256 i = 0; i < ct.length; i++) {
            result[i] = decrypt(ct[i], a, ux[i], pi[i]);
        }
        return result;
    }
}
