// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";

struct DLProof {
    BigNumber.instance grr;
    BigNumber.instance rrr;
}

library DLProofLib {
    using BigNumberLib for BigNumber.instance;

    function valid(
        DLProof memory pi,
        BigNumber.instance memory g,
        BigNumber.instance memory y
    ) internal view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked(g.val, y.val, pi.grr.val));
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
        return g.pow(pi.rrr).equals(pi.grr.mul(y.pow(c)));
    }
}
