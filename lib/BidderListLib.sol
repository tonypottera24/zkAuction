// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {Ct, CtLib} from "./CtLib.sol";
import {BigNumber} from "./BigNumber.sol";
import {BigNumberLib} from "./BigNumberLib.sol";

struct Bidder {
    uint256 index;
    address addr;
    uint256 balance;
    bool malicious;
    BigNumber.instance elgamalY;
    Ct[] bidA;
    bool hasSubmitBidCA;
    bool hasDecBidCA;
    bool win;
    bool payed;
}

struct BidderList {
    Bidder[] list;
    mapping(address => uint256) map;
}

library BidderListLib {
    using CtLib for Ct;
    using CtLib for Ct[];
    using BigNumberLib for BigNumber.instance;

    function init(
        BidderList storage bList,
        address addr,
        uint256 balance,
        BigNumber.instance memory elgamalY
    ) internal {
        bList.list.push();
        bList.map[addr] = bList.list.length - 1;
        Bidder storage bidder = bList.list[bList.list.length - 1];
        bidder.index = bList.list.length - 1;
        bidder.addr = addr;
        bidder.balance = balance;
        bidder.elgamalY = elgamalY;
    }

    function get(BidderList storage bList, uint256 i)
        internal
        view
        returns (Bidder storage)
    {
        return bList.list[i];
    }

    function find(BidderList storage bList, address addr)
        internal
        view
        returns (Bidder storage)
    {
        uint256 i = bList.map[addr];
        if (i == 0 && get(bList, i).addr != addr) revert("Bidder not found.");
        return get(bList, i);
    }

    function length(BidderList storage bList) internal view returns (uint256) {
        return bList.list.length;
    }

    function malicious(BidderList storage bList) internal view returns (bool) {
        for (uint256 i = 0; i < length(bList); i++) {
            if (get(bList, i).malicious) return true;
        }
        return false;
    }
}
