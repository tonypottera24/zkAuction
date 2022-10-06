// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";

struct DLProof {
    BigNumber.instance t;
    BigNumber.instance r;
}

library DLProofLib {
    using BigNumberLib for BigNumber.instance;

    function valid(
        DLProof memory pi,
        BigNumber.instance memory g,
        BigNumber.instance memory y,
        BigNumber.instance storage p,
        BigNumber.instance storage q
    ) internal view returns (bool) {
        // (pi.t, pi.r) = (pi.t.mod(p), pi.r.mod(q));
        // (g, y) = (g.mod(p), y.mod(p));

        bytes32 digest = keccak256(abi.encodePacked(g.val, y.val, pi.t.val));
        uint256 bit_length = 0;
        for (uint256 i = 0; i < 256; i++) {
            if (digest >> i > 0) bit_length++;
            else break;
        }
        bytes memory digest_packed = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            digest_packed[i] = digest[i];
        }
        BigNumber.instance memory c = BigNumber.instance(
            digest_packed,
            false,
            bit_length
        );
        c = c.mod(q);
        return pi.t.equals(g.pow(pi.r, p).mul(y.pow(c, p), p), p);
    }
}
