// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "solady/src/utils/FixedPointMathLib.sol";

/// @title Contains 512-bit math functions
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-core/blob/main/contracts/libraries/FullMath.sol)
/// @author Credit to Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        return FixedPointMathLib.fullMulDiv(a, b, denominator);
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256) {
        return FixedPointMathLib.fullMulDivUp(a, b, denominator);
    }

    /// @notice Calculates a * b / 2^96 with full precision.
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @return result The 256-bit result
    function mulDivQ96(uint256 a, uint256 b) internal pure returns (uint256 result) {
        assembly ("memory-safe") {
            // 512-bit multiply `[prod1 prod0] = a * b`.
            // Compute the product mod `2**256` and mod `2**256 - 1`
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that `product = prod1 * 2**256 + prod0`.

            // Least significant 256 bits of the product.
            let prod0 := mul(a, b)
            let mm := mulmod(a, b, not(0))
            // Most significant 256 bits of the product.
            let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

            // Make sure the result is less than `2**256`.
            if iszero(gt(0x1000000000000000000000000, prod1)) {
                // Store the function selector of `FullMulDivFailed()`.
                mstore(0x00, 0xae47f702)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Divide [prod1 prod0] by 2^96.
            result := or(shr(96, prod0), shl(160, prod1))
        }
    }

    /// @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
    function sqrt(uint256 x) internal pure returns (uint256) {
        return FixedPointMathLib.sqrt(x);
    }
}
