// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for liquidity
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-core/blob/main/contracts/libraries/LiquidityMath.sol)
library LiquidityMath {
    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @param x The liquidity before change
    /// @param y The delta by which liquidity should be changed
    /// @return z The liquidity delta
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := add(x, y)
            if shr(128, z) {
                if slt(y, 0) {
                    // revert on underflow
                    // selector "Error(string)", [0x1c, 0x20)
                    mstore(0, 0x08c379a0)
                    // abi encoding offset
                    mstore(0x20, 0x20)
                    // reason string length 2 and 'LS', [0x5f, 0x62)
                    mstore(0x42, 0x024c53)
                    // 4 byte selector + 32 byte offset + 32 byte length + 2 byte reason
                    revert(0x1c, 0x46)
                }
                // revert on overflow
                // selector "Error(string)", [0x1c, 0x20)
                mstore(0, 0x08c379a0)
                // abi encoding offset
                mstore(0x20, 0x20)
                // reason string length 2 and 'LA', [0x5f, 0x62)
                mstore(0x42, 0x024c41)
                // 4 byte selector + 32 byte offset + 32 byte length + 2 byte reason
                revert(0x1c, 0x46)
            }
        }
    }
}
