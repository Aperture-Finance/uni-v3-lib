// SPDX-License-Identifier: GPL-3.0-or-later
// User defined value types are introduced in Solidity v0.8.8.
// https://blog.soliditylang.org/2021/09/27/user-defined-value-types/
pragma solidity >=0.8.8;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

type V3PoolCallee is address;
using PoolCaller for V3PoolCallee global;

/// @title Uniswap v3 Pool Caller
/// @author Aperture Finance
/// @notice Gas efficient library to call `IUniswapV3Pool` assuming the pool exists.
/// @dev Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// However, this is safe because "Note that you do not need to update the free memory pointer if there is no following
/// allocation, but you can only use memory starting from the current offset given by the free memory pointer."
/// according to https://docs.soliditylang.org/en/latest/assembly.html#memory-safety.
library PoolCaller {
    /// @dev Equivalent to `IUniswapV3Pool.fee`
    /// @param pool Uniswap v3 pool
    function fee(V3PoolCallee pool) internal view returns (uint24 f) {
        bytes4 selector = IUniswapV3PoolImmutables.fee.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), pool, 0, 4, 0, 0x20)) {
                revert(0, 0)
            }
            f := mload(0)
        }
    }

    /// @dev Equivalent to `IUniswapV3Pool.tickSpacing`
    /// @param pool Uniswap v3 pool
    function tickSpacing(V3PoolCallee pool) internal view returns (int24 ts) {
        bytes4 selector = IUniswapV3PoolImmutables.tickSpacing.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), pool, 0, 4, 0, 0x20)) {
                revert(0, 0)
            }
            ts := mload(0)
        }
    }

    /// @dev Equivalent to `IUniswapV3Pool.slot0`
    /// @param pool Uniswap v3 pool
    function slot0(
        V3PoolCallee pool
    )
        internal
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        bytes4 selector = IUniswapV3PoolState.slot0.selector;
        assembly ("memory-safe") {
            // Get a pointer to some free memory.
            let fmp := mload(0x40)
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We copy up to 224 bytes of return data after fmp.
            if iszero(staticcall(gas(), pool, 0, 4, fmp, 0xe0)) {
                revert(0, 0)
            }
            sqrtPriceX96 := mload(fmp)
            tick := mload(add(fmp, 0x20))
            observationIndex := mload(add(fmp, 0x40))
            observationCardinality := mload(add(fmp, 0x60))
            observationCardinalityNext := mload(add(fmp, 0x80))
            feeProtocol := mload(add(fmp, 0xa0))
            unlocked := mload(add(fmp, 0xc0))
        }
    }

    /// @dev Equivalent to `(uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0()`
    /// @param pool Uniswap v3 pool
    function sqrtPriceX96AndTick(
        V3PoolCallee pool
    ) internal view returns (uint160 sqrtPriceX96, int24 tick) {
        bytes4 selector = IUniswapV3PoolState.slot0.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We use 0 and 64 to copy up to 64 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), pool, 0, 4, 0, 0x40)) {
                revert(0, 0)
            }
            sqrtPriceX96 := mload(0)
            tick := mload(0x20)
        }
    }

    /// @dev Equivalent to `IUniswapV3Pool.liquidity`
    /// @param pool Uniswap v3 pool
    function liquidity(V3PoolCallee pool) internal view returns (uint128 l) {
        bytes4 selector = IUniswapV3PoolState.liquidity.selector;
        assembly ("memory-safe") {
            // Write the function selector into memory.
            mstore(0, selector)
            // We use 4 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), pool, 0, 4, 0, 0x20)) {
                revert(0, 0)
            }
            l := mload(0)
        }
    }

    /// @dev Equivalent to `IUniswapV3Pool.tickBitmap`
    /// @param pool Uniswap v3 pool
    /// @param wordPos The key in the mapping containing the word in which the bit is stored
    function tickBitmap(
        V3PoolCallee pool,
        int16 wordPos
    ) internal view returns (uint256 tickWord) {
        bytes4 selector = IUniswapV3PoolState.tickBitmap.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            // Pad int16 to 32 bytes.
            mstore(4, signextend(1, wordPos))
            // We use 36 because of the length of our calldata.
            // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), pool, 0, 0x24, 0, 0x20)) {
                revert(0, 0)
            }
            tickWord := mload(0)
        }
    }

    // info stored for each initialized individual tick
    struct Info {
        // the total position liquidity that references this tick
        uint128 liquidityGross;
        // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
        int128 liquidityNet;
        // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        // the cumulative tick value on the other side of the tick
        int56 tickCumulativeOutside;
        // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint160 secondsPerLiquidityOutsideX128;
        // the seconds spent on the other side of the tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint32 secondsOutside;
        // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
        // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
        bool initialized;
    }

    /// @dev Equivalent to `IUniswapV3Pool.ticks`
    /// @param pool Uniswap v3 pool
    function ticks(
        V3PoolCallee pool,
        int24 tick
    ) internal view returns (Info memory info) {
        bytes4 selector = IUniswapV3PoolState.ticks.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            // Pad int24 to 32 bytes.
            mstore(4, signextend(2, tick))
            // We use 36 because of the length of our calldata.
            // We copy up to 256 bytes of return data at info's pointer.
            if iszero(staticcall(gas(), pool, 0, 0x24, info, 0x100)) {
                revert(0, 0)
            }
        }
    }

    /// @dev Equivalent to `( , int128 liquidityNet, , , , , , ) = pool.ticks(tick)`
    /// @param pool Uniswap v3 pool
    function liquidityNet(
        V3PoolCallee pool,
        int24 tick
    ) internal view returns (int128 ln) {
        bytes4 selector = IUniswapV3PoolState.ticks.selector;
        assembly ("memory-safe") {
            // Write the abi-encoded calldata into memory.
            mstore(0, selector)
            // Pad int24 to 32 bytes.
            mstore(4, signextend(2, tick))
            // We use 36 because of the length of our calldata.
            // We use 0 and 64 to copy up to 64 bytes of return data into the scratch space.
            if iszero(staticcall(gas(), pool, 0, 0x24, 0, 0x40)) {
                revert(0, 0)
            }
            ln := mload(0x20)
        }
    }

    /// @dev Equivalent to `IUniswapV3Pool.swap`
    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param pool Uniswap v3 pool
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        V3PoolCallee pool,
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes memory data
    ) internal returns (int256 amount0, int256 amount1) {
        bytes4 selector = IUniswapV3PoolActions.swap.selector;
        assembly ("memory-safe") {
            // Get a pointer to some free memory.
            let fmp := mload(0x40)
            mstore(fmp, selector)
            mstore(add(fmp, 4), recipient)
            mstore(add(fmp, 0x24), zeroForOne)
            mstore(add(fmp, 0x44), amountSpecified)
            mstore(add(fmp, 0x64), sqrtPriceLimitX96)
            // Use 160 for the offset of `data` in calldata.
            mstore(add(fmp, 0x84), 0xa0)
            // length = data.length + 32
            let length := add(mload(data), 0x20)
            // Call the identity precompile 0x04 to copy `data` into calldata.
            pop(staticcall(gas(), 0x04, data, length, add(fmp, 0xa4), length))
            // We use `196 + data.length` for the length of our calldata.
            // We use 0 and 64 to copy up to 64 bytes of return data into the scratch space.
            if iszero(
                and(
                    // The arguments of `and` are evaluated from right to left.
                    eq(returndatasize(), 0x40), // Ensure `returndatasize` is 64.
                    call(gas(), pool, 0, fmp, add(0xa4, length), 0, 0x40)
                )
            ) {
                // It is safe to overwrite the free memory pointer 0x40 and the zero pointer 0x60 here before exiting
                // because a contract obtains a freshly cleared instance of memory for each message call.
                returndatacopy(0, 0, returndatasize())
                // Bubble up the revert reason.
                revert(0, returndatasize())
            }
            // Read the return data.
            amount0 := mload(0)
            amount1 := mload(0x20)
        }
    }
}
