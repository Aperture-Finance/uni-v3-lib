// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/// @title Library for efficient ternary operations
/// @author Aperture Finance
library TernaryLib {
    /// @notice Equivalent to the ternary operator: `condition ? a : b`
    function ternary(
        bool condition,
        uint256 a,
        uint256 b
    ) internal pure returns (uint256 res) {
        assembly {
            res := xor(b, mul(xor(a, b), condition))
        }
    }

    /// @notice Equivalent to the ternary operator: `condition ? a : b`
    function ternary(
        bool condition,
        address a,
        address b
    ) internal pure returns (address res) {
        assembly {
            res := xor(b, mul(xor(a, b), condition))
        }
    }

    /// @notice Equivalent to: `a < b ? a : b`
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return ternary(a < b, a, b);
    }

    /// @notice Equivalent to: `a > b ? a : b`
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return ternary(a > b, a, b);
    }

    /// @notice Equivalent to: `condition ? (b, a) : (a, b)`
    function switchIf(
        bool condition,
        address a,
        address b
    ) internal pure returns (address, address) {
        assembly {
            let diff := mul(xor(a, b), condition)
            a := xor(a, diff)
            b := xor(b, diff)
        }
        return (a, b);
    }

    /// @notice Sorts two addresses and returns them in ascending order
    function sort2(
        address a,
        address b
    ) internal pure returns (address, address) {
        assembly {
            let diff := mul(xor(a, b), lt(b, a))
            a := xor(a, diff)
            b := xor(b, diff)
        }
        return (a, b);
    }

    /// @notice Sorts two uint160s and returns them in ascending order
    function sort2(
        uint160 a,
        uint160 b
    ) internal pure returns (uint160, uint160) {
        assembly {
            let diff := mul(xor(a, b), lt(b, a))
            a := xor(a, diff)
            b := xor(b, diff)
        }
        return (a, b);
    }
}
