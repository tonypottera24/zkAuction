// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {ECPointExt} from "./ECPointLib.sol";
import {Ct, CtLib} from "./CtLib.sol";
import {Bid01Proof} from "./Bid01ProofLib.sol";
import {Bid01Proof, Bid01ProofLib} from "./Bid01ProofLib.sol";

struct Bidder {
    uint256 index;
    address addr;
    uint256 balance;
    bool malicious;
    ECPointExt elgamalY;
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

    function init(
        BidderList storage bList,
        address addr,
        uint256 balance,
        ECPointExt memory elgamalY
    ) internal {
        bList.list.push();
        bList.map[addr] = bList.list.length - 1;
        Bidder storage bidder = bList.list[bList.list.length - 1];
        bidder.index = bList.list.length - 1;
        bidder.addr = addr;
        bidder.balance = balance;
        bidder.elgamalY = elgamalY;
        bidder.malicious = false;
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
