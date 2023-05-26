// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ISwapMath {
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    )
        external
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        );

    function computeSwapStepExactIn(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint24 feePips
    )
        external
        pure
        returns (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut);

    function computeSwapStepExactOut(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint24 feePips
    )
        external
        pure
        returns (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut);
}
