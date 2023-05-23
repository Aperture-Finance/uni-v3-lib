// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@uniswap/v3-core/contracts/libraries/LiquidityMath.sol";
import "./interfaces/ILiquidityMath.sol";

/// @dev Expose internal functions to test the LiquidityMath library.
contract LiquidityMathTest is ILiquidityMath {
    function addDelta(
        uint128 x,
        int128 y
    ) external pure override returns (uint128 z) {
        return LiquidityMath.addDelta(x, y);
    }
}
