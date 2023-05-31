// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILiquidityAmounts} from "src/test/interfaces/ILiquidityAmounts.sol";
import {LiquidityAmounts} from "src/LiquidityAmounts.sol";
import {TickMath} from "src/TickMath.sol";
import "./Base.t.sol";

contract LiquidityAmountsWrapper is ILiquidityAmounts {
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) external pure returns (uint128 liquidity) {
        return
            LiquidityAmounts.getLiquidityForAmount0(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0
            );
    }

    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) external pure returns (uint128 liquidity) {
        return
            LiquidityAmounts.getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount1
            );
    }

    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) external pure returns (uint128 liquidity) {
        return
            LiquidityAmounts.getLiquidityForAmounts(
                sqrtRatioX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0,
                amount1
            );
    }

    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) external pure returns (uint256 amount0) {
        return
            LiquidityAmounts.getAmount0ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
    }

    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) external pure returns (uint256 amount1) {
        return
            LiquidityAmounts.getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
    }

    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) external pure returns (uint256 amount0, uint256 amount1) {
        return
            LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
    }
}

/// @dev Test contract for LiquidityAmounts
contract LiquidityAmountsTest is BaseTest {
    // Wrapper that exposes the original LiquidityMath library.
    ILiquidityAmounts internal ogWrapper =
        ILiquidityAmounts(makeAddr("original"));
    LiquidityAmountsWrapper internal wrapper;

    function setUp() public override {
        wrapper = new LiquidityAmountsWrapper();
        makeOriginalLibrary(address(ogWrapper), "LiquidityAmountsTest");
    }

    function testFuzz_GetLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) public {
        sqrtRatioAX96 = boundUint160(sqrtRatioAX96);
        sqrtRatioBX96 = boundUint160(sqrtRatioBX96);
        try
            ogWrapper.getLiquidityForAmount0(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0
            )
        returns (uint128 liquidity) {
            assertEq(
                liquidity,
                wrapper.getLiquidityForAmount0(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    amount0
                )
            );
        } catch (bytes memory) {
            vm.expectRevert();
            wrapper.getLiquidityForAmount0(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0
            );
        }
    }

    function testFuzz_GetLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) public {
        sqrtRatioAX96 = boundUint160(sqrtRatioAX96);
        sqrtRatioBX96 = boundUint160(sqrtRatioBX96);
        try
            ogWrapper.getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount1
            )
        returns (uint128 liquidity) {
            assertEq(
                liquidity,
                wrapper.getLiquidityForAmount1(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    amount1
                )
            );
        } catch (bytes memory) {
            vm.expectRevert();
            wrapper.getLiquidityForAmount1(
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount1
            );
        }
    }

    function testFuzz_GetLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) public {
        sqrtRatioX96 = boundUint160(sqrtRatioX96);
        sqrtRatioAX96 = boundUint160(sqrtRatioAX96);
        sqrtRatioBX96 = boundUint160(sqrtRatioBX96);
        try
            ogWrapper.getLiquidityForAmounts(
                sqrtRatioX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0,
                amount1
            )
        returns (uint128 liquidity) {
            assertEq(
                liquidity,
                wrapper.getLiquidityForAmounts(
                    sqrtRatioX96,
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    amount0,
                    amount1
                )
            );
        } catch (bytes memory) {
            vm.expectRevert();
            wrapper.getLiquidityForAmounts(
                sqrtRatioX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                amount0,
                amount1
            );
        }
    }

    function testGas_GetLiquidityForAmounts() public view {
        uint160 sqrtRatioAX96 = TickMath.MIN_SQRT_RATIO;
        uint160 sqrtRatioBX96 = TickMath.MAX_SQRT_RATIO;
        for (uint256 i; i < 100; ++i) {
            try
                wrapper.getLiquidityForAmounts(
                    pseudoRandomUint160(i),
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    1 << i,
                    1 << (128 - i)
                )
            {} catch {}
        }
    }

    function testGas_GetLiquidityForAmounts_Og() public view {
        uint160 sqrtRatioAX96 = TickMath.MIN_SQRT_RATIO;
        uint160 sqrtRatioBX96 = TickMath.MAX_SQRT_RATIO;
        for (uint256 i; i < 100; ++i) {
            try
                ogWrapper.getLiquidityForAmounts(
                    pseudoRandomUint160(i),
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    1 << i,
                    1 << (128 - i)
                )
            {} catch {}
        }
    }

    function testFuzz_GetAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) public {
        sqrtRatioAX96 = boundUint160(sqrtRatioAX96);
        sqrtRatioBX96 = boundUint160(sqrtRatioBX96);
        try
            ogWrapper.getAmount0ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            )
        returns (uint256 amount0) {
            assertEq(
                amount0,
                wrapper.getAmount0ForLiquidity(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    liquidity
                )
            );
        } catch (bytes memory) {
            vm.expectRevert();
            wrapper.getAmount0ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        }
    }

    function testFuzz_GetAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) public {
        sqrtRatioAX96 = boundUint160(sqrtRatioAX96);
        sqrtRatioBX96 = boundUint160(sqrtRatioBX96);
        try
            ogWrapper.getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            )
        returns (uint256 amount1) {
            assertEq(
                amount1,
                wrapper.getAmount1ForLiquidity(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    liquidity
                )
            );
        } catch (bytes memory) {
            vm.expectRevert();
            wrapper.getAmount1ForLiquidity(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        }
    }

    function testFuzz_GetAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) public {
        sqrtRatioX96 = boundUint160(sqrtRatioX96);
        sqrtRatioAX96 = boundUint160(sqrtRatioAX96);
        sqrtRatioBX96 = boundUint160(sqrtRatioBX96);
        try
            ogWrapper.getAmountsForLiquidity(
                sqrtRatioX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            )
        returns (uint256 amount0, uint256 amount1) {
            (uint256 _amount0, uint256 _amount1) = wrapper
                .getAmountsForLiquidity(
                    sqrtRatioX96,
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    liquidity
                );
            assertEq(amount0, _amount0);
            assertEq(amount1, _amount1);
        } catch (bytes memory) {
            vm.expectRevert();
            wrapper.getAmountsForLiquidity(
                sqrtRatioX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
        }
    }

    function testGas_GetAmountsForLiquidity() public view {
        uint160 sqrtRatioAX96 = TickMath.MIN_SQRT_RATIO;
        uint160 sqrtRatioBX96 = TickMath.MAX_SQRT_RATIO;
        for (uint256 i; i < 100; ++i) {
            try
                wrapper.getAmountsForLiquidity(
                    pseudoRandomUint160(i),
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    uint128(1 << i)
                )
            {} catch {}
        }
    }

    function testGas_GetAmountsForLiquidity_Og() public view {
        uint160 sqrtRatioAX96 = TickMath.MIN_SQRT_RATIO;
        uint160 sqrtRatioBX96 = TickMath.MAX_SQRT_RATIO;
        for (uint256 i; i < 100; ++i) {
            try
                ogWrapper.getAmountsForLiquidity(
                    pseudoRandomUint160(i),
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    uint128(1 << i)
                )
            {} catch {}
        }
    }
}
