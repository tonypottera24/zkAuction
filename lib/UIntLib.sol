// // SPDX-License-Identifier: MIT
// pragma solidity >=0.4.22 <0.7.0;
// pragma experimental ABIEncoderV2;

// library UIntLib {
//     modifier safeP(uint p) {
//         require(p > 1, "p is a prime, p should larger than 1.");
//         _;
//     }

//     modifier safeAArray(uint[] memory a) {
//         require(a.length > 0, "a must within [1, p).");
//         _;
//     }

//     function safe(uint a, uint p) internal pure safeP(p) returns (bool) {
//         return 0 < a && a < p;
//     }

//     function safe(uint[] memory a, uint p) internal pure safeAArray(a) returns (bool) {
//         for (uint i = 0 ; i < a.length ; i++) {
//             if (safe(a[i], p) == false) return false;
//         }
//         return true;
//     }

//     function mul(uint a, uint b, uint p) internal pure safeP(p) returns (uint) {
//         require(safe(a, p), "a must within [1, p).");
//         require(safe(b, p), "b must within [1, p).");
//         return mulmod(a, b, p);
//     }

//     function inv(uint a, uint p) internal pure safeP(p) returns (uint) {
//         require(safe(a, p), "a must within [1, p).");
//         uint a0 = a;
//         uint a1 = p;
//         uint q;
//         uint x0 = 1;
//         uint x1 = 0;
//         uint y0 = 0;
//         uint y1 = 1;
//         for (; a1 != 0 ;) {
//             (q, a0, a1) = (a0 / a1, a1, a0 % a1);
//             (x0, x1) = (x1, x0 - q * x1);
//             (y0, y1) = (y1, y0 - q * y1);
//         }
//         assert(safe(x0, p));
//         assert(mul(a, x0, p) == 1);
//         return x0;
//     }

//     function pow(uint a, uint k, uint p) internal pure safeP(p) returns (uint) {
//         require(safe(a, p), "a must within [1, p).");
//         require(safe(k, p), "k must within [1, p).");
//         uint result = 1;
//         for (uint c = 1; c <= k; c *= 2) {
//             if (k & c != 0) result = mul(result, a, p);
//             a = mul(a, a, p);
//         }
//         assert(safe(result, p));
//         return result;
//     }
// }

