// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;
import {BigNumber} from "./BigNumber.sol";

library BigNumberLib {
    uint256 public constant bitLength = 3072;

    function from_uint256(uint256 a)
        internal
        pure
        returns (BigNumber.instance memory)
    {
        uint256 bit_length = 0;
        for (uint256 i = 0; i < 256; i++) {
            if ((a >> i) > 0) bit_length++;
            else break;
        }
        bytes memory a_packed = abi.encodePacked(a);
        bytes memory packed = new bytes(32);
        for (uint256 i = 0; i < packed.length && i < a_packed.length; i++) {
            packed[packed.length - i - 1] = a_packed[a_packed.length - i - 1];
        }
        return BigNumber.instance(packed, false, bit_length);
    }

    function zero() internal pure returns (BigNumber.instance memory) {
        return
            BigNumber.instance(
                hex"0000000000000000000000000000000000000000000000000000000000000000",
                false,
                0
            );
    }

    function one() internal pure returns (BigNumber.instance memory) {
        return
            BigNumber.instance(
                hex"0000000000000000000000000000000000000000000000000000000000000001",
                false,
                1
            );
    }

    function p() internal pure returns (BigNumber.instance memory) {
        if (bitLength == 1024) {
            return
                BigNumber.instance(
                    hex"e6eae100576ae255abcc28ad5702afdf3713109933cc809d106aa87a26a975914b5d4763bff62b718b122072b50023b3d12be2d90f8203fd30ed2051fa8faa959117097e284cc81e8e0c4c015524ed3eef7bf1feaedaf43ba08ef2f85f930e6851d9f4a7c89192953c6aff6afdb24daf44a39f0e63727c45c72317fe50e61f0f",
                    false,
                    1024
                );
        } else if (bitLength == 2048) {
            return
                BigNumber.instance(
                    hex"913e12504b80d82c6819e21fa7fa53cdb0583a9ff5d46ba805b33abe417c398a5ac4a874ce894faee67180a5ff8d14caeb2ff602af9f3739ca12680b67d7d78c6ff48b77e1a7cfc6d0ea2e53cdcb77e90970ebb5c26a14fe9ed84b9f486961186347f60fe74fc0681610b404f7ad9bb8f26de73b4b42ea037cf5d24d9545020726207373ae75b05157776387d592c6fc0005d9aa617283da410e26244424151f56b3b486548fe59a3245fe57f5f16aafbbb17fa7401186a7afd80add3f33c4c505a1b8f6c2ae71269171f10e8fa9fbf929b201abae5b20548339049ff147ba799a037d3fc854e5608418269788cbf9a8a4e6c33343bfcdbb3f03e80aef72525f",
                    false,
                    2048
                );
        } else if (bitLength == 3072) {
            return
                BigNumber.instance(
                    hex"f9c610b2c0cd225ba3b96eaa3f3aaaa8ab87fc992e5fb4629fc9d6ddeeaefd24d003a3f6ef0dd2ade5d4cf44c8e9b991140409afde3f6b7a20046ddf519548bbefdbf6b7a053c035d3d8f0baf04baa5498c60d573eea51441a9b2886536745873165d7211b98a1ff4c71ecbf5430c0490e196e0bfa751cbfc7532e1d032283aeaf8bd844181945a064d3ec36794462ece2799f7397363f6e8095ed21fe322a50a317e6045e8cbef654086e4b433b766248f429660fbd1504591ca8876f4e2bb39e5e21ef14d7aaedb257931abda891b151211c3d4699bb0a3ee9276c75312dd033f7a6518bdf8f5dce3699bb24e0f73baf3b6a79231e833e779a314424de2cf210f2a5292ac2b50ac383c3f290eeb6edffcfd0220d6f9db9317a9bbbad8526d25124ba4b9ad42c0154c9a061e324a87fc580157f8d3a1dee5e8856881ba8c40195fafce21dff72e548b9ad9bfe8fb8d54a250be28bd7bbbe85307725c6d981ff188a6625ab651472c4363a7f750a32b1cee27a7eeee8ed8cdcae6b8dbadbf0ff",
                    false,
                    3072
                );
        } else {
            revert("bitLength not exist.");
        }
    }

    function q() internal pure returns (BigNumber.instance memory) {
        if (bitLength == 1024) {
            return
                BigNumber.instance(
                    hex"737570802bb5712ad5e61456ab8157ef9b89884c99e6404e8835543d1354bac8a5aea3b1dffb15b8c58910395a8011d9e895f16c87c101fe98769028fd47d54ac88b84bf1426640f47062600aa92769f77bdf8ff576d7a1dd047797c2fc9873428ecfa53e448c94a9e357fb57ed926d7a251cf8731b93e22e3918bff28730f87",
                    false,
                    1023
                );
        } else if (bitLength == 2048) {
            return
                BigNumber.instance(
                    hex"489f092825c06c16340cf10fd3fd29e6d82c1d4ffaea35d402d99d5f20be1cc52d62543a6744a7d77338c052ffc68a657597fb0157cf9b9ce5093405b3ebebc637fa45bbf0d3e7e368751729e6e5bbf484b875dae1350a7f4f6c25cfa434b08c31a3fb07f3a7e0340b085a027bd6cddc7936f39da5a17501be7ae926caa28103931039b9d73ad828abbbb1c3eac9637e0002ecd530b941ed2087131222120a8fab59da432a47f2cd1922ff2bfaf8b557ddd8bfd3a008c353d7ec056e9f99e26282d0dc7b6157389348b8f88747d4fdfc94d900d5d72d902a419c824ff8a3dd3ccd01be9fe42a72b0420c134bc465fcd452736199a1dfe6dd9f81f40577b9292f",
                    false,
                    2047
                );
        } else if (bitLength == 3072) {
            return
                BigNumber.instance(
                    hex"7ce308596066912dd1dcb7551f9d555455c3fe4c972fda314fe4eb6ef7577e926801d1fb7786e956f2ea67a26474dcc88a0204d7ef1fb5bd100236efa8caa45df7edfb5bd029e01ae9ec785d7825d52a4c6306ab9f7528a20d4d944329b3a2c398b2eb908dcc50ffa638f65faa186024870cb705fd3a8e5fe3a9970e819141d757c5ec220c0ca2d03269f61b3ca23176713ccfb9cb9b1fb7404af690ff191528518bf3022f465f7b2a043725a19dbb31247a14b307de8a822c8e5443b7a715d9cf2f10f78a6bd576d92bc98d5ed448d8a8908e1ea34cdd851f7493b63a9896e819fbd328c5efc7aee71b4cdd92707b9dd79db53c918f419f3bcd18a2126f16790879529495615a8561c1e1f948775b76ffe7e81106b7cedc98bd4dddd6c2936928925d25cd6a1600aa64d030f192543fe2c00abfc69d0ef72f442b440dd46200cafd7e710effb972a45cd6cdff47dc6aa51285f145ebdddf42983b92e36cc0ff8c453312d5b28a39621b1d3fba851958e7713d3f777476c66e5735c6dd6df87f",
                    false,
                    3071
                );
        } else {
            revert("bitLength not exist.");
        }
    }

    function g() internal pure returns (BigNumber.instance memory) {
        return
            BigNumber.instance(
                hex"0000000000000000000000000000000000000000000000000000000000000002",
                false,
                2
            );
    }

    function gInv() internal pure returns (BigNumber.instance memory) {
        if (bitLength == 1024) {
            return
                BigNumber.instance(
                    hex"737570802bb5712ad5e61456ab8157ef9b89884c99e6404e8835543d1354bac8a5aea3b1dffb15b8c58910395a8011d9e895f16c87c101fe98769028fd47d54ac88b84bf1426640f47062600aa92769f77bdf8ff576d7a1dd047797c2fc9873428ecfa53e448c94a9e357fb57ed926d7a251cf8731b93e22e3918bff28730f88",
                    false,
                    1023
                );
        } else if (bitLength == 2048) {
            return
                BigNumber.instance(
                    hex"489f092825c06c16340cf10fd3fd29e6d82c1d4ffaea35d402d99d5f20be1cc52d62543a6744a7d77338c052ffc68a657597fb0157cf9b9ce5093405b3ebebc637fa45bbf0d3e7e368751729e6e5bbf484b875dae1350a7f4f6c25cfa434b08c31a3fb07f3a7e0340b085a027bd6cddc7936f39da5a17501be7ae926caa28103931039b9d73ad828abbbb1c3eac9637e0002ecd530b941ed2087131222120a8fab59da432a47f2cd1922ff2bfaf8b557ddd8bfd3a008c353d7ec056e9f99e26282d0dc7b6157389348b8f88747d4fdfc94d900d5d72d902a419c824ff8a3dd3ccd01be9fe42a72b0420c134bc465fcd452736199a1dfe6dd9f81f40577b92930",
                    false,
                    2046
                );
        } else if (bitLength == 3072) {
            return
                BigNumber.instance(
                    hex"7ce308596066912dd1dcb7551f9d555455c3fe4c972fda314fe4eb6ef7577e926801d1fb7786e956f2ea67a26474dcc88a0204d7ef1fb5bd100236efa8caa45df7edfb5bd029e01ae9ec785d7825d52a4c6306ab9f7528a20d4d944329b3a2c398b2eb908dcc50ffa638f65faa186024870cb705fd3a8e5fe3a9970e819141d757c5ec220c0ca2d03269f61b3ca23176713ccfb9cb9b1fb7404af690ff191528518bf3022f465f7b2a043725a19dbb31247a14b307de8a822c8e5443b7a715d9cf2f10f78a6bd576d92bc98d5ed448d8a8908e1ea34cdd851f7493b63a9896e819fbd328c5efc7aee71b4cdd92707b9dd79db53c918f419f3bcd18a2126f16790879529495615a8561c1e1f948775b76ffe7e81106b7cedc98bd4dddd6c2936928925d25cd6a1600aa64d030f192543fe2c00abfc69d0ef72f442b440dd46200cafd7e710effb972a45cd6cdff47dc6aa51285f145ebdddf42983b92e36cc0ff8c453312d5b28a39621b1d3fba851958e7713d3f777476c66e5735c6dd6df880",
                    false,
                    3071
                );
        } else {
            revert("bitLength not exist.");
        }
    }

    function z() internal pure returns (BigNumber.instance memory) {
        return
            BigNumber.instance(
                hex"0000000000000000000000000000000000000000000000000000000000000003",
                false,
                2
            );
    }

    function zInv() internal pure returns (BigNumber.instance memory) {
        if (bitLength == 1024) {
            return
                BigNumber.instance(
                    hex"4cf8f5aac7ce4b71e3eeb839c7ab8ff5125bb03311442adf0578e2d362387c85c3c9c27695520e7b2e5b60263c55613bf063f6485a80abff104f0ac5fe2fe387305d032a0d6eed5f84aec40071b6f9bfa52950aa3a48fc13e02fa652ca865a22c5f3518d42db30dc6978ffce5490c48fc18bdfaf767b7ec1ed0bb2aa1af75fb0",
                    false,
                    1023
                );
        } else if (bitLength == 2048) {
            return
                BigNumber.instance(
                    hex"306a061ac3d59d6422b34b5fe2a8c699e572be3551f1793801e668ea15d4132e1e418d7c44d86fe4f77b2ae1ffd9b198f90ffcab8fdfbd13435b7803cd47f284255183d2a08d454245a364c699ee7d4dadd04e91eb78b1aa34f2c3dfc2cdcb082117fcaff7c54022b2059156fd39de92fb79f7be6e6ba3567efc9b6f31c1ab57b760267be4d1e570727d212d4730ecfeaaac9de375d0d69e15af620c16b6b1b51ce691821c2ff733661754c7fca5ce3a93e5d537c005d78d3a9d58f46a6696ec5735e85240e4d062307b505a2fe353fdb890ab393a1e601c2bbdac35506d3e2888abd46a981c4c75815d623282eea88d8c4cebbbc13fef3e6a56a2ae4fd0c620",
                    false,
                    2046
                );
        } else if (bitLength == 3072) {
            return
                BigNumber.instance(
                    hex"53420590eaef0b73e13dcf8e15138e38392d54330f753c20dfedf249fa3a54619aabe1524faf4639f746efc1984de885b156ade54a1523d3600179f51b31c2e94ff3fce7e01beabc9bf2fae8fac3e371884204726a4e1b16b3890d821bcd172d107747b5b3dd8b55197b4eea7165956daf5dcf59537c5eea97c664b45660d68f8fd94816b2b3173576f14ebcd316cba44b7ddfd132676a7a2adca460aa10b8c58bb2a20174d994fcc6ad7a191669277618516322053f070173098d827a6f63e68a1f60a506f28e4f3b72865e3f38309070605ebf178893ae14f862797c65b9f011528cc5d94a851f44bcdde90c4afd13e513ce28610a2bbf7d3365c1619f6450b050e1b863963c58ebd696a6304f924f55454560af253493107e33e939d70cf0c5b6e8c3de46b955c6ede020a10c382a972ab1d52f135f4f74d81cd809384155dca8fef609ffd0f7183de48954da92f1c361aea0d947e93f81bad261ecf32b55082e220c8e7706d0ec12137fd1ae10e5efa0d37fa4f84f2ef43a23d9e8f3fb00",
                    false,
                    3071
                );
        } else {
            revert("bitLength not exist.");
        }
    }

    function equals(BigNumber.instance memory a, BigNumber.instance memory b)
        internal
        view
        returns (bool)
    {
        if (isNotSet(a) && isNotSet(b)) return true;
        if (isNotSet(a) || isNotSet(b)) return false;
        return BigNumber.cmp(modP(a), modP(b), false) == 0;
    }

    function equals(
        BigNumber.instance[] memory a,
        BigNumber.instance[] memory b
    ) internal view returns (bool) {
        if (a.length != b.length) return false;
        for (uint256 i = 0; i < a.length; i++) {
            if (equals(a[i], b[i]) == false) return false;
        }
        return true;
    }

    function isNotSet(BigNumber.instance memory a)
        internal
        view
        returns (bool)
    {
        if (a.bitlen == 0) return true;
        return BigNumber.cmp(modP(a), zero(), false) == 0;
    }

    function isNotSet(BigNumber.instance[] memory a)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < a.length; i++) {
            if (isNotSet(a[i]) == false) return false;
        }
        return true;
    }

    function isIdentityElement(BigNumber.instance memory a)
        internal
        view
        returns (bool)
    {
        if (a.bitlen == 0) return false;
        return BigNumber.cmp(modP(a), modP(one()), false) == 0;
    }

    function modP(BigNumber.instance memory a)
        internal
        view
        returns (BigNumber.instance memory)
    {
        BigNumber.instance memory ans = BigNumber.bn_mod(a, p());
        if (ans.neg == true) ans = BigNumber.prepare_add(ans, p());
        return ans;
    }

    function modQ(BigNumber.instance memory a)
        internal
        view
        returns (BigNumber.instance memory)
    {
        BigNumber.instance memory ans = BigNumber.bn_mod(a, q());
        if (ans.neg == true) ans = BigNumber.prepare_add(ans, q());
        return ans;
    }

    function mul(BigNumber.instance memory a, BigNumber.instance memory b)
        internal
        view
        returns (BigNumber.instance memory)
    {
        return BigNumber.modmul(modP(a), modP(b), p());
    }

    function mul(BigNumber.instance[] memory a, BigNumber.instance[] memory b)
        internal
        view
        returns (BigNumber.instance[] memory)
    {
        require(a.length == b.length, "a.length != b.length");
        BigNumber.instance[] memory result = new BigNumber.instance[](a.length);
        for (uint256 i = 0; i < a.length; i++) {
            result[i] = mul(a[i], b[i]);
        }
        return result;
    }

    function pow(BigNumber.instance memory a, BigNumber.instance memory k)
        internal
        view
        returns (BigNumber.instance memory)
    {
        return BigNumber.prepare_modexp(modP(a), k, p());
    }

    function divZ(BigNumber.instance memory a)
        internal
        view
        returns (BigNumber.instance memory)
    {
        return mul(a, zInv());
    }

    function divG(BigNumber.instance memory a)
        internal
        view
        returns (BigNumber.instance memory)
    {
        return mul(a, gInv());
    }
}
