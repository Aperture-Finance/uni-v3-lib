// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@uniswap/v3-core/contracts/libraries/SwapMath.sol";
import "./interfaces/ISwapMath.sol";

/// @dev Expose internal functions to test the SwapMath library.
contract SwapMathTest is ISwapMath {
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    ) external pure override returns (uint160, uint256, uint256, uint256) {
        return
            SwapMath.computeSwapStep(
                sqrtRatioCurrentX96,
                sqrtRatioTargetX96,
                liquidity,
                amountRemaining,
                feePips
            );
    }

    function computeSwapStepExactIn(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint24 feePips
    )
        external
        pure
        override
        returns (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut)
    {
        (sqrtRatioNextX96, amountIn, amountOut, ) = SwapMath.computeSwapStep(
            sqrtRatioCurrentX96,
            sqrtRatioTargetX96,
            liquidity,
            int256(amountRemaining),
            feePips
        );
    }

    function computeSwapStepExactOut(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint24 feePips
    )
        external
        pure
        override
        returns (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut)
    {
        (sqrtRatioNextX96, amountIn, amountOut, ) = SwapMath.computeSwapStep(
            sqrtRatioCurrentX96,
            sqrtRatioTargetX96,
            liquidity,
            -int256(amountRemaining),
            feePips
        );
    }
}
