// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import {ECPoint, ECPointLib} from "./lib/ECPointLib.sol";
import {Bidder, BidderList, BidderListLib} from "./lib/BidderListLib.sol";
import {Ct, CtLib} from "./lib/CtLib.sol";
import {Ct01Proof, Ct01ProofLib} from "./lib/Ct01ProofLib.sol";
import {CtMProof, CtMProofLib} from "./lib/CtMProofLib.sol";
import {DLProof, DLProofLib} from "./lib/DLProofLib.sol";
import {SameDLProof, SameDLProofLib} from "./lib/SameDLProofLib.sol";
import {Timer, TimerLib} from "./lib/TimerLib.sol";

contract Auction {
    using ECPointLib for ECPoint;
    using BidderListLib for BidderList;
    using CtLib for Ct;
    using CtLib for Ct[];
    using DLProofLib for DLProof;
    using DLProofLib for DLProof[];
    using Ct01ProofLib for Ct01Proof;
    using Ct01ProofLib for Ct01Proof[];
    using CtMProofLib for CtMProof;
    using CtMProofLib for CtMProof[];
    using SameDLProofLib for SameDLProof;
    using SameDLProofLib for SameDLProof[];
    using TimerLib for Timer;

    address sellerAddr;
    BidderList bList;
    ECPoint public pk;
    uint256 public M;
    uint256[7] successCount;
    uint256 public minimumStake;
    bool public auctionAborted;
    Timer[7] public timer;
    uint64 public phase;

    Ct[] public c;
    Ct[] public mixedC;
    uint256 public jM;

    uint256[] public price;
    uint256 public m1stPrice;

    ECPoint[] public zM;

    function priceLength() public view returns (uint256) {
        return price.length;
    }

    constructor(
        uint256 _M,
        uint256[] memory _price,
        uint256[7] memory _timeout,
        uint256 _minimumStake
    ) {
        sellerAddr = msg.sender;
        require(_M > 0, "M <= 0");
        M = _M;
        require(_price.length >= 2, "price.length must be at least 2.");
        price = _price;
        require(
            _timeout.length == timer.length,
            "timeout.length != timer.length"
        );
        for (uint256 i = 0; i < _timeout.length; i++) {
            require(_timeout[i] > 0, "_timeout[i] <= 0");
            timer[i].timeout = _timeout[i];
        }
        timer[1].start = block.timestamp;
        timer[2].start = timer[1].start + timer[1].timeout;
        minimumStake = _minimumStake;
        phase = 1;

        zM.push(ECPointLib.identityElement());
        for (uint256 k = 1; k <= _M; k++) {
            zM.push(zM[k - 1].add(ECPointLib.z()));
        }
    }

    function phase1BidderInit(ECPoint memory _pk, DLProof memory _pi)
        public
        payable
    {
        require(phase == 1, "phase != 1");
        require(timer[1].exceeded() == false, "timer[1].exceeded() == true");
        require(_pk.isIdentityElement() == false, "pk must not be zero");
        require(_pi.valid(ECPointLib.g(), _pk), "Discrete log proof invalid.");
        require(
            msg.value >= minimumStake,
            "Bidder's deposit must larger than minimumStake."
        );
        bList.init(msg.sender, msg.value, _pk);
        pk = pk.add(_pk);
    }

    function phase1Success() public view returns (bool) {
        return bList.length() > M && timer[1].exceeded();
    }

    function phase1Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(phase == 1, "phase != 1");
        require(phase1Success() == false, "phase1Success() == true");
        require(timer[1].exceeded(), "timer[1].exceeded() == false");
        returnAllStake();
        auctionAborted = true;
    }

    function phase2BidderSubmitBid(
        Ct[] memory _v,
        Ct01Proof[] memory _v_01_proof,
        CtMProof memory _v_sum_proof
    ) public {
        if (phase == 1 && phase1Success()) phase = 2;
        require(phase == 2, "phase != 2");
        require(timer[2].exceeded() == false, "timer[2].exceeded() == true");
        Bidder storage bidder = bList.find(msg.sender);
        require(
            bidder.addr != address(0),
            "Bidder can only submit their bids if they join in phase 1."
        );
        require(
            _v.length == price.length && _v_01_proof.length == price.length,
            "bid.length != price.length || pi01.length != price.length"
        );
        require(_v_01_proof.valid(_v, pk), "Ct01Proof not valid.");
        require(_v_sum_proof.valid(_v.sum(), pk, zM[1]), "CtMProof not valid.");

        require(bidder.a.length == 0, "Already submit bid.");
        bidder.a.set(_v);

        for (uint256 j = bidder.a.length - 2; j >= 0; j--) {
            bidder.a[j] = bidder.a[j].add(bidder.a[j + 1]);
            if (j == 0) break; // j is unsigned. it will never be negative
        }

        if (c.length == 0) c.set(bidder.a);
        else c.set(c.add(bidder.a));

        successCount[2]++;

        if (phase2Success()) {
            c.set(c.subC(zM[M]));
            timer[3].start = block.timestamp;
        }
    }

    function phase2Success() public view returns (bool) {
        return successCount[2] == bList.length();
    }

    function phase2Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(phase == 2, "phase != 2");
        require(phase2Success() == false, "phase2Success() == true");
        require(timer[2].exceeded(), "timer[2].exceeded() == false");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).a.length != price.length) {
                bList.get(i).isMalicious = true;
            }
        }
        compensateHonestBidders();
        auctionAborted = true;
        // TODO remove malicious bidder and continue.
    }

    function phase3M1stPriceDecisionMix(
        Ct[] memory _mixedC,
        SameDLProof[] memory _pi
    ) public {
        if (phase == 2 && phase2Success()) phase = 3;
        require(phase == 3, "phase != 3");
        require(timer[3].exceeded() == false, "timer[3].exceeded() == true");
        require(
            _pi.length == price.length && _mixedC.length == price.length,
            "pi, ctA, price must have same length."
        );
        Bidder storage bidder = bList.find(msg.sender);
        require(bidder.hasSubmitMixedC == false, "bidder.hasSubmitMix == true");
        for (uint256 j = 0; j < mixedC.length; j++) {
            require(
                _pi[j].valid(mixedC[j].u, c[j].c, _mixedC[j].u, _mixedC[j].c),
                "SDL proof is not valid"
            );
        }
        if (mixedC.length == 0) mixedC.set(_mixedC);
        else mixedC.set(mixedC.add(_mixedC));
        bidder.hasSubmitMixedC = true;
        successCount[3]++;
        if (phase3Success()) timer[4].start = block.timestamp;
    }

    function phase3Success() public view returns (bool) {
        return successCount[3] == bList.length();
    }

    function phase3Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(phase == 3, "phase != 3");
        require(phase3Success() == false, "phase3Success() == true");
        require(timer[3].exceeded(), "timer[3].exceeded() == false");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).hasSubmitMixedC == false) {
                bList.get(i).isMalicious = true;
            }
        }
        compensateHonestBidders();
        auctionAborted = true;
    }

    function phase4M1stPriceDecision(ECPoint memory ux, SameDLProof memory pi)
        public
    {
        if (phase == 3 && phase3Success()) phase = 4;
        require(phase == 4, "phase != 4");
        require(timer[4].exceeded() == false, "Phase 4 time's up.");
        Bidder storage bidder = bList.find(msg.sender);
        require(bidder.hasDecMixedC == false, "bidder has decrypt mixedC.");
        mixedC[jM] = mixedC[jM].decrypt(bidder, ux, pi);

        bidder.hasDecMixedC = true;
        successCount[4]++;
        if (
            successCount[4] == bList.length() &&
            mixedC[jM].c.isIdentityElement() == false
        ) {
            jM++;
            for (uint256 i = 0; i < bList.length(); i++) {
                bList.get(i).hasDecMixedC = false;
            }
            successCount[4] = 0;
        }

        if (phase4Success()) timer[5].start = block.timestamp;
    }

    function phase4Success() public view returns (bool) {
        return
            jM < price.length &&
            successCount[4] == bList.length() &&
            mixedC[jM].c.isIdentityElement();
    }

    function phase4Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(phase == 4, "phase != 4");
        require(phase4Success() == false, "phase4Success() == true");
        require(timer[4].exceeded(), "timer[4].exceeded() == false");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).hasDecMixedC == false) {
                bList.get(i).isMalicious = true;
            }
        }
        compensateHonestBidders();
        auctionAborted = true;
    }

    function phase5WinnerDecision(CtMProof memory piM) public {
        if (phase == 4 && phase4Success()) phase = 5;
        require(phase == 5, "phase != 5");
        require(timer[5].exceeded() == false, "Phase 5 time's up.");
        Bidder storage bidder = bList.find(msg.sender);
        require(bidder.win == false, "Bidder has already declare win.");
        require(piM.valid(bidder.a[jM], pk, zM[1]), "CtMProof not valid.");
        bidder.win = true;
        successCount[5]++;
        if (phase5Success()) timer[6].start = block.timestamp;
    }

    function phase5Success() public view returns (bool) {
        return successCount[5] == M;
    }

    function phase5Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(phase == 5, "phase != 5");
        require(phase5Success() == false, "phase5Success() == true");
        require(timer[5].exceeded(), "timer[5].exceeded() == false");
        require(successCount[5] == 0, "There are still some winners.");
        returnAllStake();
        auctionAborted = true;
    }

    function phase6Payment() public payable {
        if (phase == 5 && phase5Success()) phase = 6;
        require(phase == 6, "phase != 6");
        require(timer[6].exceeded() == false, "timer[6].exceeded() == true");
        Bidder storage bidder = bList.find(msg.sender);
        require(bidder.win, "Only winner needs to pay.");
        require(bidder.payed == false, "Only need to pay once.");
        require(
            msg.value == price[jM - 1],
            "msg.value must equals to the second highest price."
        );
        payable(sellerAddr).transfer(msg.value);
        bidder.payed = true;
        successCount[6]++;
        if (phase6Success()) returnAllStake();
    }

    function phase6Success() public view returns (bool) {
        return phase == 6 && successCount[6] == successCount[5];
    }

    function phase6Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(phase == 6, "phase != 6");
        require(phase6Success() == false, "phase6Success() == true");
        require(timer[6].exceeded(), "timer[6].exceeded() == false");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).win && bList.get(i).payed == false) {
                bList.get(i).isMalicious = true;
            }
        }
        if (bList.isMalicious()) compensateHonestBidders();
        else returnAllStake();
        auctionAborted = true;
    }

    function getStake() public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](bList.length());
        for (uint256 i = 0; i < bList.length(); i++) {
            result[i] = bList.get(i).stake;
        }
        return result;
    }

    function returnAllStake() internal {
        require(bList.isMalicious() == false);
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).stake > 0) {
                payable(bList.get(i).addr).transfer(bList.get(i).stake);
                bList.get(i).stake = 0;
            }
        }
    }

    function compensateHonestBidders() internal {
        require(bList.isMalicious(), "Bidders are not malicious.");
        uint256 d = 0;
        uint256 maliciousBidderCount = 0;
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).isMalicious) {
                d += bList.get(i).stake;
                bList.get(i).stake = 0;
                maliciousBidderCount++;
            }
        }
        d /= bList.length() - maliciousBidderCount;
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).isMalicious == false)
                payable(bList.get(i).addr).transfer(d);
        }
    }
}
