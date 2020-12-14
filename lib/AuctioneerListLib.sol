// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {ECPointExt} from "./ECPointLib.sol";

struct Auctioneer {
    uint256 index;
    address payable addr;
    uint256 balance;
    ECPointExt elgamalY;
    bool malicious;
}

struct AuctioneerList {
    Auctioneer[] list;
    mapping(address => uint256) map;
}

library AuctioneerListLib {
    function add(AuctioneerList storage aList, address payable addr) internal {
        aList.list.push();
        aList.map[addr] = aList.list.length - 1;
        Auctioneer storage auctioneer = aList.list[aList.list.length - 1];
        auctioneer.index = aList.list.length - 1;
        auctioneer.addr = addr;
    }

    function get(AuctioneerList storage aList, uint256 i)
        internal
        view
        returns (Auctioneer storage)
    {
        return aList.list[i];
    }

    function find(AuctioneerList storage aList, address addr)
        internal
        view
        returns (Auctioneer storage)
    {
        uint256 i = aList.map[addr];
        if (i == 0 && get(aList, i).addr != addr)
            revert("Auctioneer not found.");
        return get(aList, i);
    }

    function length(AuctioneerList storage aList)
        internal
        view
        returns (uint256)
    {
        return aList.list.length;
    }

    function malicious(AuctioneerList storage aList)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < length(aList); i++) {
            if (get(aList, i).malicious) return true;
        }
        return false;
    }
}
