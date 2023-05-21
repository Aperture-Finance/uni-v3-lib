// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.8;

import "./BitMath.sol";
import "./PoolCaller.sol";

/// @title Packed tick initialized state library
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-core/blob/main/contracts/libraries/TickBitmap.sol)
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(
        int24 tick
    ) internal pure returns (int16 wordPos, uint8 bitPos) {
        assembly {
            // signed arithmetic shift right
            wordPos := sar(8, tick)
            bitPos := and(tick, 255)
        }
    }

    /// @dev round towards negative infinity
    function compress(
        int24 tick,
        int24 tickSpacing
    ) internal pure returns (int24 compressed) {
        // compressed = tick / tickSpacing;
        // if (tick < 0 && tick % tickSpacing != 0) compressed--;
        assembly {
            compressed := sub(
                sdiv(tick, tickSpacing),
                // If (tick < 0 && tick % tickSpacing != 0) then tick % tickSpacing < 0, vice versa
                slt(smod(tick, tickSpacing), 0)
            )
        }
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param pool Uniswap v3 pool
    /// @param tick The starting tick
    /// @param tickSpacing The spacing between usable ticks
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @param lastWordPos The last read word position in the Bitmap
    /// @param lastWord The last read word in the Bitmap
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(
        V3PoolCallee pool,
        int24 tick,
        int24 tickSpacing,
        bool lte,
        int16 lastWordPos,
        uint256 lastWord
    )
        internal
        view
        returns (int24 next, bool initialized, int16 wordPos, uint256 tickWord)
    {
        int24 compressed = compress(tick, tickSpacing);
        uint8 bitPos;
        uint256 mask;
        uint256 masked;

        if (lte) {
            (wordPos, bitPos) = position(compressed);
            // Reuse the same word if the position doesn't change
            tickWord = wordPos == lastWordPos
                ? lastWord
                : pool.tickBitmap(wordPos);
            // all the 1s at or to the right of the current bitPos
            // mask = (1 << (bitPos + 1)) - 1
            // (bitPos + 1) may be 256 but fine
            assembly {
                mask := sub(shl(add(bitPos, 1), 1), 1)
                masked := and(tickWord, mask)
                initialized := iszero(iszero(masked))
            }

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            if (initialized) {
                uint8 msb = BitMath.mostSignificantBit(masked);
                assembly {
                    next := mul(add(sub(compressed, bitPos), msb), tickSpacing)
                }
            } else {
                assembly {
                    next := mul(sub(compressed, bitPos), tickSpacing)
                }
            }
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            unchecked {
                (wordPos, bitPos) = position(++compressed);
            }
            // Reuse the same word if the position doesn't change
            tickWord = wordPos == lastWordPos
                ? lastWord
                : pool.tickBitmap(wordPos);
            // all the 1s at or to the left of the bitPos
            // mask = ~((1 << bitPos) - 1)
            assembly {
                mask := not(sub(shl(bitPos, 1), 1))
                masked := and(tickWord, mask)
                initialized := iszero(iszero(masked))
            }

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            if (initialized) {
                uint8 lsb = BitMath.leastSignificantBit(masked);
                assembly {
                    next := mul(add(sub(compressed, bitPos), lsb), tickSpacing)
                }
            } else {
                assembly {
                    next := mul(add(sub(compressed, bitPos), 255), tickSpacing)
                }
            }
        }
    }

    /// @notice Returns the next initialized tick not limited to the same word as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @dev It is assumed that the next initialized tick exists.
    /// @param pool Uniswap v3 pool
    /// @param tick The starting tick
    /// @param tickSpacing The spacing between usable ticks
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @param lastWordPos The last read word position in the Bitmap
    /// @param lastWord The last read word in the Bitmap
    /// @return next The next initialized tick
    function nextInitializedTick(
        V3PoolCallee pool,
        int24 tick,
        int24 tickSpacing,
        bool lte,
        int16 lastWordPos,
        uint256 lastWord
    ) internal view returns (int24 next, int16 wordPos, uint256 tickWord) {
        int24 compressed = compress(tick, tickSpacing);
        uint8 bitPos;
        uint256 masked;
        uint8 sb;
        if (lte) {
            (wordPos, bitPos) = position(compressed);
            // Reuse the same word if the position doesn't change
            tickWord = wordPos == lastWordPos
                ? lastWord
                : pool.tickBitmap(wordPos);
            // all the 1s at or to the right of the current bitPos
            // mask = (1 << (bitPos + 1)) - 1
            // (bitPos + 1) may be 256 but fine
            assembly {
                let mask := sub(shl(add(bitPos, 1), 1), 1)
                masked := and(tickWord, mask)
            }
            while (masked == 0) {
                // Always query the next word to the left
                unchecked {
                    masked = tickWord = pool.tickBitmap(--wordPos);
                }
            }
            sb = BitMath.mostSignificantBit(masked);
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            unchecked {
                (wordPos, bitPos) = position(++compressed);
            }
            // Reuse the same word if the position doesn't change
            tickWord = wordPos == lastWordPos
                ? lastWord
                : pool.tickBitmap(wordPos);
            // all the 1s at or to the left of the bitPos
            // mask = ~((1 << bitPos) - 1)
            assembly {
                let mask := not(sub(shl(bitPos, 1), 1))
                masked := and(tickWord, mask)
            }
            while (masked == 0) {
                // Always query the next word to the right
                unchecked {
                    masked = tickWord = pool.tickBitmap(++wordPos);
                }
            }
            sb = BitMath.leastSignificantBit(masked);
        }
        assembly {
            // next = (wordPos * 256 + sb) * tickSpacing
            next := mul(add(shl(8, wordPos), sb), tickSpacing)
        }
    }
}
