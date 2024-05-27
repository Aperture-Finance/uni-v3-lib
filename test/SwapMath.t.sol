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
        return SwapMath.computeSwapStep(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, amountRemaining, feePips);
    }

    function computeSwapStepExactIn(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint24 feePips
    ) external pure override returns (uint160, uint256, uint256) {
        return
            SwapMath.computeSwapStepExactIn(
                sqrtRatioCurrentX96,
                sqrtRatioTargetX96,
                liquidity,
                amountRemaining,
                feePips
            );
    }

    function computeSwapStepExactOut(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint24 feePips
    ) external pure override returns (uint160, uint256, uint256) {
        return
            SwapMath.computeSwapStepExactOut(
                sqrtRatioCurrentX96,
                sqrtRatioTargetX96,
                liquidity,
                amountRemaining,
                feePips
            );
    }
}

/// @title Test contract for SwapMath
contract SwapMathTest is BaseTest {
    // Wrapper that exposes the original SwapMath library.
    ISwapMath internal ogWrapper;
    SwapMathWrapper internal wrapper;

    function setUp() public override {
        ogWrapper = ISwapMath(deployCode("out/SwapMathTest.sol/SwapMathTest.json"));
        wrapper = new SwapMathWrapper();
    }

    function testFuzz_getSqrtPriceTarget(
        bool zeroForOne,
        uint160 sqrtPriceNextX96,
        uint160 sqrtPriceLimitX96
    ) external pure {
        assertEq(
            SwapMath.getSqrtPriceTarget(zeroForOne, sqrtPriceNextX96, sqrtPriceLimitX96),
            (zeroForOne ? sqrtPriceNextX96 < sqrtPriceLimitX96 : sqrtPriceNextX96 > sqrtPriceLimitX96)
                ? sqrtPriceLimitX96
                : sqrtPriceNextX96
        );
    }

    function testFuzz_ComputeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    ) external {
        sqrtRatioCurrentX96 = boundUint160(sqrtRatioCurrentX96);
        sqrtRatioTargetX96 = boundUint160(sqrtRatioTargetX96);
        liquidity = uint128(bound(liquidity, 1, type(uint128).max));
        feePips = uint24(bound(feePips, 0, SwapMath.MAX_FEE_PIPS));
        try
            ogWrapper.computeSwapStep(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, amountRemaining, feePips)
        returns (uint160 ogSqrtRatioNextX96, uint256 ogAmountIn, uint256 ogAmountOut, uint256 ogFeeAmount) {
            (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut, uint256 feeAmount) = wrapper
                .computeSwapStep(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, amountRemaining, feePips);
            assertEq(sqrtRatioNextX96, ogSqrtRatioNextX96);
            // The fee amount invariant is forgone but the total amount in and out should be the same.
            assertEq(amountIn + feeAmount, ogAmountIn + ogFeeAmount);
            assertEq(amountOut, ogAmountOut);
        } catch (bytes memory) {
            vm.expectRevert();
            wrapper.computeSwapStep(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, amountRemaining, feePips);
        }
    }

    function testGas_ComputeSwapStep() external view {
        for (uint256 i; i < 100; ++i) {
            wrapper.computeSwapStep(
                pseudoRandomUint160(i),
                pseudoRandomUint160(i ** 2),
                pseudoRandomUint128(i ** 3),
                pseudoRandomInt128(i ** 4),
                uint24(i)
            );
        }
    }

    function testGas_ComputeSwapStep_Og() external view {
        for (uint256 i; i < 100; ++i) {
            ogWrapper.computeSwapStep(
                pseudoRandomUint160(i),
                pseudoRandomUint160(i ** 2),
                pseudoRandomUint128(i ** 3),
                pseudoRandomInt128(i ** 4),
                uint24(i)
            );
        }
    }

    function testFuzz_ComputeSwapStepExactIn(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint24 feePips
    ) external {
        sqrtRatioCurrentX96 = boundUint160(sqrtRatioCurrentX96);
        sqrtRatioTargetX96 = boundUint160(sqrtRatioTargetX96);
        liquidity = uint128(bound(liquidity, 1, type(uint128).max));
        amountRemaining = bound(amountRemaining, 0, (1 << 255) - 1);
        feePips = uint24(bound(feePips, 0, SwapMath.MAX_FEE_PIPS));
        try
            ogWrapper.computeSwapStepExactIn(
                sqrtRatioCurrentX96,
                sqrtRatioTargetX96,
                liquidity,
                amountRemaining,
                feePips
            )
        returns (uint160 ogSqrtRatioNextX96, uint256 ogAmountIn, uint256 ogAmountOut) {
            (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut) = wrapper.computeSwapStepExactIn(
                sqrtRatioCurrentX96,
                sqrtRatioTargetX96,
                liquidity,
                amountRemaining,
                feePips
            );
            assertEq(sqrtRatioNextX96, ogSqrtRatioNextX96, "sqrtRatioNextX96");
            assertEq(amountIn, ogAmountIn, "amountIn");
            assertEq(amountOut, ogAmountOut, "amountOut");
        } catch (bytes memory) {
            vm.expectRevert();
            wrapper.computeSwapStepExactIn(
                sqrtRatioCurrentX96,
                sqrtRatioTargetX96,
                liquidity,
                amountRemaining,
                feePips
            );
        }
    }

    function testGas_ComputeSwapStepExactIn() external view {
        for (uint256 i; i < 100; ++i) {
            wrapper.computeSwapStepExactIn(
                pseudoRandomUint160(i),
                pseudoRandomUint160(i ** 2),
                pseudoRandomUint128(i ** 3),
                pseudoRandom(i ** 4),
                uint24(i)
            );
        }
    }

    function testGas_ComputeSwapStepExactIn_Og() external view {
        for (uint256 i; i < 100; ++i) {
            ogWrapper.computeSwapStepExactIn(
                pseudoRandomUint160(i),
                pseudoRandomUint160(i ** 2),
                pseudoRandomUint128(i ** 3),
                pseudoRandom(i ** 4),
                uint24(i)
            );
        }
    }

    function testFuzz_ComputeSwapStepExactOut(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint24 feePips
    ) external {
        sqrtRatioCurrentX96 = boundUint160(sqrtRatioCurrentX96);
        sqrtRatioTargetX96 = boundUint160(sqrtRatioTargetX96);
        liquidity = uint128(bound(liquidity, 1, type(uint128).max));
        amountRemaining = bound(amountRemaining, 1, (1 << 255) - 1);
        feePips = uint24(bound(feePips, 0, SwapMath.MAX_FEE_PIPS));
        try
            ogWrapper.computeSwapStepExactOut(
                sqrtRatioCurrentX96,
                sqrtRatioTargetX96,
                liquidity,
                amountRemaining,
                feePips
            )
        returns (uint160 ogSqrtRatioNextX96, uint256 ogAmountIn, uint256 ogAmountOut) {
            (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut) = wrapper.computeSwapStepExactOut(
                sqrtRatioCurrentX96,
                sqrtRatioTargetX96,
                liquidity,
                amountRemaining,
                feePips
            );
            assertEq(sqrtRatioNextX96, ogSqrtRatioNextX96, "sqrtRatioNextX96");
            assertEq(amountIn, ogAmountIn, "amountIn");
            assertEq(amountOut, ogAmountOut, "amountOut");
        } catch (bytes memory) {
            vm.expectRevert();
            wrapper.computeSwapStepExactOut(
                sqrtRatioCurrentX96,
                sqrtRatioTargetX96,
                liquidity,
                amountRemaining,
                feePips
            );
        }
    }

    function testGas_ComputeSwapStepExactOut() external view {
        for (uint256 i; i < 100; ++i) {
            wrapper.computeSwapStepExactOut(
                pseudoRandomUint160(i),
                pseudoRandomUint160(i ** 2),
                pseudoRandomUint128(i ** 3),
                pseudoRandom(i ** 4),
                uint24(i)
            );
        }
    }

    function testGas_ComputeSwapStepExactOut_Og() external view {
        for (uint256 i; i < 100; ++i) {
            ogWrapper.computeSwapStepExactOut(
                pseudoRandomUint160(i),
                pseudoRandomUint160(i ** 2),
                pseudoRandomUint128(i ** 3),
                pseudoRandom(i ** 4),
                uint24(i)
            );
        }
    }
}
