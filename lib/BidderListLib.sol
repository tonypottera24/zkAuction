// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

import {Ct, CtLib} from "./CtLib.sol";
import {Bid01Proof} from "./Bid01ProofLib.sol";
import {Bid01Proof, Bid01ProofLib} from "./Bid01ProofLib.sol";

struct Bidder {
    uint256 index;
    address payable addr;
    uint256 balance;
    bool malicious;
    Ct[] bid;
    Ct bidSum;
    Bid01Proof[] bid01Proof;
    Ct[] bidA;
}

struct BidderList {
    Bidder[] list;
    mapping(address => uint256) map;
}

library BidderListLib {
    using CtLib for Ct;
    using CtLib for Ct[];
    using Bid01ProofLib for Bid01Proof;
    using Bid01ProofLib for Bid01Proof[];

    event BidderListLibEvent(uint256 j0);

    function add(
        BidderList storage bList,
        address payable addr,
        uint256 balance,
        Ct[] memory bid
    ) internal {
        bList.list.push();
        bList.map[addr] = bList.list.length - 1;
        Bidder storage bidder = bList.list[bList.list.length - 1];
        bidder.index = bList.list.length - 1;
        bidder.addr = addr;
        bidder.balance = balance;
        bidder.malicious = false;
        for (uint256 j = 0; j < bid.length; j++) {
            bidder.bid.push(bid[j]);
            bidder.bidA.push(bid[j]);
            bidder.bid01Proof.push();
        }
        bidder.bid01Proof.setU(bid);
        bidder.bidSum = bid.sum();
        require(bidder.bidA.length >= 2, "bidder.bidA.length < 2");
        for (uint256 j = bidder.bidA.length - 2; j >= 0; j--) {
            bidder.bidA[j] = bList.list[bList.list.length - 1].bidA[j].add(
                bList.list[bList.list.length - 1].bidA[j + 1]
            );
            if (j == 0) break;
        }
    }

    function remove(BidderList storage bList, uint256 i) internal {
        bList.list[i] = bList.list[bList.list.length - 1];
        bList.list.pop();
        bList.map[bList.list[i].addr] = i;
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
        if (i == 0 && get(bList, i).addr != addr)
            revert("Auctioneer not found.");
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

    function removeMalicious(BidderList storage bList) internal {
        for (uint256 i = 0; i < length(bList); i++) {
            if (get(bList, i).malicious) {
                remove(bList, i);
                i--;
            }
        }
    }
}
