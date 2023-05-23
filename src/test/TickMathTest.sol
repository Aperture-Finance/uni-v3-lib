// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "./interfaces/ITickMath.sol";

/// @dev Expose internal functions to test the TickMath library.
contract TickMathTest is ITickMath {
    function getSqrtRatioAtTick(
        int24 tick
    ) external pure override returns (uint160 sqrtPriceX96) {
        return TickMath.getSqrtRatioAtTick(tick);
    }

    function getTickAtSqrtRatio(
        uint160 sqrtPriceX96
    ) external pure override returns (int24 tick) {
        return TickMath.getTickAtSqrtRatio(sqrtPriceX96);
    }
}
