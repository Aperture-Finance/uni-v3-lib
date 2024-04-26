// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/// @title Library for efficient ternary operations
/// @author Aperture Finance
library TernaryLib {
    /// @notice Equivalent to the ternary operator: `condition ? a : b`
    function ternary(bool condition, uint256 a, uint256 b) internal pure returns (uint256 res) {
        assembly {
            res := xor(b, mul(xor(a, b), condition))
        }
    }

    /// @notice Equivalent to the ternary operator: `condition ? a : b`
    function ternary(bool condition, address a, address b) internal pure returns (address res) {
        assembly {
            res := xor(b, mul(xor(a, b), condition))
        }
    }

    /// @notice Equivalent to: `uint256(x < 0 ? -x : x)`
    function abs(int256 x) internal pure returns (uint256 y) {
        assembly {
            // mask = 0 if x >= 0 else -1
            let mask := sar(255, x)
            // If x >= 0, |x| = x = 0 ^ x
            // If x < 0, |x| = ~~|x| = ~(-|x| - 1) = ~(x - 1) = -1 ^ (x - 1)
            // Either case, |x| = mask ^ (x + mask)
            y := xor(mask, add(mask, x))
        }
    }

    /// @notice Equivalent to: `a > b ? a - b : b - a`
    function absDiff(uint256 a, uint256 b) internal pure returns (uint256 res) {
        assembly {
            let diff := sub(a, b)
            let mask := sar(255, diff)
            res := xor(mask, add(mask, diff))
        }
    }

    /// @notice Equivalent to: `a > b ? a - b : b - a`
    function absDiffU160(uint160 a, uint160 b) internal pure returns (uint256 res) {
        assembly {
            let diff := sub(a, b)
            let mask := sar(255, diff)
            res := xor(mask, add(mask, diff))
        }
    }

    /// @notice Equivalent to: `a < b ? a : b`
    function min(uint256 a, uint256 b) internal pure returns (uint256 res) {
        assembly {
            res := xor(b, mul(xor(a, b), lt(a, b)))
        }
    }

    /// @notice Equivalent to: `a > b ? a : b`
    function max(uint256 a, uint256 b) internal pure returns (uint256 res) {
        assembly {
            res := xor(b, mul(xor(a, b), gt(a, b)))
        }
    }

    /// @notice Equivalent to: `condition ? (b, a) : (a, b)`
    function switchIf(bool condition, uint256 a, uint256 b) internal pure returns (uint256, uint256) {
        assembly {
            let diff := mul(xor(a, b), condition)
            a := xor(a, diff)
            b := xor(b, diff)
        }
        return (a, b);
    }

    /// @notice Equivalent to: `condition ? (b, a) : (a, b)`
    function switchIf(bool condition, address a, address b) internal pure returns (address, address) {
        assembly {
            let diff := mul(xor(a, b), condition)
            a := xor(a, diff)
            b := xor(b, diff)
        }
        return (a, b);
    }

    /// @notice Sorts two addresses and returns them in ascending order
    function sort2(address a, address b) internal pure returns (address, address) {
        assembly {
            let diff := mul(xor(a, b), lt(b, a))
            a := xor(a, diff)
            b := xor(b, diff)
        }
        return (a, b);
    }

    /// @notice Sorts two uint256s and returns them in ascending order
    function sort2(uint256 a, uint256 b) internal pure returns (uint256, uint256) {
        assembly {
            let diff := mul(xor(a, b), lt(b, a))
            a := xor(a, diff)
            b := xor(b, diff)
        }
        return (a, b);
    }

    /// @notice Sorts two uint160s and returns them in ascending order
    function sort2U160(uint160 a, uint160 b) internal pure returns (uint160, uint160) {
        assembly {
            let diff := mul(xor(a, b), lt(b, a))
            a := xor(a, diff)
            b := xor(b, diff)
        }
        return (a, b);
    }
}
