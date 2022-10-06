// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;
import {BigNumber} from "./BigNumber.sol";

library BigNumberLib {
    function equals(
        BigNumber.instance memory a,
        BigNumber.instance memory b,
        BigNumber.instance memory p
    ) internal view returns (bool) {
        if (a.bitlen == 0 && b.bitlen == 0) return true;
        return BigNumber.cmp(mod(a, p), mod(b, p), false) == 0;
    }

    function isZero(BigNumber.instance memory a, BigNumber.instance memory p)
        internal
        view
        returns (bool)
    {
        if (a.bitlen == 0) return true;
        BigNumber.instance memory b0 = BigNumber.instance(
            hex"0000000000000000000000000000000000000000000000000000000000000000",
            false,
            0
        );
        return BigNumber.cmp(mod(a, p), mod(b0, p), false) == 0;
    }

    function isOne(BigNumber.instance memory a, BigNumber.instance memory p)
        internal
        view
        returns (bool)
    {
        if (a.bitlen == 0) return false;
        BigNumber.instance memory b1 = BigNumber.instance(
            hex"0000000000000000000000000000000000000000000000000000000000000001",
            false,
            1
        );
        return BigNumber.cmp(mod(a, p), mod(b1, p), false) == 0;
    }

    function mod(BigNumber.instance memory a, BigNumber.instance memory p)
        internal
        view
        returns (BigNumber.instance memory)
    {
        BigNumber.instance memory ans = BigNumber.bn_mod(a, p);
        if (ans.neg == true) ans = BigNumber.prepare_add(ans, p);
        return ans;
    }

    function mul(
        BigNumber.instance memory a,
        BigNumber.instance memory b,
        BigNumber.instance memory p
    ) internal view returns (BigNumber.instance memory) {
        return BigNumber.modmul(mod(a, p), mod(b, p), p);
    }

    function pow(
        BigNumber.instance memory a,
        BigNumber.instance memory k,
        BigNumber.instance memory p
    ) internal view returns (BigNumber.instance memory) {
        return BigNumber.prepare_modexp(mod(a, p), k, p);
    }
}
