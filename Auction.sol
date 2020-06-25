// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import {BigNumber} from "./lib/BigNumber.sol";
import {BigNumberLib} from "./lib/BigNumberLib.sol";
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

contract Auction {
    using BigNumberLib for BigNumber.instance;
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

    address payable sellerAddr;

    AuctioneerList aList;

    function getElgamalY() public view returns (BigNumber.instance[2] memory) {
        return [aList.get(0).elgamalY, aList.get(1).elgamalY];
    }

    BidderList bList;

    function getBListLength() public view returns (uint256) {
        return bList.length();
    }

    function getBidProd() public view returns (Ct[] memory) {
        Ct[] memory result = new Ct[](bList.length());
        for (uint256 i = 0; i < bList.length(); i++) {
            result[i] = bList.get(i).bidProd;
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

    BigNumber.instance public p;
    BigNumber.instance public q;
    BigNumber.instance public g;
    BigNumber.instance public z;
    BigNumber.instance public zInv;
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

    function hashTest(BigNumber.instance memory a, BigNumber.instance memory b)
        public
        pure
        returns (BigNumber.instance memory)
    {
        bytes32 digest = keccak256(abi.encodePacked(a.val, b.val));
        uint256 bit_length = 0;
        for (uint256 i = 0; i < 256; i++) {
            if (digest >> i > 0) bit_length++;
            else break;
        }
        return BigNumber.instance(abi.encodePacked(digest), false, bit_length);
    }

    constructor(
        address payable[2] memory auctioneer_addr,
        address payable _sellerAddr,
        uint256[] memory _price,
        uint256[6] memory duration,
        uint256[2] memory _balanceLimit
    ) public {
        p = BigNumber.instance(
            hex"e6eae100576ae255abcc28ad5702afdf3713109933cc809d106aa87a26a975914b5d4763bff62b718b122072b50023b3d12be2d90f8203fd30ed2051fa8faa959117097e284cc81e8e0c4c015524ed3eef7bf1feaedaf43ba08ef2f85f930e6851d9f4a7c89192953c6aff6afdb24daf44a39f0e63727c45c72317fe50e61f0f",
            false,
            1024
        );
        q = BigNumber.instance(
            hex"737570802bb5712ad5e61456ab8157ef9b89884c99e6404e8835543d1354bac8a5aea3b1dffb15b8c58910395a8011d9e895f16c87c101fe98769028fd47d54ac88b84bf1426640f47062600aa92769f77bdf8ff576d7a1dd047797c2fc9873428ecfa53e448c94a9e357fb57ed926d7a251cf8731b93e22e3918bff28730f87",
            false,
            1023
        );
        g = BigNumber.instance(
            hex"0000000000000000000000000000000000000000000000000000000000000002",
            false,
            2
        );
        z = BigNumber.instance(
            hex"0000000000000000000000000000000000000000000000000000000000000003",
            false,
            2
        );
        zInv = BigNumber.instance(
            hex"4cf8f5aac7ce4b71e3eeb839c7ab8ff5125bb03311442adf0578e2d362387c85c3c9c27695520e7b2e5b60263c55613bf063f6485a80abff104f0ac5fe2fe387305d032a0d6eed5f84aec40071b6f9bfa52950aa3a48fc13e02fa652ca865a22c5f3518d42db30dc6978ffce5490c48fc18bdfaf767b7ec1ed0bb2aa1af75fb0",
            false,
            2
        );
        assert(z.mul(zInv, p).isOne(p));
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
        require(_sellerAddr != address(0));
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

    function phase1AuctioneerInit(
        BigNumber.instance memory elgamalY,
        DLProof memory pi
    ) public payable {
        require(isPhase1(), "Phase 0 not completed yet.");
        require(timer[0].timesUp() == false, "Phase 1 time's up.");
        Auctioneer storage auctioneer = aList.find(msg.sender);
        require(
            auctioneer.addr != address(0),
            "Only pre-defined addresses can become auctioneer."
        );
        require(elgamalY.isZero(p) == false, "elgamalY must not be zero");
        require(pi.valid(g, elgamalY, p, q), "Discrete log proof invalid.");
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
        return
            aList.get(0).elgamalY.isZero(p) == false &&
            aList.get(1).elgamalY.isZero(p) == false;
    }

    function phase1Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase1(), "Phase 1 completed successfully.");
        require(timer[0].timesUp(), "Phase 1 still have time to complete.");
        if (aList.get(0).elgamalY.isZero(p) == false)
            aList.get(0).malicious = true;
        if (aList.get(1).elgamalY.isZero(p) == false)
            aList.get(1).malicious = true;
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
        require(bid.isNotDec(p), "bid.u1, bid.u2, bid.c must within (0, p)");
        bList.add(msg.sender, msg.value, bid, zInv, p);
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
        BigNumber.instance[] memory ux,
        BigNumber.instance[] memory uxInv,
        SameDLProof[] memory pi
    ) public {
        require(isPhase3(), "Phase 3 not completed yet.");
        require(timer[2].timesUp() == false, "Phase 3 time's up.");
        require(
            ux.length == bList.length() && pi.length == bList.length(),
            "Length of bList, ux, pi must be same."
        );
        Auctioneer storage auctioneer = aList.find(msg.sender);
        for (uint256 i = 0; i < bList.length(); i++) {
            require(
                bList.get(i).bidProd.isNotDec(p) ||
                    bList.get(i).bidProd.isPartialDec(p),
                "Ct has already been decrypted."
            );
            bList.get(i).bidProd = bList.get(i).bidProd.decrypt(
                auctioneer,
                ux[i],
                uxInv[i],
                pi[i],
                g,
                p,
                q
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
            ctV.length == bList.length() &&
                ctVV.length == bList.length() &&
                pi.length == bList.length(),
            "Length of bList, ctV, ctVV, pi must be same."
        );
        require(
            msg.sender == aList.get(1).addr,
            "Only A2 can call this function."
        );
        for (uint256 i = 0; i < bList.length(); i++) {
            bList.get(i).bid01Proof.setV(ctV[i], ctVV[i], pi[i], p, q);
        }
    }

    function phase3BidderVerification01Dec(
        BigNumber.instance[][] memory uxV,
        BigNumber.instance[][] memory uxVInv,
        SameDLProof[][] memory piV,
        BigNumber.instance[][] memory uxVV,
        BigNumber.instance[][] memory uxVVInv,
        SameDLProof[][] memory piVV
    ) public {
        require(isPhase3(), "Phase 3 not completed yet.");
        require(timer[2].timesUp() == false, "Phase 3 time's up.");
        require(
            uxV.length == bList.length() &&
                uxVInv.length == bList.length() &&
                piV.length == bList.length() &&
                uxVV.length == bList.length() &&
                uxVV.length == bList.length() &&
                piVV.length == bList.length(),
            "Length of bList, uxV, uxVV, pi must be same."
        );
        Auctioneer storage auctioneer = aList.find(msg.sender);
        for (uint256 i = 0; i < bList.length(); i++) {
            require(
                bList.get(i).bid01Proof.length > 0,
                "bList.get(i).bid01Proof is empty."
            );
            bList.get(i).bid01Proof.setA(
                auctioneer,
                uxV[i],
                uxVInv[i],
                piV[i],
                g,
                p,
                q
            );
            bList.get(i).bid01Proof.setAA(
                auctioneer,
                uxVV[i],
                uxVVInv[i],
                piVV[i],
                g,
                p,
                q
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
                bList.get(i).bidProd.isFullDec(p) == false ||
                bList.get(i).bidProd.c.equals(z, p) == false ||
                bList.get(i).bid01Proof.length == 0 ||
                (bList.get(i).bid01Proof.length > 0 &&
                    bList.get(i).bid01Proof.valid(p) == false)
            ) return false;
        }
        return true;
    }

    function phase3Resolve() public {
        require(auctionAborted == false, "Problem resolved, auction aborted.");
        require(isPhase3(), "Phase 3 completed successfully.");
        require(timer[2].timesUp(), "Phase 3 still have time to complete.");
        for (uint256 i = 0; i < bList.length(); i++) {
            if (bList.get(i).bidProd.isDecByA(0, p) == false)
                aList.get(0).malicious = true;
            if (bList.get(i).bidProd.isDecByA(1, p) == false)
                aList.get(1).malicious = true;
            if (bList.get(i).bid01Proof.stageA(p) == false)
                aList.get(1).malicious = true;
            else {
                if (bList.get(i).bid01Proof.stageAIsDecByA(0, p) == false)
                    aList.get(0).malicious = true;
                if (bList.get(i).bid01Proof.stageAIsDecByA(1, p) == false)
                    aList.get(1).malicious = true;
            }
            if (aList.get(0).malicious && aList.get(1).malicious) break;
        }
        if (aList.malicious()) {
            compensateAuctioneerMalicious();
            auctionAborted = true;
        } else {
            for (uint256 i = 0; i < bList.length(); i++) {
                assert(bList.get(i).bidProd.isFullDec(p));
                if (bList.get(i).bidProd.c.equals(z, p) == false) {
                    bList.get(i).malicious = true;
                    continue;
                }
                assert(bList.get(i).bid01Proof.stageACompleted(p));
                if (bList.get(i).bid01Proof.valid(p) == false)
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
                ct = ct.mul(bList.get(i).bidA[j], p);
            }
            bidC.push(ct);
            bidC01Proof.push();
        }
        bidC01Proof.setU(bidC, zInv, p);
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
            msg.sender == aList.get(1).addr,
            "Only A2 can call this function."
        );
        bidC01Proof.setV(ctV, ctVV, pi, p, q);
    }

    function phase4SecondHighestBidDecisionDec(
        BigNumber.instance memory uxV,
        BigNumber.instance memory uxVInv,
        SameDLProof memory piV,
        BigNumber.instance memory uxVV,
        BigNumber.instance memory uxVVInv,
        SameDLProof memory piVV
    ) public {
        require(isPhase4(), "Phase 4 not completed yet.");
        require(timer[3].timesUp() == false, "Phase 4 time's up.");
        Auctioneer storage auctioneer = aList.find(msg.sender);
        bidC01Proof[secondHighestBidPriceJ].setA(
            auctioneer,
            uxV,
            uxVInv,
            piV,
            g,
            p,
            q
        );
        bidC01Proof[secondHighestBidPriceJ].setAA(
            auctioneer,
            uxVV,
            uxVVInv,
            piVV,
            g,
            p,
            q
        );

        if (bidC01Proof[secondHighestBidPriceJ].stageACompleted(p)) {
            if (bidC01Proof[secondHighestBidPriceJ].valid(p)) {
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
        if (bidC01Proof.stageA(p) == false) {
            aList.get(1).malicious = true;
        } else {
            if (bidC01Proof.stageAIsDecByA(0, p) == false)
                aList.get(0).malicious = true;
            if (bidC01Proof.stageAIsDecByA(1, p) == false)
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
        BigNumber.instance[] memory ux,
        BigNumber.instance[] memory uxInv,
        SameDLProof[] memory pi
    ) public {
        require(isPhase5(), "Phase 5 not completed yet.");
        require(timer[4].timesUp() == false, "Phase 5 time's up.");
        require(
            ux.length == bList.length() && pi.length == bList.length(),
            "Length of bList, ux, pi must be same."
        );
        Auctioneer storage auctioneer = aList.find(msg.sender);
        for (uint256 i = 0; i < bList.length(); i++) {
            bList.get(i).bidA[secondHighestBidPriceJ + 1] = bList
                .get(i)
                .bidA[secondHighestBidPriceJ + 1]
                .decrypt(auctioneer, ux[i], uxInv[i], pi[i], g, p, q);
            if (
                bList.get(i).bidA[secondHighestBidPriceJ + 1].isFullDec(p) &&
                bList.get(i).bidA[secondHighestBidPriceJ + 1].c.equals(z, p)
            ) {
                winnerI = i;
            }
        }
        if (phase5Success()) timer[5].start = now;
    }

    function phase5Success() public view returns (bool) {
        for (uint256 i = 0; i < bList.length(); i++) {
            if (
                bList.get(i).bidA[secondHighestBidPriceJ + 1].isFullDec(p) &&
                bList.get(i).bidA[secondHighestBidPriceJ + 1].c.isOne(p)
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
                    0,
                    p
                ) == false
            ) aList.get(0).malicious = true;
            if (
                bList.get(winnerI).bidA[secondHighestBidPriceJ + 1].isDecByA(
                    1,
                    p
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
