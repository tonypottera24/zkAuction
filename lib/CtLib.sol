// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {BoolLib} from "./BoolLib.sol";
import {ECPoint, ECPointLib} from "./ECPointLib.sol";
import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";

struct Ct {
    ECPoint u;
    ECPoint c;
}

library CtLib {
    using BoolLib for bool;
    using BoolLib for bool[];
    using ECPointLib for ECPoint;
    using ECPointLib for ECPoint[];
    using SameDLProofLib for SameDLProof;
    using SameDLProofLib for SameDLProof[];

    function isEmpty(Ct memory ct) internal pure returns (bool) {
        return ct.u.isEmpty() || ct.c.isEmpty();
    }

    function isEmpty(Ct[] memory ct) internal pure returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isEmpty(ct[i]) == false) return false;
        }
        return true;
    }

    function set(Ct[] storage ct1, Ct[] memory ct2) internal {
        for (uint256 i = 0; i < ct2.length; i++) {
            if (ct1.length <= i) ct1.push(ct2[i]);
            else ct1[i] = ct2[i];
        }
    }

    function add(Ct memory ct1, Ct memory ct2)
        internal
        pure
        returns (Ct memory)
    {
        return Ct(ct1.u.add(ct2.u), ct1.c.add(ct2.c));
    }

    function add(Ct[] memory ct1, Ct[] memory ct2)
        internal
        pure
        returns (Ct[] memory result)
    {
        require(ct1.length == ct2.length, "ct1.length != ct2.length");
        result = new Ct[](ct1.length);
        for (uint256 i = 0; i < ct1.length; i++) {
            result[i] = add(ct1[i], ct2[i]);
        }
    }

    function subC(Ct memory ct, ECPoint memory a)
        internal
        pure
        returns (Ct memory)
    {
        return Ct(ct.u, ct.c.sub(a));
    }

    function subC(Ct[] memory ct, ECPoint memory a)
        internal
        pure
        returns (Ct[] memory result)
    {
        result = new Ct[](ct.length);
        for (uint256 i = 0; i < ct.length; i++) {
            result[i] = subC(ct[i], a);
        }
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
        ECPoint memory ux,
        SameDLProof memory pi
    ) internal view returns (Ct memory) {
        require(
            pi.valid(ct.u, ECPointLib.g(), ux, bidder.pk),
            "Same discrete log verification failed."
        );
        return Ct(ct.u, ct.c.sub(ux));
    }

    function decrypt(
        Ct[] memory ct,
        Bidder storage bidder,
        ECPoint[] memory ux,
        SameDLProof[] memory pi
    ) internal view returns (Ct[] memory result) {
        result = new Ct[](ct.length);
        for (uint256 i = 0; i < ct.length; i++) {
            result[i] = decrypt(ct[i], bidder, ux[i], pi[i]);
        }
    }
}
