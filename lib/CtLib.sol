// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {BoolLib} from "./BoolLib.sol";
import {ECPointExt, ECPointLib} from "./ECPointLib.sol";
import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";

struct Ct {
    ECPointExt u;
    ECPointExt c;
}

library CtLib {
    using BoolLib for bool;
    using BoolLib for bool[];
    using ECPointLib for ECPointExt;
    using ECPointLib for ECPointExt[];
    using SameDLProofLib for SameDLProof;
    using SameDLProofLib for SameDLProof[];

    function isNotSet(Ct memory ct) internal pure returns (bool) {
        return ct.u.isNotSet() || ct.c.isNotSet();
    }

    function isNotSet(Ct[] memory ct) internal pure returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isNotSet(ct[i]) == false) return false;
        }
        return true;
    }

    function add(Ct memory ct1, Ct memory ct2)
        internal
        view
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

    function equals(Ct memory ct1, Ct memory ct2) internal view returns (bool) {
        return ct1.u.equals(ct2.u) && ct1.c.equals(ct2.c);
    }

    function sum(Ct[] memory ct) internal view returns (Ct memory result) {
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
            pi.valid(ct.u, ECPointLib.g(), ux, bidder.elgamalY),
            "Same discrete log verification failed."
        );
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
