// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IBitMath {
    function mostSignificantBit(uint256 x) external pure returns (uint8 r);

    function leastSignificantBit(uint256 x) external pure returns (uint8 r);
}
