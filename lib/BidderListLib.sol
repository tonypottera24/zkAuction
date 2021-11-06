// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {ECPoint} from "./ECPointLib.sol";
import {Ct, CtLib} from "./CtLib.sol";
import {BiddingVectorItem, BiddingVectorItemLib} from "./BiddingVectorItemLib.sol";

struct Bidder {
    address addr;
    uint256 stake;
    bool isMalicious;
    ECPoint pk;
    BiddingVectorItem[] a;
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

    function init(
        BidderList storage bList,
        address addr,
        uint256 stake,
        ECPoint memory pk
    ) internal {
        bList.list.push();
        bList.map[addr] = bList.list.length - 1;
        Bidder storage B = bList.list[bList.list.length - 1];
        B.addr = addr;
        B.stake = stake;
        B.pk = pk;
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

    function isMalicious(BidderList storage bList)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < length(bList); i++) {
            if (get(bList, i).isMalicious) return true;
        }
        return false;
    }
}
