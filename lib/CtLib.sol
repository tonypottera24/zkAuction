// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {ECPoint, ECPointLib} from "./ECPointLib.sol";
import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";

struct Ct {
    ECPoint c;
    ECPoint r;
}

library CtLib {
    using ECPointLib for ECPoint;
    using ECPointLib for ECPoint[];
    using SameDLProofLib for SameDLProof;
    using SameDLProofLib for SameDLProof[];

    function set(Ct[] storage ct1, Ct[] memory ct2) internal {
        for (uint256 i = 0; i < ct2.length; i++) {
            if (ct1.length <= i) ct1.push(ct2[i]);
            else ct1[i] = ct2[i];
        }
        while (ct1.length > ct2.length) ct1.pop();
    }

    function add(Ct memory ct1, Ct memory ct2)
        internal
        view
        returns (Ct memory)
    {
        return Ct(ct1.c.add(ct2.c), ct1.r.add(ct2.r));
    }

    function add(Ct[] memory ct1, Ct[] memory ct2)
        internal
        view
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
        view
        returns (Ct memory)
    {
        return Ct(ct.c.sub(a), ct.r);
    }

    function subC(Ct[] memory ct, ECPoint memory a)
        internal
        view
        returns (Ct[] memory result)
    {
        result = new Ct[](ct.length);
        for (uint256 i = 0; i < ct.length; i++) {
            result[i] = subC(ct[i], a);
        }
    }

    function equals(Ct memory ct1, Ct memory ct2) internal pure returns (bool) {
        return ct1.c.equals(ct2.c) && ct1.r.equals(ct2.r);
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
        ECPoint memory ux,
        SameDLProof memory pi
    ) internal view returns (Ct memory) {
        require(
            pi.valid(ct.r, ECPointLib.g(), ux, bidder.pk),
            "Same discrete log verification failed."
        );
        return Ct(ct.r, ct.c.sub(ux));
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
