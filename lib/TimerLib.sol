// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;
pragma experimental ABIEncoderV2;

struct Timer {
    uint256 start;
    uint256 duration;
}

library TimerLib {
    function timesUp(Timer storage t) internal view returns (bool) {
        if (t.start == 0) return false;
        return block.timestamp > t.start + t.duration;
    }
}
