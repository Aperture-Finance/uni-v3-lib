// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@uniswap/v3-core/contracts/libraries/BitMath.sol";
import "./interfaces/IBitMath.sol";

/// @dev Expose internal functions to test the BitMath library.
contract BitMathTest is IBitMath {
    function mostSignificantBit(
        uint256 x
    ) external pure override returns (uint8 r) {
        return BitMath.mostSignificantBit(x);
    }

    function leastSignificantBit(
        uint256 x
    ) external pure override returns (uint8 r) {
        return BitMath.leastSignificantBit(x);
    }
}
