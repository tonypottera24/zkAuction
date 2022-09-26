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
    Ct[] public bidC;
    Ct[] public bidCA;
    uint256 public jM;
    uint256 public minimumStake;
    uint256[] public price;
    bool public auctionAborted;
    Timer[7] public timer;
    uint64 public phase;
    ECPoint[] public zM;

    function bListLength() public view returns (uint256) {
        return bList.length();
    }

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
            require(_timeout[i] > 0, "Timer duration must larger than zero.");
            timer[i].timeout = _timeout[i];
        }
        timer[1].start = block.timestamp;
        timer[2].start = timer[1].start + timer[1].timeout;
        minimumStake = _minimumStake;
        phase = 1;

        for (uint256 k = 1; k <= _M; k++) {
            zM.push(zM[k - 1].add(ECPointLib.z()));
        }
    }

    function isPhase1() internal view returns (bool) {
        return phase1Success() == false;
    }

    function phase1BidderInit(ECPoint memory _pk, DLProof memory pi)
        public
        payable
    {
        require(isPhase1(), "Phase 0 not completed yet.");
        require(timer[0].exceeded() == false, "Phase 1 time's up.");
        require(_pk.isIdentityElement() == false, "pk must not be zero");
        require(pi.valid(ECPointLib.g(), _pk), "Discrete log proof invalid.");
        require(
            msg.value >= minimumStake,
            "Bidder's deposit must larger than minimumStake."
        );
        bList.init(msg.sender, msg.value, _pk);
        _pk = _pk.add(_pk);
    }

    function phase1Success() public view returns (bool) {
        return bList.length() > M && timer[0].exceeded();
    }

    function phase1Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase1(), "Phase 1 completed successfully.");
        require(timer[0].exceeded(), "Phase 1 still have time to complete.");
        returnAllStake();
        auctionAborted = true;
    }

    function isPhase2() internal view returns (bool) {
        return isPhase1() == false && phase2Success() == false;
    }

    function phase2BidderSubmitBid(
        Ct[] memory bid,
        Ct01Proof[] memory pi01,
        CtMProof memory piM
    ) public {
        require(isPhase2(), "Phase 1 not completed yet.");
        require(timer[1].exceeded() == false, "Phase 2 time's up.");
        Bidder storage bidder = bList.find(msg.sender);
        require(
            bidder.addr != address(0),
            "Bidder can only submit their bids if they join in phase 1."
        );
        require(bidder.a.length == 0, "Already submit bid.");
        require(
            bid.length == price.length && pi01.length == price.length,
            "bid.length, pi01.length, price.length must be same."
        );
        require(pi01.valid(bid, pk), "Ct01Proof not valid.");
        require(piM.valid(pk, bid.sum(), zM[1]), "CtMProof not valid.");

        bidder.a.set(bid);
        for (uint256 j = bidder.a.length - 2; j >= 0; j--) {
            bidder.a[j] = bidder.a[j].add(bidder.a[j + 1]);
            if (j == 0) break; // j is unsigned. it will never be negative
        }
        if (bidC.length == 0) bidC.set(bidder.a);
        else bidC.set(bidC.add(bidder.a));
        successCount[2]++;
        if (phase2Success()) {
            bidC.set(bidC.subC(ECPointLib.z().scalar(M)));
            timer[2].start = block.timestamp;
        }
    }

    function phase2Success() public view returns (bool) {
        return successCount[2] == bList.length();
    }

    function phase2Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase2(), "Phase 2 completed successfully.");
        require(timer[1].exceeded(), "Phase 2 still have time to complete.");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).a.length != price.length) {
                bList.get(i).malicious = true;
            }
        }
        compensateBidderMalicious();
        auctionAborted = true;
        // NOTE: remove malicious bidder and continue.
    }

    function isPhase3() internal view returns (bool) {
        return
            isPhase1() == false &&
            isPhase2() == false &&
            phase3Success() == false;
    }

    function phase3M1stPriceDecisionPrepare(
        Ct[] memory ctA,
        SameDLProof[] memory pi
    ) public {
        require(isPhase3(), "Phase 3 not completed yet.");
        require(timer[2].exceeded() == false, "Phase 3 time's up.");
        require(
            pi.length == price.length && ctA.length == price.length,
            "pi, ctA, price must have same length."
        );
        Bidder storage bidder = bList.find(msg.sender);
        require(
            bidder.hasSubmitCR == false,
            "bidder has already submit bidCA."
        );
        for (uint256 j = 0; j < bidCA.length; j++) {
            require(
                pi[j].valid(bidC[j].u, bidC[j].c, ctA[j].u, ctA[j].c),
                "SDL proof is not valid"
            );
        }
        if (bidCA.length == 0) bidCA.set(ctA);
        else bidCA.set(bidCA.add(ctA));
        bidder.hasSubmitCR = true;
        successCount[3]++;
        if (phase3Success()) timer[3].start = block.timestamp;
    }

    function phase3Success() public view returns (bool) {
        return successCount[3] == bList.length();
    }

    function phase3Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase3(), "Phase 3 completed successfully.");
        require(timer[2].exceeded(), "Phase 3 still have time to complete.");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).hasSubmitCR == false) {
                bList.get(i).malicious = true;
            }
        }
        compensateBidderMalicious();
        auctionAborted = true;
    }

    function isPhase4() internal view returns (bool) {
        return
            isPhase1() == false &&
            isPhase2() == false &&
            isPhase3() == false &&
            phase4Success() == false;
    }

    function phase4M1stPriceDecision(ECPoint memory ux, SameDLProof memory pi)
        public
    {
        require(isPhase4(), "Phase 4 not completed yet.");
        require(timer[3].exceeded() == false, "Phase 4 time's up.");
        Bidder storage bidder = bList.find(msg.sender);
        require(bidder.hasDecCR == false, "bidder has decrypt bidCA.");
        bidCA[jM] = bidCA[jM].decrypt(bidder, ux, pi);

        bidder.hasDecCR = true;
        successCount[4]++;
        if (
            successCount[4] == bList.length() &&
            bidCA[jM].c.isIdentityElement() == false
        ) {
            jM++;
            for (uint256 i = 0; i < bList.length(); i++) {
                bList.get(i).hasDecCR = false;
            }
            successCount[4] = 0;
        }

        if (phase4Success()) timer[4].start = block.timestamp;
    }

    function phase4Success() public view returns (bool) {
        return
            jM < price.length &&
            successCount[4] == bList.length() &&
            bidCA[jM].c.isIdentityElement();
    }

    function phase4Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase4(), "Phase 4 completed successfully.");
        require(timer[3].exceeded(), "Phase 4 still have time to complete.");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).hasDecCR == false) {
                bList.get(i).malicious = true;
            }
        }
        compensateBidderMalicious();
        auctionAborted = true;
    }

    function isPhase5() public view returns (bool) {
        return
            isPhase1() == false &&
            isPhase2() == false &&
            isPhase3() == false &&
            isPhase4() == false &&
            phase5Success() == false;
    }

    function phase5WinnerDecision(CtMProof memory piM) public {
        require(isPhase5(), "Phase 5 not completed yet.");
        require(timer[4].exceeded() == false, "Phase 5 time's up.");
        Bidder storage bidder = bList.find(msg.sender);
        require(bidder.win == false, "Bidder has already declare win.");
        require(piM.valid(pk, bidder.a[jM], 1), "CtMProof not valid.");
        bidder.win = true;
        successCount[5]++;
        if (phase5Success()) timer[5].start = block.timestamp;
    }

    function phase5Success() public view returns (bool) {
        return successCount[5] == M;
    }

    function phase5Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase5(), "Phase 5 completed successfully.");
        require(timer[4].exceeded(), "Phase 5 still have time to complete.");
        require(successCount[5] == 0, "There are still some winners.");
        returnAllStake();
        auctionAborted = true;
    }

    function isPhase6() internal view returns (bool) {
        return
            isPhase1() == false &&
            isPhase2() == false &&
            isPhase3() == false &&
            isPhase4() == false &&
            isPhase5() == false;
    }

    function phase6Payment() public payable {
        require(isPhase6(), "Phase 6 not completed yet.");
        require(timer[5].exceeded() == false, "Phase 6 time's up.");
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
        return isPhase6() && successCount[6] == successCount[5];
    }

    function phase6Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase6(), "Phase 6 completed successfully.");
        require(timer[5].exceeded(), "Phase 6 still have time to complete.");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).win && bList.get(i).payed == false) {
                bList.get(i).malicious = true;
            }
        }
        if (bList.malicious()) compensateBidderMalicious();
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
        require(bList.malicious() == false);
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).stake > 0) {
                payable(bList.get(i).addr).transfer(bList.get(i).stake);
                bList.get(i).stake = 0;
            }
        }
    }

    function compensateBidderMalicious() internal {
        require(bList.malicious(), "Bidders are not malicious.");
        uint256 d = 0;
        uint256 maliciousBidderCount = 0;
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).malicious) {
                d += bList.get(i).stake;
                bList.get(i).stake = 0;
                maliciousBidderCount++;
            }
        }
        d /= bList.length() - maliciousBidderCount;
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).malicious == false)
                payable(bList.get(i).addr).transfer(d);
        }
    }
}
