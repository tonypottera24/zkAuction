// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import {UIntLib} from "./UIntLib.sol";
import {ECPoint, ECPointLib} from "./ECPointLib.sol";
import {Ct, CtLib} from "./CtLib.sol";

struct BiddingVectorItem {
    uint256 price;
    Ct ct;
}

library BiddingVectorItemLib {
    using UIntLib for uint256;
    using ECPointLib for ECPoint;
    using CtLib for Ct;

    function append(
        BiddingVectorItem[] storage v1,
        BiddingVectorItem[] memory v2
    ) internal {
        for (uint256 i = 0; i < v2.length; i++) {
            v1.push(v2[i]);
        }
    }

    function sum(BiddingVectorItem[] memory v)
        internal
        returns (Ct memory result)
    {
        if (v.length > 0) {
            for (uint256 i = 0; i < v.length; i++) {
                result = result.add(v[i].ct);
            }
        }
    }

    function distinct_sort(BiddingVectorItem[] storage v) internal {
        BiddingVectorItem[] memory v_sorted = v;
        qsort(v_sorted, 0, int256(v_sorted.length - 1));
        uint256 i = 0;
        v[0] = v_sorted[0];
        for (uint256 j = 1; j < v_sorted.length; j++) {
            if (v[i].price == v_sorted[j].price) {
                v[i].ct = v[i].ct.add(v_sorted[j].ct);
            } else {
                i++;
                v[i] = v_sorted[j];
            }
        }
        while (v.length > i + 1) v.pop();
        for (int256 j = int256(v.length) - 2; j >= 0; j--) {
            v[uint256(j)].ct = v[uint256(j)].ct.add(v[uint256(j + 1)].ct);
        }
    }

    function qsort(
        BiddingVectorItem[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)].price;
        while (i <= j) {
            while (arr[uint256(i)].price < pivot) i++;
            while (pivot < arr[uint256(j)].price) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) qsort(arr, left, j);
        if (i < right) qsort(arr, i, right);
    }
}
