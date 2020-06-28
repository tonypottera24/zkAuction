// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import {
    Auctioneer,
    AuctioneerList,
    AuctioneerListLib
} from "./lib/AuctioneerListLib.sol";
import {Bidder, BidderList, BidderListLib} from "./lib/BidderListLib.sol";
import {Ct, CtLib} from "./lib/CtLib.sol";
import {DLProof, DLProofLib} from "./lib/DLProofLib.sol";
import {SameDLProof, SameDLProofLib} from "./lib/SameDLProofLib.sol";
import {CtSameDLProof, CtSameDLProofLib} from "./lib/CtSameDLProofLib.sol";
import {Bid01Proof, Bid01ProofLib} from "./lib/Bid01ProofLib.sol";
import {Timer, TimerLib} from "./lib/TimerLib.sol";
import {ECPointExt, ECPointLib} from "./lib/ECPointLib.sol";

contract Auction {
    using AuctioneerListLib for AuctioneerList;
    using BidderListLib for BidderList;
    using CtLib for Ct;
    using CtLib for Ct[];
    using DLProofLib for DLProof;
    using DLProofLib for DLProof[];
    using SameDLProofLib for SameDLProof;
    using SameDLProofLib for SameDLProof[];
    using CtSameDLProofLib for CtSameDLProof;
    using CtSameDLProofLib for CtSameDLProof[];
    using Bid01ProofLib for Bid01Proof;
    using Bid01ProofLib for Bid01Proof[];
    using TimerLib for Timer;
    using ECPointLib for ECPointExt;

    address payable sellerAddr;

    AuctioneerList aList;

    function getElgamalY() public view returns (ECPointExt[2] memory) {
        return [aList.get(0).elgamalY, aList.get(1).elgamalY];
    }

    BidderList bList;

    function getBListLength() public view returns (uint256) {
        return bList.length();
    }

    function getBidSum() public view returns (Ct[] memory) {
        Ct[] memory result = new Ct[](bList.length());
        for (uint256 i = 0; i < bList.length(); i++) {
            result[i] = bList.get(i).bidSum;
        }
        return result;
    }

    function getBidderBid01ProofU(uint256 index)
        public
        view
        returns (Ct[] memory, Ct[] memory)
    {
        Ct[] memory ctU = new Ct[](bList.get(index).bid01Proof.length);
        Ct[] memory ctUU = new Ct[](bList.get(index).bid01Proof.length);
        for (uint256 j = 0; j < bList.get(index).bid01Proof.length; j++) {
            ctU[j] = bList.get(index).bid01Proof[j].u;
            ctUU[j] = bList.get(index).bid01Proof[j].uu;
        }
        return (ctU, ctUU);
    }

    function getBidderBid01ProofV(uint256 index)
        public
        view
        returns (Ct[] memory, Ct[] memory)
    {
        Ct[] memory ctV = new Ct[](bList.get(index).bid01Proof.length);
        Ct[] memory ctVV = new Ct[](bList.get(index).bid01Proof.length);
        for (uint256 j = 0; j < bList.get(index).bid01Proof.length; j++) {
            ctV[j] = bList.get(index).bid01Proof[j].v;
            ctVV[j] = bList.get(index).bid01Proof[j].vv;
        }
        return (ctV, ctVV);
    }

    function getBidderBid01ProofA(uint256 index)
        public
        view
        returns (Ct[] memory, Ct[] memory)
    {
        Ct[] memory ctA = new Ct[](bList.get(index).bid01Proof.length);
        Ct[] memory ctAA = new Ct[](bList.get(index).bid01Proof.length);
        for (uint256 j = 0; j < bList.get(index).bid01Proof.length; j++) {
            ctA[j] = bList.get(index).bid01Proof[j].a;
            ctAA[j] = bList.get(index).bid01Proof[j].aa;
        }
        return (ctA, ctAA);
    }

    Ct[] bidC;
    Bid01Proof[] bidC01Proof;

    function getBidC01ProofU() public view returns (Ct[] memory, Ct[] memory) {
        Ct[] memory ctU = new Ct[](bidC01Proof.length);
        Ct[] memory ctUU = new Ct[](bidC01Proof.length);
        for (uint256 j = 0; j < bidC01Proof.length; j++) {
            ctU[j] = bidC01Proof[j].u;
            ctUU[j] = bidC01Proof[j].uu;
        }
        return (ctU, ctUU);
    }

    function getBidC01ProofJV() public view returns (Ct memory, Ct memory) {
        return (
            bidC01Proof[secondHighestBidPriceJ].v,
            bidC01Proof[secondHighestBidPriceJ].vv
        );
    }

    function getBidA() public view returns (Ct[] memory) {
        Ct[] memory result = new Ct[](bList.length());
        for (uint256 i = 0; i < bList.length(); i++) {
            result[i] = bList.get(i).bidA[secondHighestBidPriceJ + 1];
        }
        return result;
    }

    uint256 public binarySearchL;
    uint256 public secondHighestBidPriceJ;
    uint256 public binarySearchR;
    uint256 public winnerI;

    uint256[] price;

    function getPrice() public view returns (uint256[] memory) {
        return price;
    }

    uint256 public auctioneerBalanceLimit;
    uint256 public bidderBalanceLimit;

    bool public auctionAborted;

    Timer[6] timer;

    function getTimer() public view returns (Timer[6] memory) {
        return timer;
    }

    // function hashTest(ECPointExt memory a, ECPointExt memory b)
    //     public
    //     pure
    //     returns (ECPointExt memory)
    // {
    //     bytes32 digest = keccak256(abi.encodePacked(a.val, b.val));
    //     uint256 bit_length = 0;
    //     for (uint256 i = 0; i < 256; i++) {
    //         if (digest >> i > 0) bit_length++;
    //         else break;
    //     }
    //     return ECPointExt(abi.encodePacked(digest), false, bit_length);
    // }

    constructor(
        address payable[2] memory auctioneer_addr,
        address payable _sellerAddr,
        uint256[] memory _price,
        uint256[6] memory duration,
        uint256[2] memory _balanceLimit
    ) public {
        require(
            auctioneer_addr[0] != auctioneer_addr[1],
            "Auctioneer address must be same."
        );
        for (uint256 i = 0; i < 2; i++) {
            require(
                auctioneer_addr[i] != address(0),
                "Auctioneer address must not be zero."
            );
            aList.add(auctioneer_addr[i]);
        }
        require(_sellerAddr != address(0), "seller address == 0");
        sellerAddr = _sellerAddr;
        require(_price.length != 0, "Price list length must not be 0.");
        price = _price;
        binarySearchR = price.length;
        secondHighestBidPriceJ = (binarySearchL + binarySearchR) / 2;
        for (uint256 i = 0; i < 6; i++) {
            require(duration[i] > 0, "Timer duration must larger than zero.");
            timer[i].duration = duration[i];
        }
        timer[0].start = now;
        auctioneerBalanceLimit = _balanceLimit[0];
        bidderBalanceLimit = _balanceLimit[1];
    }

    function isPhase1() internal view returns (bool) {
        return phase1Success() == false;
    }

    function phase1AuctioneerInit(ECPointExt memory elgamalY, DLProof memory pi)
        public
        payable
    {
        require(isPhase1(), "Phase 0 not completed yet.");
        require(timer[0].timesUp() == false, "Phase 1 time's up.");
        Auctioneer storage auctioneer = aList.find(msg.sender);
        require(
            auctioneer.addr != address(0),
            "Only pre-defined addresses can become auctioneer."
        );
        require(elgamalY.isSet(), "elgamalY must not be zero");
        require(
            pi.valid(ECPointLib.g(), elgamalY),
            "Discrete log proof invalid."
        );
        require(
            msg.value >= auctioneerBalanceLimit,
            "Auctioneer's deposit must larger than auctioneerBalanceLimit."
        );
        auctioneer.elgamalY = elgamalY;
        auctioneer.balance = msg.value;
        if (phase1Success()) {
            timer[1].start = now;
            timer[2].start = timer[1].start + timer[1].duration;
        }
    }

    function phase1Success() public view returns (bool) {
        return aList.get(0).elgamalY.isSet() && aList.get(1).elgamalY.isSet();
    }

    function phase1Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase1(), "Phase 1 completed successfully.");
        require(timer[0].timesUp(), "Phase 1 still have time to complete.");
        if (aList.get(0).elgamalY.isNotSet()) aList.get(0).malicious = true;
        if (aList.get(1).elgamalY.isNotSet()) aList.get(1).malicious = true;
        compensateAuctioneerMalicious();
        auctionAborted = true;
    }

    function isPhase2() internal view returns (bool) {
        return isPhase1() == false && phase2Success() == false;
    }

    function phase2BidderJoin(Ct[] memory bid) public payable {
        require(isPhase2(), "Phase 1 not completed yet.");
        require(timer[1].timesUp() == false, "Phase 2 time's up.");
        require(
            msg.value >= bidderBalanceLimit,
            "Bidder's deposit must larger than bidderBalanceLimit."
        );
        require(
            bid.length == price.length,
            "Bid list's length must equals to bid price list's length."
        );
        require(bid.isNotDec(), "bid.u1, bid.u2, bid.c must within (0, p)");
        bList.add(msg.sender, msg.value, bid);
    }

    function phase2Success() public view returns (bool) {
        return bList.length() > 1 && timer[1].timesUp();
    }

    function phase2Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase2(), "Phase 2 completed successfully.");
        require(timer[1].timesUp(), "Phase 2 still have time to complete.");
        returnAllBalance();
        auctionAborted = true;
    }

    function isPhase3() internal view returns (bool) {
        return
            isPhase1() == false &&
            isPhase2() == false &&
            phase3Success() == false;
    }

    function phase3BidderVerificationSum1(
        ECPointExt[] memory ux,
        SameDLProof[] memory pi
    ) public {
        require(isPhase3(), "Phase 3 not completed yet.");
        require(timer[2].timesUp() == false, "Phase 3 time's up.");
        Auctioneer storage auctioneer = aList.find(msg.sender);
        for (uint256 i = 0; i < bList.length(); i++) {
            require(
                bList.get(i).bidSum.isNotDec() ||
                    bList.get(i).bidSum.isPartialDec(),
                "Ct has already been decrypted."
            );
            bList.get(i).bidSum = bList.get(i).bidSum.decrypt(
                auctioneer,
                ux[i],
                pi[i]
            );
        }
        if (phase3Success()) {
            phase4Prepare();
            timer[3].start = now;
        }
    }

    function phase3BidderVerification01Omega(
        Ct[][] memory ctV,
        Ct[][] memory ctVV,
        CtSameDLProof[][] memory pi
    ) public {
        require(isPhase3(), "Phase 3 not completed yet.");
        require(timer[2].timesUp() == false, "Phase 3 time's up.");
        require(
            msg.sender == aList.get(1).addr,
            "Only A2 can call this function."
        );
        for (uint256 i = 0; i < bList.length(); i++) {
            bList.get(i).bid01Proof.setV(ctV[i], ctVV[i], pi[i]);
        }
    }

    function phase3BidderVerification01Dec(
        ECPointExt[][] memory uxV,
        SameDLProof[][] memory piV,
        ECPointExt[][] memory uxVV,
        SameDLProof[][] memory piVV
    ) public {
        require(isPhase3(), "Phase 3 not completed yet.");
        require(timer[2].timesUp() == false, "Phase 3 time's up.");
        Auctioneer storage auctioneer = aList.find(msg.sender);
        for (uint256 i = 0; i < bList.length(); i++) {
            require(
                bList.get(i).bid01Proof.length > 0,
                "bList.get(i).bid01Proof is empty."
            );
            bList.get(i).bid01Proof.setA(
                auctioneer,
                uxV[i],
                piV[i],
                uxVV[i],
                piVV[i]
            );
        }
        if (phase3Success()) {
            phase4Prepare();
            timer[3].start = now;
        }
    }

    function phase3Success() public view returns (bool) {
        for (uint256 i = 0; i < bList.length(); i++) {
            if (
                bList.get(i).bidSum.isFullDec() == false ||
                bList.get(i).bidSum.c.equals(ECPointLib.z()) == false ||
                bList.get(i).bid01Proof.length == 0 ||
                (bList.get(i).bid01Proof.length > 0 &&
                    bList.get(i).bid01Proof.valid() == false)
            ) return false;
        }
        return true;
    }

    function phase3Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase3(), "Phase 3 completed successfully.");
        require(timer[2].timesUp(), "Phase 3 still have time to complete.");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).bidSum.isDecByA(0) == false)
                aList.get(0).malicious = true;
            if (bList.get(i).bidSum.isDecByA(1) == false)
                aList.get(1).malicious = true;
            if (bList.get(i).bid01Proof.stageA() == false)
                aList.get(1).malicious = true;
            else {
                if (bList.get(i).bid01Proof.stageAIsDecByA(0) == false)
                    aList.get(0).malicious = true;
                if (bList.get(i).bid01Proof.stageAIsDecByA(1) == false)
                    aList.get(1).malicious = true;
            }
            if (aList.get(0).malicious && aList.get(1).malicious) break;
        }
        if (aList.malicious()) {
            compensateAuctioneerMalicious();
            auctionAborted = true;
        } else {
            for (uint256 i = 0; i < bList.length(); i++) {
                assert(bList.get(i).bidSum.isFullDec());
                if (bList.get(i).bidSum.c.equals(ECPointLib.z()) == false) {
                    bList.get(i).malicious = true;
                    continue;
                }
                assert(bList.get(i).bid01Proof.stageACompleted());
                if (bList.get(i).bid01Proof.valid() == false)
                    bList.get(i).malicious = true;
            }
            if (bList.malicious()) {
                compensateBidderMalicious();
                bList.removeMalicious();
            }
            if (bList.length() > 0) {
                phase4Prepare();
                timer[3].start = now;
            } else {
                returnAllBalance();
                auctionAborted = true;
            }
        }
    }

    function phase4Prepare() internal {
        require(isPhase4(), "Phase 4 not completed yet.");
        for (uint256 j = 0; j < price.length; j++) {
            Ct memory ct = bList.get(0).bidA[j];
            for (uint256 i = 1; i < bList.length(); i++) {
                ct = ct.add(bList.get(i).bidA[j]);
            }
            bidC.push(ct);
            bidC01Proof.push();
        }
        bidC01Proof.setU(bidC);
    }

    function isPhase4() internal view returns (bool) {
        return
            isPhase1() == false &&
            isPhase2() == false &&
            isPhase3() == false &&
            phase4Success() == false;
    }

    function phase4SecondHighestBidDecisionOmega(
        Ct[] memory ctV,
        Ct[] memory ctVV,
        CtSameDLProof[] memory pi
    ) public {
        require(isPhase4(), "Phase 4 not completed yet.");
        require(timer[3].timesUp() == false, "Phase 4 time's up.");
        require(
            msg.sender == aList.get(1).addr,
            "Only A2 can call this function."
        );
        bidC01Proof.setV(ctV, ctVV, pi);
    }

    function phase4SecondHighestBidDecisionDec(
        ECPointExt memory uxV,
        SameDLProof memory piV,
        ECPointExt memory uxVV,
        SameDLProof memory piVV
    ) public {
        require(isPhase4(), "Phase 4 not completed yet.");
        require(timer[3].timesUp() == false, "Phase 4 time's up.");
        Auctioneer storage auctioneer = aList.find(msg.sender);
        bidC01Proof[secondHighestBidPriceJ].setA(
            auctioneer,
            uxV,
            piV,
            uxVV,
            piVV
        );

        if (bidC01Proof[secondHighestBidPriceJ].stageACompleted()) {
            if (bidC01Proof[secondHighestBidPriceJ].valid()) {
                binarySearchR = secondHighestBidPriceJ;
            } else {
                binarySearchL = secondHighestBidPriceJ;
            }
            secondHighestBidPriceJ = (binarySearchL + binarySearchR) / 2;
        }
        if (phase4Success()) timer[4].start = now;
    }

    function phase4Success() public view returns (bool) {
        if (binarySearchL == price.length - 1) return false;
        return binarySearchL + 1 == binarySearchR;
    }

    function phase4Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase4(), "Phase 4 completed successfully.");
        require(timer[3].timesUp(), "Phase 4 still have time to complete.");
        if (bidC01Proof.stageA() == false) {
            aList.get(1).malicious = true;
        } else {
            if (bidC01Proof.stageAIsDecByA(0) == false)
                aList.get(0).malicious = true;
            if (bidC01Proof.stageAIsDecByA(1) == false)
                aList.get(1).malicious = true;
        }
        compensateAuctioneerMalicious();
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

    function phase5WinnerDecision(
        ECPointExt[] memory ux,
        SameDLProof[] memory pi
    ) public {
        require(isPhase5(), "Phase 5 not completed yet.");
        require(timer[4].timesUp() == false, "Phase 5 time's up.");
        Auctioneer storage auctioneer = aList.find(msg.sender);
        for (uint256 i = 0; i < bList.length(); i++) {
            bList.get(i).bidA[secondHighestBidPriceJ + 1] = bList
                .get(i)
                .bidA[secondHighestBidPriceJ + 1]
                .decrypt(auctioneer, ux[i], pi[i]);
            if (
                bList.get(i).bidA[secondHighestBidPriceJ + 1].isFullDec() &&
                bList.get(i).bidA[secondHighestBidPriceJ + 1].c.equals(
                    ECPointLib.z()
                )
            ) {
                winnerI = i;
            }
        }
        if (phase5Success()) timer[5].start = now;
    }

    function phase5Success() public view returns (bool) {
        for (uint256 i = 0; i < bList.length(); i++) {
            if (
                bList.get(i).bidA[secondHighestBidPriceJ + 1].isFullDec() &&
                bList.get(i).bidA[secondHighestBidPriceJ + 1].c.equals(
                    ECPointLib.z()
                )
            ) {
                return true;
            }
        }
        return false;
    }

    function phase5Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase5(), "Phase 5 completed successfully.");
        require(timer[4].timesUp(), "Phase 5 still have time to complete.");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (
                bList.get(winnerI).bidA[secondHighestBidPriceJ + 1].isDecByA(
                    0
                ) == false
            ) aList.get(0).malicious = true;
            if (
                bList.get(winnerI).bidA[secondHighestBidPriceJ + 1].isDecByA(
                    1
                ) == false
            ) aList.get(1).malicious = true;
            if (aList.get(0).malicious && aList.get(1).malicious) break;
        }
        compensateAuctioneerMalicious();
        auctionAborted = true;
    }

    function isPhase6() internal view returns (bool) {
        return
            isPhase1() == false &&
            isPhase2() == false &&
            isPhase3() == false &&
            isPhase4() == false &&
            isPhase5() == false &&
            phase6Success() == false;
    }

    function phase6Payment() public payable {
        require(isPhase6(), "Phase 6 not completed yet.");
        require(timer[5].timesUp() == false, "Phase 6 time's up.");
        require(
            msg.sender == bList.get(winnerI).addr,
            "Only winner needs to pay."
        );
        require(
            msg.value == price[secondHighestBidPriceJ],
            "msg.value must equals to the second highest price."
        );
        sellerAddr.transfer(msg.value);
        returnAllBalance();
    }

    function getBalance() public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](
            aList.length() + bList.length()
        );
        for (uint256 i = 0; i < aList.length(); i++) {
            result[i] = aList.get(i).balance;
        }
        for (uint256 i = 0; i < bList.length(); i++) {
            result[i + aList.length()] = bList.get(i).balance;
        }
        return result;
    }

    function phase6Success() public view returns (bool) {
        for (uint256 i = 0; i < aList.length(); i++) {
            if (aList.get(i).balance > 0) return false;
        }
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).balance > 0) return false;
        }
        return true;
    }

    function phase6Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase6(), "Phase 6 completed successfully.");
        require(timer[5].timesUp(), "Phase 6 still have time to complete.");
        bList.get(winnerI).malicious = true;
        compensateBidderMalicious();
        bList.removeMalicious();
        returnAllBalance();
        auctionAborted = true;
    }

    function returnAllBalance() internal {
        require(aList.malicious() == false && bList.malicious() == false);
        for (uint256 i = 0; i < aList.length(); i++) {
            if (aList.get(i).balance > 0) {
                aList.get(i).addr.transfer(aList.get(i).balance);
                aList.get(i).balance = 0;
            }
        }
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).balance > 0) {
                bList.get(i).addr.transfer(bList.get(i).balance);
                bList.get(i).balance = 0;
            }
        }
    }

    function compensateAuctioneerMalicious() internal {
        require(aList.malicious(), "Auctioneers are not malicious.");
        uint256 d;
        for (uint256 i = 0; i < aList.length(); i++) {
            if (aList.get(i).malicious) {
                d += aList.get(i).balance;
                aList.get(i).balance = 0;
            }
        }
        if (aList.get(0).malicious && aList.get(1).malicious)
            d /= bList.length();
        else d /= 1 + bList.length();
        for (uint256 i = 0; i < aList.length(); i++) {
            if (aList.get(i).malicious == false) {
                aList.get(i).addr.transfer(d + aList.get(i).balance);
                aList.get(i).balance = 0;
            }
        }
        for (uint256 i = 0; i < bList.length(); i++) {
            bList.get(i).addr.transfer(d + bList.get(i).balance);
            bList.get(i).balance = 0;
        }
    }

    function compensateBidderMalicious() internal {
        require(bList.malicious(), "Bidders are not malicious.");
        uint256 d;
        uint256 maliciousBidderCount;
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).malicious) {
                d += bList.get(i).balance;
                bList.get(i).balance = 0;
                maliciousBidderCount++;
            }
        }
        d /= aList.length() + bList.length() - maliciousBidderCount;
        aList.get(0).addr.transfer(d);
        aList.get(1).addr.transfer(d);
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).malicious == false) bList.get(i).addr.transfer(d);
        }
    }
}
