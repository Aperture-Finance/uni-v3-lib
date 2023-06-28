// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

/// @title BitMath
/// @author Aperture Finance
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibBit.sol)
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     If x == 0, r == 0. Otherwise
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        assembly {
            // r = x >= 2**128 ? 128 : 0
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            // r += (x >> r) >= 2**64 ? 64 : 0
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            // r += (x >> r) >= 2**32 ? 32 : 0
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // https://graphics.stanford.edu/~seander/bithacks.html#IntegerLogDeBruijn
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            r := or(
                r,
                byte(
                    shr(251, mul(x, shl(224, 0x07c4acdd))),
                    0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f
                )
            )
        }
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     If x == 0, r == 0. Otherwise
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        assembly {
            // Isolate the least significant bit, x = x & -x = x & (~x + 1)
            x := and(x, sub(0, x))

            // r = x >= 2**128 ? 128 : 0
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            // r += (x >> r) >= 2**64 ? 64 : 0
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            // r += (x >> r) >= 2**32 ? 32 : 0
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // https://graphics.stanford.edu/~seander/bithacks.html#ZerosOnRightMultLookup
            r := or(
                r,
                byte(
                    shr(251, mul(shr(r, x), shl(224, 0x077cb531))),
                    0x00011c021d0e18031e16140f191104081f1b0d17151310071a0c12060b050a09
                )
            )
        }
    }
}
