// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";
import {Ct, CtLib} from "./CtLib.sol";

struct SameDLProof {
    BigNumber.instance grr1;
    BigNumber.instance grr2;
    BigNumber.instance rrr;
}

library SameDLProofLib {
    using BigNumberLib for BigNumber.instance;
    using CtLib for Ct;
    using CtLib for Ct[];

    function valid(
        SameDLProof memory pi,
        BigNumber.instance memory g1,
        BigNumber.instance memory g2,
        BigNumber.instance memory y1,
        BigNumber.instance memory y2
    ) internal view returns (bool) {
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    g1.val,
                    g2.val,
                    y1.val,
                    y2.val,
                    pi.grr1.val,
                    pi.grr2.val
                )
            );
        uint256 bit_length = 0;
        for (uint256 i = 0; i < 256; i++) {
            if ((digest >> i) > 0) bit_length++;
            else break;
        }
        bytes memory digest_packed = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            digest_packed[i] = digest[i];
        }
        BigNumber.instance memory c =
            BigNumber.instance(digest_packed, false, bit_length).modQ();
        return
            g1.pow(pi.rrr).equals(pi.grr1.mul(y1.pow(c))) &&
            g2.pow(pi.rrr).equals(pi.grr2.mul(y2.pow(c)));
    }

    function valid(
        SameDLProof[] memory pi,
        BigNumber.instance[] memory g1,
        BigNumber.instance[] memory g2,
        BigNumber.instance[] memory y1,
        BigNumber.instance[] memory y2
    ) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i], g1[i], g2[i], y1[i], y2[i]) == false) return false;
        }
        return true;
    }
}
