// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

import {BoolLib} from "./lib/BoolLib.sol";
import {ECPointExt, ECPointLib} from "./lib/ECPointLib.sol";
import {Bidder, BidderList, BidderListLib} from "./lib/BidderListLib.sol";
import {Ct, CtLib} from "./lib/CtLib.sol";
import {DLProof, DLProofLib} from "./lib/DLProofLib.sol";
import {SameDLProof, SameDLProofLib} from "./lib/SameDLProofLib.sol";
import {CtSameDLProof, CtSameDLProofLib} from "./lib/CtSameDLProofLib.sol";
import {Bid01Proof, Bid01ProofLib} from "./lib/Bid01ProofLib.sol";
import {Timer, TimerLib} from "./lib/TimerLib.sol";

contract Auction {
    using BoolLib for bool[];
    using ECPointLib for ECPointExt;
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

    address sellerAddr;

    function getElgamalY() public view returns (ECPointExt[] memory) {
        ECPointExt[] memory result = new ECPointExt[](bList.length());
        for (uint256 i = 0; i < bList.length(); i++) {
            result[i] = bList.get(i).elgamalY;
        }
        return result;
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
            ctU[j] = bList.get(index).bid01Proof[j].ctU;
            ctUU[j] = bList.get(index).bid01Proof[j].ctUU;
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
            ctV[j] = bList.get(index).bid01Proof[j].ctV;
            ctVV[j] = bList.get(index).bid01Proof[j].ctVV;
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
            ctA[j] = bList.get(index).bid01Proof[j].ctA;
            ctAA[j] = bList.get(index).bid01Proof[j].ctAA;
        }
        return (ctA, ctAA);
    }

    Ct[] bidC;
    Bid01Proof[] bidC01Proof;
    bool[] hasDecBidC01Proof;

    function getBidC01ProofU() public view returns (Ct[] memory, Ct[] memory) {
        Ct[] memory ctU = new Ct[](bidC01Proof.length);
        Ct[] memory ctUU = new Ct[](bidC01Proof.length);
        for (uint256 j = 0; j < bidC01Proof.length; j++) {
            ctU[j] = bidC01Proof[j].ctU;
            ctUU[j] = bidC01Proof[j].ctUU;
        }
        return (ctU, ctUU);
    }

    function getBidC01ProofJV() public view returns (Ct memory, Ct memory) {
        return (
            bidC01Proof[secondHighestPriceJ].ctV,
            bidC01Proof[secondHighestPriceJ].ctVV
        );
    }

    function getBidA() public view returns (Ct[] memory) {
        Ct[] memory result = new Ct[](bList.length());
        for (uint256 i = 0; i < bList.length(); i++) {
            result[i] = bList.get(i).bidA[secondHighestPriceJ + 1];
        }
        return result;
    }

    uint256 public binarySearchL;
    uint256 public secondHighestPriceJ;
    uint256 public binarySearchR;
    uint256 public winnerI;

    uint256[] price;

    function getPrice() public view returns (uint256[] memory) {
        return price;
    }

    uint256 public bidderBalanceLimit;

    bool public auctionAborted;

    Timer[6] timer;

    function getTimer() public view returns (Timer[6] memory) {
        return timer;
    }

    constructor(
        uint256[] memory _price,
        uint256[6] memory duration,
        uint256 _balanceLimit
    ) {
        sellerAddr = msg.sender;
        require(_price.length != 0, "Price list length must not be 0.");
        price = _price;
        binarySearchR = price.length;
        secondHighestPriceJ = (binarySearchL + binarySearchR) / 2;
        for (uint256 i = 0; i < 6; i++) {
            require(duration[i] > 0, "Timer duration must larger than zero.");
            timer[i].duration = duration[i];
        }
        timer[0].start = block.timestamp;
        timer[1].start = timer[0].start + timer[0].duration;
        bidderBalanceLimit = _balanceLimit;
    }

    function isPhase1() internal view returns (bool) {
        return phase1Success() == false;
    }

    function phase1BidderInit(ECPointExt memory elgamalY, DLProof memory pi)
        public
        payable
    {
        require(isPhase1(), "Phase 0 not completed yet.");
        require(timer[0].timesUp() == false, "Phase 1 time's up.");
        require(elgamalY.isNotSet() == false, "elgamalY must not be zero");
        require(
            pi.valid(ECPointLib.g(), elgamalY),
            "Discrete log proof invalid."
        );
        require(
            msg.value >= bidderBalanceLimit,
            "Bidder's deposit must larger than bidderBalanceLimit."
        );
        bList.init(msg.sender, msg.value, elgamalY);
    }

    function phase1Success() public view returns (bool) {
        return bList.length() > 1 && timer[0].timesUp();
    }

    function phase1Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase1(), "Phase 1 completed successfully.");
        require(timer[0].timesUp(), "Phase 1 still have time to complete.");
        returnAllBalance();
        auctionAborted = true;
    }

    function isPhase2() internal view returns (bool) {
        return isPhase1() == false && phase2Success() == false;
    }

    function phase2BidderSubmitBid(Ct[] memory bid) public {
        require(isPhase2(), "Phase 1 not completed yet.");
        require(timer[1].timesUp() == false, "Phase 2 time's up.");
        Bidder storage bidder = bList.find(msg.sender);
        require(
            bidder.addr != address(0),
            "Bidder can only submit their bids if they join in phase 1."
        );
        require(
            bid.length == price.length,
            "Bid list's length must equals to bid price list's length."
        );
        require(bid.isNotSet() == false, "bid is not set.");
        for (uint256 j = 0; j < bid.length; j++) {
            bidder.bidA.push(bid[j]);
            bidder.bid01Proof.push();
        }
        bidder.bid01Proof.setU(bid);
        bidder.bidSum = bid.sum();
        require(bidder.bidA.length >= 2, "bidder.bidA.length < 2");
        for (uint256 j = bidder.bidA.length - 2; j >= 0; j--) {
            bidder.bidA[j] = bidder.bidA[j].add(bidder.bidA[j + 1]);
            if (j == 0) break; // j is unsigned. it will never be negative
        }
        if (phase2Success()) timer[2].start = block.timestamp;
    }

    function phase2Success() public view returns (bool) {
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).bidA.length != price.length) return false;
        }
        return true;
    }

    function phase2Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase2(), "Phase 2 completed successfully.");
        require(timer[1].timesUp(), "Phase 2 still have time to complete.");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).bidA.length != price.length)
                bList.get(i).malicious = true;
        }
        compensateBidderMalicious();
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
        require(
            ux.length == bList.length() && pi.length == bList.length(),
            "Length of bList, ux, pi must be same."
        );
        Bidder storage bidder = bList.find(msg.sender);
        require(
            bidder.hasDecBidSum == false,
            "BidSum has already been decrypted."
        );
        for (uint256 i = 0; i < bList.length(); i++) {
            bList.get(i).bidSum = bList.get(i).bidSum.decrypt(
                bidder,
                ux[i],
                pi[i]
            );
        }
        bidder.hasDecBidSum = true;
        if (phase3Success()) {
            phase4Prepare();
            timer[3].start = block.timestamp;
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
            ctV.length == bList.length() &&
                ctVV.length == bList.length() &&
                pi.length == bList.length(),
            "Length of bList, ctV, ctVV, pi must be same."
        );
        require(
            msg.sender == bList.get(0).addr,
            "Only B0 can call this function."
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
        require(
            uxV.length == bList.length() &&
                piV.length == bList.length() &&
                uxVV.length == bList.length() &&
                piVV.length == bList.length(),
            "Length of bList, uxV, uxVV, pi must be same."
        );
        Bidder storage bidder = bList.find(msg.sender);
        require(
            bidder.hasDecBid01Proof == false,
            "Bid01Proof has already been decrypted."
        );
        for (uint256 i = 0; i < bList.length(); i++) {
            require(
                bList.get(i).bid01Proof.length > 0,
                "bList.get(i).bid01Proof is empty."
            );
            bList.get(i).bid01Proof.setA(
                bidder,
                uxV[i],
                piV[i],
                uxVV[i],
                piVV[i]
            );
        }
        bidder.hasDecBid01Proof = true;
        if (phase3Success()) {
            phase4Prepare();
            timer[3].start = block.timestamp;
        }
    }

    function phase3Success() public view returns (bool) {
        if (bList.hasDecBidSum() == false) return false;
        if (bList.hasDecBid01Proof() == false) return false;
        for (uint256 i = 0; i < bList.length(); i++) {
            if (
                bList.get(i).bidSum.c.equals(ECPointLib.z()) == false ||
                bList.get(i).bid01Proof.valid() == false
            ) return false;
        }
        return true;
    }

    function phase3Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase3(), "Phase 3 completed successfully.");
        require(timer[2].timesUp(), "Phase 3 still have time to complete.");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).hasDecBidSum == false) {
                bList.get(i).malicious = true;
            }
        }
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).bid01Proof.stageA() == false) {
                bList.get(0).malicious = true;
            }
        }
        if (bList.get(0).malicious == false) {
            for (uint256 i = 0; i < bList.length(); i++) {
                if (bList.get(i).hasDecBid01Proof == false) {
                    bList.get(i).malicious = true;
                }
            }
        }
        if (bList.malicious() == false) {
            for (uint256 i = 0; i < bList.length(); i++) {
                if (bList.get(i).bidSum.c.equals(ECPointLib.z()) == false) {
                    bList.get(i).malicious = true;
                }
                if (bList.get(i).bid01Proof.valid() == false) {
                    bList.get(i).malicious = true;
                }
            }
        }
        compensateBidderMalicious();
        auctionAborted = true;
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
        hasDecBidC01Proof = new bool[](bList.length());
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
            ctV.length == bidC01Proof.length &&
                ctVV.length == bidC01Proof.length &&
                pi.length == bidC01Proof.length,
            "Length of bidC01Proof, ctV, ctVV, pi must be same."
        );
        require(
            msg.sender == bList.get(0).addr,
            "Only B0 can call this function."
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
        Bidder storage bidder = bList.find(msg.sender);
        require(
            hasDecBidC01Proof[bidder.index] == false,
            "bidder has dec BidC01Proof."
        );
        bidC01Proof[secondHighestPriceJ].setA(bidder, uxV, piV, uxVV, piVV);
        hasDecBidC01Proof[bidder.index] = true;

        if (hasDecBidC01Proof.isTrue()) {
            if (bidC01Proof[secondHighestPriceJ].valid()) {
                binarySearchR = secondHighestPriceJ;
            } else {
                binarySearchL = secondHighestPriceJ;
            }
            secondHighestPriceJ = (binarySearchL + binarySearchR) / 2;
            hasDecBidC01Proof = new bool[](bList.length());
        }

        if (phase4Success()) timer[4].start = block.timestamp;
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
            bList.get(0).malicious = true;
        } else {
            for (uint256 i = 0; i < bList.length(); i++) {
                if (hasDecBidC01Proof[i] == false) {
                    bList.get(i).malicious = true;
                }
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

    function phase5WinnerDecision(
        ECPointExt[] memory ux,
        SameDLProof[] memory pi
    ) public {
        require(isPhase5(), "Phase 5 not completed yet.");
        require(timer[4].timesUp() == false, "Phase 5 time's up.");
        require(
            ux.length == bList.length() && pi.length == bList.length(),
            "Length of bList, ux, pi must be same."
        );
        Bidder storage bidder = bList.find(msg.sender);
        require(bidder.hasDecBidA == false, "Bidder has dec bidA");
        for (uint256 i = 0; i < bList.length(); i++) {
            bList.get(i).bidA[secondHighestPriceJ + 1] = bList.get(i).bidA[
                secondHighestPriceJ + 1
            ]
                .decrypt(bidder, ux[i], pi[i]);
        }
        bidder.hasDecBidA = true;
        if (bList.hasDecBidA()) {
            for (uint256 i = 0; i < bList.length(); i++) {
                if (
                    bList.get(i).bidA[secondHighestPriceJ + 1].c.equals(
                        ECPointLib.z()
                    )
                ) {
                    winnerI = i;
                }
            }
        }
        if (phase5Success()) timer[5].start = block.timestamp;
    }

    function phase5Success() public view returns (bool) {
        return bList.hasDecBidA();
    }

    function phase5Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase5(), "Phase 5 completed successfully.");
        require(timer[4].timesUp(), "Phase 5 still have time to complete.");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).hasDecBidA == false) {
                bList.get(i).malicious = true;
            }
        }
        compensateBidderMalicious();
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
            msg.value == price[secondHighestPriceJ],
            "msg.value must equals to the second highest price."
        );
        payable(sellerAddr).transfer(msg.value);
        returnAllBalance();
    }

    function getBalance() public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](bList.length());
        for (uint256 i = 0; i < bList.length(); i++) {
            result[i] = bList.get(i).balance;
        }
        return result;
    }

    function phase6Success() public view returns (bool) {
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
        auctionAborted = true;
    }

    function returnAllBalance() internal {
        require(bList.malicious() == false);
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).balance > 0) {
                payable(bList.get(i).addr).transfer(bList.get(i).balance);
                bList.get(i).balance = 0;
            }
        }
    }

    function compensateBidderMalicious() internal {
        require(bList.malicious(), "Bidders are not malicious.");
        uint256 d = 0;
        uint256 maliciousBidderCount = 0;
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).malicious) {
                d += bList.get(i).balance;
                bList.get(i).balance = 0;
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
