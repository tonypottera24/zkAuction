// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";
import {Bidder, BidderList, BidderListLib} from "./BidderListLib.sol";
import {Ct, CtLib} from "./CtLib.sol";

struct Ct01Proof {
    BigNumber.instance aa0;
    BigNumber.instance aa1;
    BigNumber.instance bb0;
    BigNumber.instance bb1;
    BigNumber.instance c0;
    BigNumber.instance c1;
    BigNumber.instance rrr0;
    BigNumber.instance rrr1;
}

library Ct01ProofLib {
    using BigNumberLib for BigNumber.instance;
    using CtLib for Ct;
    using CtLib for Ct[];

    function valid(
        Ct01Proof memory pi,
        Ct memory ct,
        BigNumber.instance memory y
    ) internal view returns (bool) {
        if (
            BigNumberLib.g().pow(pi.rrr0).equals(pi.aa0.mul(ct.u.pow(pi.c0))) ==
            false ||
            BigNumberLib.g().pow(pi.rrr1).equals(pi.aa1.mul(ct.u.pow(pi.c1))) ==
            false ||
            y.pow(pi.rrr0).equals(pi.bb0.mul(ct.c.pow(pi.c0))) == false ||
            y.pow(pi.rrr1).equals(pi.bb1.mul(ct.c.divZ().pow(pi.c1))) == false
        ) {
            return false;
        }

        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    y.val,
                    ct.u.val,
                    ct.c.val,
                    pi.aa0.val,
                    pi.bb0.val,
                    pi.aa1.val,
                    pi.bb1.val
                )
            );
        uint256 c = uint256(digest);
        uint256 c0 = 0;
        uint256 c1 = 0;
        for (uint256 i = 0; i < 32; i++) {
            c0 =
                (c0 << 8) +
                uint256(uint8(pi.c0.val[pi.c0.val.length - 32 + i]));
            c1 =
                (c1 << 8) +
                uint256(uint8(pi.c1.val[pi.c1.val.length - 32 + i]));
        }
        return c0 + c1 == c;
    }

    function valid(
        Ct01Proof[] memory pi,
        Ct[] memory ct,
        BigNumber.instance memory y
    ) internal view returns (bool) {
        for (uint256 i = 0; i < pi.length; i++) {
            if (valid(pi[i], ct[i], y) == false) return false;
        }
        return true;
    }
}
