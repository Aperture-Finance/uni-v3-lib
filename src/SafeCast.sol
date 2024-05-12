// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-core/blob/main/contracts/libraries/SafeCast.sol)
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param x The uint256 to be downcasted
    /// @return The downcasted integer, now type uint160
    function toUint160(uint256 x) internal pure returns (uint160) {
        if (x >= 1 << 160) revert();
        return uint160(x);
    }

    /// @notice Cast a uint256 to a uint128, revert on overflow
    /// @param x The uint256 to be downcasted
    /// @return The downcasted integer, now type uint128
    function toUint128(uint256 x) internal pure returns (uint128) {
        if (x >= 1 << 128) revert();
        return uint128(x);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param x The int256 to be downcasted
    /// @return The downcasted integer, now type int128
    function toInt128(int256 x) internal pure returns (int128) {
        unchecked {
            if (((1 << 127) + uint256(x)) >> 128 == uint256(0)) return int128(x);
            revert();
        }
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param x The uint256 to be casted
    /// @return The casted integer, now type int256
    function toInt256(uint256 x) internal pure returns (int256) {
        if (int256(x) >= 0) return int256(x);
        revert();
    }

    /// @notice Cast a uint256 to a int128, revert on overflow
    /// @param x The uint256 to be downcasted
    /// @return The downcasted integer, now type int128
    function toInt128(uint256 x) internal pure returns (int128) {
        if (x >= 1 << 127) revert();
        return int128(int256(x));
    }
}
