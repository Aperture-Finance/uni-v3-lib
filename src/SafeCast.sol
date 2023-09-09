// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

/// @title Safe casting methods
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-core/blob/main/contracts/libraries/SafeCast.sol)
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if shr(160, y) {
                revert(0, 0)
            }
            z := y
        }
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint128
    function toUint128(uint256 y) internal pure returns (uint128 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if shr(128, y) {
                revert(0, 0)
            }
            z := y
        }
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if sub(y, signextend(15, y)) {
                revert(0, 0)
            }
            z := y
        }
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if shr(255, y) {
                revert(0, 0)
            }
            z := y
        }
    }

    /// @notice Cast a uint256 to a int128, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(uint256 y) internal pure returns (int128 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if shr(127, y) {
                revert(0, 0)
            }
            z := y
        }
    }
}
