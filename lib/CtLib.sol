// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";
import {Auctioneer} from "./AuctioneerListLib.sol";
// import {UIntLib} from "./UIntLib.sol";
import {SameDLProof, SameDLProofLib} from "./SameDLProofLib.sol";

struct Ct {
    // Ciphertext
    BigNumber.instance u1;
    BigNumber.instance u2;
    BigNumber.instance c;
}

library CtLib {
    using BigNumberLib for BigNumber.instance;
    using SameDLProofLib for SameDLProof;
    using SameDLProofLib for SameDLProof[];

    function isSet(Ct memory ct, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        return
            ct.u1.isZero(p) == false ||
            ct.u2.isZero(p) == false ||
            ct.c.isZero(p) == false;
    }

    function isNotSet(Ct memory ct, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        return ct.u1.isZero(p) && ct.u2.isZero(p) && ct.c.isZero(p);
    }

    function isNotSet(Ct[] memory ct, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isNotSet(ct[i], p) == false) return false;
        }
        return true;
    }

    function isNotDec(Ct memory ct, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        return
            ct.u1.isZero(p) == false &&
            ct.u2.isZero(p) == false &&
            ct.c.isZero(p) == false;
    }

    function isNotDec(Ct[] memory ct, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isNotDec(ct[i], p) == false) return false;
        }
        return true;
    }

    function isPartialDec(Ct memory ct, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        return
            ((ct.u1.isZero(p) == false && ct.u2.isZero(p)) ||
                (ct.u1.isZero(p) && ct.u2.isZero(p) == false)) &&
            ct.c.isZero(p) == false;
    }

    function isPartialDec(Ct[] memory ct, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isPartialDec(ct[i], p) == false) return false;
        }
        return true;
    }

    function isDecByA(
        Ct memory ct,
        uint256 i,
        BigNumber.instance storage p
    ) internal view returns (bool) {
        require(i == 0 || i == 1, "i can only be 0 or 1.");
        if (i == 0) return ct.u1.isZero(p);
        else return ct.u2.isZero(p);
    }

    function isDecByA(
        Ct[] memory ct,
        uint256 auctioneer_i,
        BigNumber.instance storage p
    ) internal view returns (bool) {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isDecByA(ct[i], auctioneer_i, p) == false) return false;
        }
        return true;
    }

    function isFullDec(Ct memory ct, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        return ct.u1.isZero(p) && ct.u2.isZero(p);
    }

    function isFullDec(Ct[] memory ct, BigNumber.instance storage p)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < ct.length; i++) {
            if (isFullDec(ct[i], p) == false) return false;
        }
        return true;
    }

    function mul(
        Ct memory ct1,
        Ct memory ct2,
        BigNumber.instance storage p
    ) internal view returns (Ct memory) {
        Ct memory result = Ct(
            ct1.u1.mul(ct2.u1, p),
            ct1.u2.mul(ct2.u2, p),
            ct1.c.mul(ct2.c, p)
        );
        if (ct1.u1.isZero(p)) result.u1 = ct2.u1;
        if (ct2.u1.isZero(p)) result.u1 = ct1.u1;
        if (ct1.u2.isZero(p)) result.u2 = ct2.u2;
        if (ct2.u2.isZero(p)) result.u2 = ct1.u2;
        return result;
    }

    function mul(
        Ct memory ct,
        BigNumber.instance memory z,
        BigNumber.instance storage p
    ) internal view returns (Ct memory) {
        return Ct(ct.u1, ct.u2, ct.c.mul(z, p));
    }

    function mul(
        Ct[] memory ct,
        BigNumber.instance storage z,
        BigNumber.instance storage p
    ) internal view returns (Ct[] memory) {
        Ct[] memory result = new Ct[](ct.length);
        for (uint256 i = 0; i < ct.length; i++) {
            result[i] = mul(ct[i], z, p);
        }
        return result;
    }

    function equals(
        Ct memory ct1,
        Ct memory ct2,
        BigNumber.instance storage p
    ) internal view returns (bool) {
        return
            ct1.u1.equals(ct2.u1, p) &&
            ct1.u2.equals(ct2.u2, p) &&
            ct1.c.equals(ct2.c, p);
    }

    function prod(Ct[] memory ct, BigNumber.instance storage p)
        internal
        view
        returns (Ct memory result)
    {
        if (ct.length > 0) {
            result = ct[0];
            for (uint256 i = 1; i < ct.length; i++) {
                result = mul(result, ct[i], p);
            }
        }
    }

    function decrypt(
        Ct memory ct,
        Auctioneer storage a,
        BigNumber.instance memory ux,
        BigNumber.instance memory uxInv,
        SameDLProof memory pi,
        BigNumber.instance storage g,
        BigNumber.instance storage p,
        BigNumber.instance storage q
    ) internal view returns (Ct memory) {
        require(ux.mul(uxInv, p).isOne(p), "uxInv is not ux's inverse");
        BigNumber.instance memory b0 = BigNumber.instance(
            hex"0000000000000000000000000000000000000000000000000000000000000000",
            false,
            0
        );
        require(a.index == 0 || a.index == 1, "a.index can only be 0 or 1");
        if (a.index == 0) {
            require(ct.u1.isZero(p) == false, "ct.u1 should not be zero.");
            require(
                pi.valid(ct.u1, g, ux, a.elgamalY, p, q),
                "Same discrete log verification failed."
            );
            return Ct(b0, ct.u2, ct.c.mul(uxInv, p));
        } else {
            require(ct.u2.isZero(p) == false, "ct.u2 should not be zero.");
            require(
                pi.valid(ct.u2, g, ux, a.elgamalY, p, q),
                "Same discrete log verification failed."
            );
            return Ct(ct.u1, b0, ct.c.mul(uxInv, p));
        }
    }

    function decrypt(
        Ct[] memory ct,
        Auctioneer storage a,
        BigNumber.instance[] memory ux,
        BigNumber.instance[] memory uxInv,
        SameDLProof[] memory pi,
        BigNumber.instance storage g,
        BigNumber.instance storage p,
        BigNumber.instance storage q
    ) internal view returns (Ct[] memory) {
        Ct[] memory result = new Ct[](ct.length);
        for (uint256 i = 0; i < ct.length; i++) {
            result[i] = decrypt(ct[i], a, ux[i], uxInv[i], pi[i], g, p, q);
        }
        return result;
    }
}
