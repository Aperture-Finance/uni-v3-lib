// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITickMath} from "src/test/interfaces/ITickMath.sol";
import {TickMath} from "src/TickMath.sol";
import "./Base.t.sol";

contract TickMathWrapper is ITickMath {
    function getSqrtRatioAtTick(int24 tick) external pure returns (uint160 sqrtPriceX96) {
        return TickMath.getSqrtRatioAtTick(tick);
    }

    function getTickAtSqrtRatio(uint160 sqrtPriceX96) external pure returns (int24 tick) {
        return TickMath.getTickAtSqrtRatio(sqrtPriceX96);
    }
}

/// @dev Test assembly optimized `TickMath` against the original.
contract TickMathTest is Test {
    // Wrapper that exposes the original LiquidityMath library.
    ITickMath internal ogWrapper;
    TickMathWrapper internal wrapper;

    function setUp() public {
        ogWrapper = ITickMath(deployCode("out/TickMathTest.sol/TickMathTest.json"));
        wrapper = new TickMathWrapper();
    }

    /// @notice Benchmark the gas cost of `getSqrtRatioAtTick`
    function testGas_GetSqrtRatioAtTick() public view {
        for (int24 tick = -50; tick < 50; ) {
            wrapper.getSqrtRatioAtTick(tick++);
        }
    }

    /// @notice Benchmark the gas cost of `getSqrtRatioAtTick` from the original library.
    function testGas_GetSqrtRatioAtTick_Og() public view {
        for (int24 tick = -50; tick < 50; ) {
            ogWrapper.getSqrtRatioAtTick(tick++);
        }
    }

    /// @notice Test the revert reason for out of bounds ticks
    function testRevert_GetSqrtRatioAtTick() public {
        vm.expectRevert(bytes("T"));
        wrapper.getSqrtRatioAtTick(TickMath.MIN_TICK - 1);
        vm.expectRevert(bytes("T"));
        wrapper.getSqrtRatioAtTick(TickMath.MAX_TICK + 1);
    }

    /// @notice Test the equivalence of the original and new `getSqrtRatioAtTick`
    function testFuzz_GetSqrtRatioAtTick(int24 tick) public view {
        tick = int24(bound(tick, TickMath.MIN_TICK, TickMath.MAX_TICK));
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);
        assertEq(tick, TickMath.getTickAtSqrtRatio(sqrtPriceX96));
        assertEq(sqrtPriceX96, ogWrapper.getSqrtRatioAtTick(tick));
    }

    /// @notice Benchmark the gas cost of `getTickAtSqrtRatio`
    /// @dev 'via-ir' should be enabled for proper inlining. Otherwise, gas efficiency is worse than the original.
    function testGas_GetTickAtSqrtRatio() public view {
        uint160 sqrtPriceX96 = 1 << 33;
        for (uint256 i; i++ < 100; sqrtPriceX96 <<= 1) {
            wrapper.getTickAtSqrtRatio(sqrtPriceX96);
        }
    }

    /// @notice Benchmark the gas cost of `getTickAtSqrtRatio` from the original library.
    function testGas_GetTickAtSqrtRatio_Og() public view {
        uint160 sqrtPriceX96 = 1 << 33;
        for (uint256 i; i++ < 100; sqrtPriceX96 <<= 1) {
            ogWrapper.getTickAtSqrtRatio(sqrtPriceX96);
        }
    }

    /// @notice Test the revert reason for out of bounds sqrtPriceX96
    function testRevert_GetTickAtSqrtRatio() public {
        vm.expectRevert(bytes("R"));
        wrapper.getTickAtSqrtRatio(TickMath.MIN_SQRT_RATIO - 1);
        vm.expectRevert(bytes("R"));
        wrapper.getTickAtSqrtRatio(TickMath.MAX_SQRT_RATIO);
    }

    /// @notice Test the equivalence of `getTickAtSqrtRatio` and the original library
    function testFuzz_GetTickAtSqrtRatio(uint160 sqrtPriceX96) public view {
        sqrtPriceX96 = uint160(bound(sqrtPriceX96, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO - 1));
        assertEq(TickMath.getTickAtSqrtRatio(sqrtPriceX96), ogWrapper.getTickAtSqrtRatio(sqrtPriceX96));
    }
}
