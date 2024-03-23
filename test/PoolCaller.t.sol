// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pancakeswap/v3-core/contracts/interfaces/IPancakeV3Pool.sol";
import "src/PoolCaller.sol";
import "./Base.t.sol";

/// @dev Expose internal functions to test the PoolCaller library.
contract PoolCallerWrapper {
    V3PoolCallee internal immutable pool;

    constructor(address _pool) {
        pool = V3PoolCallee.wrap(_pool);
    }

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes memory data
    ) external returns (int256, int256) {
        return pool.swap(recipient, zeroForOne, amountSpecified, sqrtPriceLimitX96, data);
    }
}

/// @dev Test the PoolCaller library.
contract PoolCallerTest is BaseTest {
    using SafeTransferLib for address;

    PoolCallerWrapper internal poolCaller;
    V3PoolCallee internal poolCallee;

    function setUp() public virtual override {
        createFork();
        poolCaller = new PoolCallerWrapper(pool);
        poolCallee = V3PoolCallee.wrap(pool);
    }

    /// @dev Prepare amount to swap
    function prepSwap(bool zeroForOne, uint256 amountSpecified) internal returns (uint256) {
        if (zeroForOne) {
            amountSpecified = bound(amountSpecified, 1, IERC20(token0).balanceOf(pool) / 10);
            deal(token0, address(this), amountSpecified);
        } else {
            amountSpecified = bound(amountSpecified, 1, IERC20(token1).balanceOf(pool) / 10);
            deal(token1, address(this), amountSpecified);
        }
        return amountSpecified;
    }

    /// @dev Pay pool to finish swap
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        if (amount0Delta > 0) token0.safeTransfer(pool, uint256(amount0Delta));
        if (amount1Delta > 0) token1.safeTransfer(pool, uint256(amount1Delta));
    }

    /// @dev Ensure that the swap is successful
    function assertSwapSuccess(bool zeroForOne, uint256 amountOut) internal view {
        (address tokenIn, address tokenOut) = zeroForOne ? (token0, token1) : (token1, token0);
        assertEq(IERC20(tokenIn).balanceOf(address(this)), 0, "amountIn not exhausted");
        assertEq(IERC20(tokenOut).balanceOf(address(this)), amountOut, "amountOut mismatch");
    }

    function test_Fee() public view {
        assertEq(IUniswapV3Pool(pool).fee(), poolCallee.fee(), "fee");
    }

    function test_TickSpacing() public view {
        assertEq(IUniswapV3Pool(pool).tickSpacing(), poolCallee.tickSpacing(), "tickSpacing");
    }

    function test_Slot0() public virtual {
        (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        ) = IUniswapV3Pool(pool).slot0();
        (
            uint160 sqrtPriceX96Asm,
            int24 tickAsm,
            uint16 observationIndexAsm,
            uint16 observationCardinalityAsm,
            uint16 observationCardinalityNextAsm,
            uint8 feeProtocolAsm,
            bool unlockedAsm
        ) = poolCallee.slot0();
        assertEq(sqrtPriceX96, sqrtPriceX96Asm, "sqrtPriceX96");
        assertEq(tick, tickAsm, "tick");
        assertEq(observationIndex, observationIndexAsm, "observationIndex");
        assertEq(observationCardinality, observationCardinalityAsm, "observationCardinality");
        assertEq(observationCardinalityNext, observationCardinalityNextAsm, "observationCardinalityNext");
        assertEq(feeProtocol, feeProtocolAsm, "feeProtocol");
        assertEq(unlocked, unlockedAsm, "unlocked");
    }

    function test_SqrtPriceX96AndTick() public virtual {
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = IUniswapV3Pool(pool).slot0();
        (uint160 sqrtPriceX96Asm, int24 tickAsm) = V3PoolCallee.wrap(pool).sqrtPriceX96AndTick();
        assertEq(sqrtPriceX96, sqrtPriceX96Asm, "sqrtPriceX96");
        assertEq(tick, tickAsm, "tick");
    }

    function test_FeeGrowthGlobal0X128() public view {
        assertEq(
            IUniswapV3Pool(pool).feeGrowthGlobal0X128(),
            poolCallee.feeGrowthGlobal0X128(),
            "feeGrowthGlobal0X128"
        );
    }

    function test_FeeGrowthGlobal1X128() public view {
        assertEq(
            IUniswapV3Pool(pool).feeGrowthGlobal1X128(),
            poolCallee.feeGrowthGlobal1X128(),
            "feeGrowthGlobal1X128"
        );
    }

    function test_ProtocolFees() public view {
        (uint128 token0Fee, uint128 token1Fee) = IUniswapV3Pool(pool).protocolFees();
        (uint128 token0FeeAsm, uint128 token1FeeAsm) = poolCallee.protocolFees();
        assertEq(token0Fee, token0FeeAsm, "token0Fee");
        assertEq(token1Fee, token1FeeAsm, "token1Fee");
    }

    function test_Liquidity() public view {
        assertEq(IUniswapV3Pool(pool).liquidity(), poolCallee.liquidity(), "liquidity");
    }

    /// forge-config: default.fuzz.runs = 16
    /// forge-config: ci.fuzz.runs = 16
    function testFuzz_Ticks(int24 tick) public virtual {
        (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        ) = IUniswapV3Pool(pool).ticks(tick);
        PoolCaller.TickInfo memory info = poolCallee.ticks(tick);
        assertEq(liquidityGross, info.liquidityGross, "liquidityGross");
        assertEq(liquidityNet, info.liquidityNet, "liquidityNet");
        assertEq(feeGrowthOutside0X128, info.feeGrowthOutside0X128, "feeGrowthOutside0X128");
        assertEq(feeGrowthOutside1X128, info.feeGrowthOutside1X128, "feeGrowthOutside1X128");
        assertEq(tickCumulativeOutside, info.tickCumulativeOutside, "tickCumulativeOutside");
        assertEq(secondsPerLiquidityOutsideX128, info.secondsPerLiquidityOutsideX128, "secondsPerLiquidityOutsideX128");
        assertEq(secondsOutside, info.secondsOutside, "secondsOutside");
        assertEq(initialized, info.initialized, "initialized");
    }

    function test_LiquidityNet() public {
        testFuzz_LiquidityNet(currentTick());
    }

    /// forge-config: default.fuzz.runs = 16
    /// forge-config: ci.fuzz.runs = 16
    function testFuzz_LiquidityNet(int24 tick) public virtual {
        (, int128 liquidityNet, , , , , , ) = IUniswapV3Pool(pool).ticks(tick);
        int128 liquidityNetAsm = poolCallee.liquidityNet(tick);
        assertEq(liquidityNet, liquidityNetAsm, "liquidityNet");
    }

    /// forge-config: default.fuzz.runs = 16
    /// forge-config: ci.fuzz.runs = 16
    function testFuzz_TickBitmap(int16 wordPos) public virtual {
        assertEq(IUniswapV3Pool(pool).tickBitmap(wordPos), poolCallee.tickBitmap(wordPos), "tickBitmap");
    }

    /// forge-config: default.fuzz.runs = 16
    /// forge-config: ci.fuzz.runs = 16
    function testFuzz_Positions(bytes32 key) public virtual {
        (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        ) = IUniswapV3Pool(pool).positions(key);
        PoolCaller.PositionInfo memory info = poolCallee.positions(key);
        assertEq(_liquidity, info.liquidity, "liquidity");
        assertEq(feeGrowthInside0LastX128, info.feeGrowthInside0LastX128, "feeGrowthInside0LastX128");
        assertEq(feeGrowthInside1LastX128, info.feeGrowthInside1LastX128, "feeGrowthInside1LastX128");
        assertEq(tokensOwed0, info.tokensOwed0, "tokensOwed0");
        assertEq(tokensOwed1, info.tokensOwed1, "tokensOwed1");
    }

    /// forge-config: default.fuzz.runs = 16
    /// forge-config: ci.fuzz.runs = 16
    function testFuzz_Observations(uint256 index) public virtual {
        (, , uint16 observationIndex, , , , ) = poolCallee.slot0();
        index = bound(index, 0, observationIndex - 1);
        (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        ) = IUniswapV3Pool(pool).observations(index);
        (
            uint32 blockTimestampAsm,
            int56 tickCumulativeAsm,
            uint160 secondsPerLiquidityCumulativeX128Asm,
            bool initializedAsm
        ) = poolCallee.observations(index);
        assertEq(blockTimestamp, blockTimestampAsm, "blockTimestamp");
        assertEq(tickCumulative, tickCumulativeAsm, "tickCumulative");
        assertEq(
            secondsPerLiquidityCumulativeX128,
            secondsPerLiquidityCumulativeX128Asm,
            "secondsPerLiquidityCumulativeX128"
        );
        assertEq(initialized, initializedAsm, "initialized");
    }

    function test_Swap() public {
        uint256 amountSpecified = 1e18;
        amountSpecified = prepSwap(true, amountSpecified);
        (, int256 amount1) = poolCallee.swap(
            address(this),
            true,
            int256(amountSpecified),
            TickMath.MIN_SQRT_RATIO + 1,
            new bytes(0)
        );
        assertSwapSuccess(true, uint256(-amount1));
    }

    /// forge-config: default.fuzz.runs = 16
    /// forge-config: ci.fuzz.runs = 16
    function testFuzz_Swap(bool zeroForOne, uint256 amountSpecified, bytes memory data) public virtual {
        amountSpecified = prepSwap(zeroForOne, amountSpecified);
        (int256 amount0, int256 amount1) = poolCallee.swap(
            address(this),
            zeroForOne,
            int256(amountSpecified),
            zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1,
            data
        );
        assertSwapSuccess(zeroForOne, zeroForOne ? uint256(-amount1) : uint256(-amount0));
    }

    function testRevert_AS_Swap() public {
        vm.expectRevert(bytes("AS"));
        poolCaller.swap(address(this), true, 0, TickMath.MIN_SQRT_RATIO, new bytes(0));
    }

    function testRevert_SPL_Swap() public {
        vm.expectRevert(bytes("SPL"));
        poolCaller.swap(address(this), true, int256(1), TickMath.MIN_SQRT_RATIO, new bytes(0));
    }
}

