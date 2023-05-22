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
            z := and(0xffffffffffffffffffffffffffffffff, add(x, y))
            for {

            } 1 {

            } {
                if slt(y, 0) {
                    if iszero(lt(z, x)) {
                        // selector "Error(string)"
                        mstore(0, 0x08c379a0)
                        // abi encoding offset
                        mstore(0x20, 0x20)
                        // reason string length
                        mstore(0x40, 2)
                        mstore(0x60, "LS")
                        revert(0x1c, 0x46)
                    }
                    break
                }
                if lt(z, x) {
                    mstore(0, 0x08c379a0)
                    mstore(0x20, 0x20)
                    mstore(0x40, 2)
                    mstore(0x60, "LA")
                    revert(0x1c, 0x46)
                }
                break
            }
        }
    }
}
