// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {BoolLib} from "./BoolLib.sol";
import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";
import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";

struct Ct {
    BigNumber.instance u;
    BigNumber.instance c;
}

library CtLib {
    using BoolLib for bool;
    using BoolLib for bool[];
    using BigNumberLib for BigNumber.instance;
    using BigNumberLib for BigNumber.instance[];
    using SameDLProofLib for SameDLProof;
    using SameDLProofLib for SameDLProof[];

    function isNotSet(Ct memory ct) internal view returns (bool) {
        return ct.u.isNotSet() || ct.c.isNotSet();
    }

    function isNotSet(Ct[] memory ct) internal view returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isNotSet(ct[i]) == false) return false;
        }
        return true;
    }

    function set(Ct[] storage ct1, Ct[] memory ct2) internal {
        for (uint256 i = 0; i < ct2.length; i++) {
            if (ct1.length <= i) ct1.push(ct2[i]);
            else ct1[i] = ct2[i];
        }
    }

    function mul(Ct memory ct1, Ct memory ct2)
        internal
        view
        returns (Ct memory)
    {
        return Ct(ct1.u.mul(ct2.u), ct1.c.mul(ct2.c));
    }

    function mul(Ct[] memory ct1, Ct[] memory ct2)
        internal
        view
        returns (Ct[] memory result)
    {
        require(ct1.length == ct2.length, "ct1.length != ct2.length");
        result = new Ct[](ct1.length);
        for (uint256 i = 0; i < ct1.length; i++) {
            result[i] = mul(ct1[i], ct2[i]);
        }
    }

    function mulC(Ct memory ct, BigNumber.instance memory a)
        internal
        view
        returns (Ct memory)
    {
        return Ct(ct.u, ct.c.mul(a));
    }

    function mulC(Ct[] memory ct, BigNumber.instance memory a)
        internal
        view
        returns (Ct[] memory result)
    {
        result = new Ct[](ct.length);
        for (uint256 i = 0; i < ct.length; i++) {
            result[i] = mulC(ct[i], a);
        }
    }

    function equals(Ct memory ct1, Ct memory ct2) internal view returns (bool) {
        return ct1.u.equals(ct2.u) && ct1.c.equals(ct2.c);
    }

    function prod(Ct[] memory ct) internal view returns (Ct memory result) {
        if (ct.length > 0) {
            result = ct[0];
            for (uint256 i = 1; i < ct.length; i++) {
                result = mul(result, ct[i]);
            }
        }
    }

    function decrypt(
        Ct memory ct,
        Bidder storage bidder,
        BigNumber.instance memory ux,
        BigNumber.instance memory uxInv,
        SameDLProof memory pi
    ) internal view returns (Ct memory) {
        require(ux.mul(uxInv).isIdentityElement(), "uxInv is not ux's inverse");
        require(
            pi.valid(ct.u, BigNumberLib.g(), ux, bidder.elgamalY),
            "Same discrete log verification failed."
        );
        return Ct(ct.u, ct.c.mul(uxInv));
    }

    function decrypt(
        Ct[] memory ct,
        Bidder storage bidder,
        BigNumber.instance[] memory ux,
        BigNumber.instance[] memory uxInv,
        SameDLProof[] memory pi
    ) internal view returns (Ct[] memory result) {
        result = new Ct[](ct.length);
        for (uint256 i = 0; i < ct.length; i++) {
            result[i] = decrypt(ct[i], bidder, ux[i], uxInv[i], pi[i]);
        }
    }
}