contract PoolCallerPCSTest is PoolCallerTest {
    function setUp() public override {
        dex = DEX.PancakeSwapV3;
        createFork();
        super.setUp();
    }

    /// forge-config: default.fuzz.runs = 16
    /// forge-config: ci.fuzz.runs = 16
    function testFuzz_LiquidityNet(int24 tick) public override {
        super.testFuzz_LiquidityNet(tick);
    }

    /// forge-config: default.fuzz.runs = 16
    /// forge-config: ci.fuzz.runs = 16
    function testFuzz_Positions(bytes32 key) public override {
        super.testFuzz_Positions(key);
    }

    /// forge-config: default.fuzz.runs = 16
    /// forge-config: ci.fuzz.runs = 16
    function testFuzz_Swap(bool zeroForOne, uint256 amountSpecified, bytes memory data) public override {
        super.testFuzz_Swap(zeroForOne, amountSpecified, data);
    }

    /// forge-config: default.fuzz.runs = 16
    /// forge-config: ci.fuzz.runs = 16
    function testFuzz_TickBitmap(int16 wordPos) public override {
        super.testFuzz_TickBitmap(wordPos);
    }

    /// forge-config: default.fuzz.runs = 16
    /// forge-config: ci.fuzz.runs = 16
    function testFuzz_Ticks(int24 tick) public override {
        super.testFuzz_Ticks(tick);
    }

    /// forge-config: default.fuzz.runs = 1
    /// forge-config: ci.fuzz.runs = 1
    function testFuzz_Observations(uint256 index) public override {
        // Skip this test as the PancakeSwap V3 pool did not have any observations at the fork block.
    }

    /// @dev Note that PancakeSwap V3 changed the slot0 struct, specifically changed `feeProtocol` from uint8 to uint32.
    // Therefore, `poolCallee.slot0()` is not able to return the correct value for `feeProtocol` or `unlocked`.
    function test_Slot0() public view override {
        (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            ,

        ) = IPancakeV3Pool(pool).slot0();
        (
            uint160 sqrtPriceX96Asm,
            int24 tickAsm,
            uint16 observationIndexAsm,
            uint16 observationCardinalityAsm,
            uint16 observationCardinalityNextAsm,
            ,

        ) = poolCallee.slot0();
        assertEq(sqrtPriceX96, sqrtPriceX96Asm, "sqrtPriceX96");
        assertEq(tick, tickAsm, "tick");
        assertEq(observationIndex, observationIndexAsm, "observationIndex");
        assertEq(observationCardinality, observationCardinalityAsm, "observationCardinality");
        assertEq(observationCardinalityNext, observationCardinalityNextAsm, "observationCardinalityNext");
    }

    function test_SqrtPriceX96AndTick() public view override {
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = IPancakeV3Pool(pool).slot0();
        (uint160 sqrtPriceX96Asm, int24 tickAsm) = V3PoolCallee.wrap(pool).sqrtPriceX96AndTick();
        assertEq(sqrtPriceX96, sqrtPriceX96Asm, "sqrtPriceX96");
        assertEq(tick, tickAsm, "tick");
    }

    /// @dev Pay pool to finish swap
    using SafeTransferLib for address;
    function pancakeV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external {
        if (amount0Delta > 0) token0.safeTransfer(pool, uint256(amount0Delta));
        if (amount1Delta > 0) token1.safeTransfer(pool, uint256(amount1Delta));
    }
}
