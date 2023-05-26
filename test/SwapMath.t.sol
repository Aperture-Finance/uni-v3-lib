// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISwapMath} from "src/test/interfaces/ISwapMath.sol";
import {SwapMath} from "src/SwapMath.sol";
import "./Base.t.sol";

contract SwapMathWrapper is ISwapMath {
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
        uint256 feePips
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
            uint24(feePips)
        );
    }
}

/// @title Test contract for SwapMath
contract SwapMathTest is BaseTest {
    // Wrapper that exposes the original SwapMath library.
    ISwapMath internal ogWrapper = ISwapMath(makeAddr("wrapper"));
    SwapMathWrapper internal wrapper;

    function setUp() public override {
        wrapper = new SwapMathWrapper();
        makeOriginalLibrary(address(ogWrapper), "SwapMathTest");
    }
}
