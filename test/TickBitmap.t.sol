// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITickBitmap} from "src/test/interfaces/ITickBitmap.sol";
import {V3PoolCallee} from "src/PoolCaller.sol";
import {TickBitmap} from "src/TickBitmap.sol";
import "./Base.t.sol";

contract TickBitmapWrapper is ITickBitmap {
    using TickBitmap for mapping(int16 => uint256);

    mapping(int16 => uint256) public bitmap;

    function flipTick(int24 tick) external {
        bitmap.flipTick(tick, 1);
    }

    function nextInitializedTickWithinOneWord(
        int24 tick,
        bool lte
    ) external view returns (int24 next, bool initialized) {
        return bitmap.nextInitializedTickWithinOneWord(tick, 1, lte);
    }

    // returns whether the given tick is initialized
    function isInitialized(int24 tick) external view returns (bool) {
        (int24 next, bool initialized) = bitmap.nextInitializedTickWithinOneWord(tick, 1, true);
        return next == tick ? initialized : false;
    }
}

/// @title Test contract for TickBitmap
contract TickBitmapTest is BaseTest {
    // Wrapper that exposes the original TickBitmap library.
    ITickBitmap internal ogWrapper;
    TickBitmapWrapper internal wrapper;

    function setUp() public virtual override {
        ogWrapper = ITickBitmap(deployCode("out/TickBitmapTest.sol/TickBitmapTest.json"));
        wrapper = new TickBitmapWrapper();
    }

    function testFuzz_Position(int24 tick) public pure {
        int16 wordPos;
        uint8 bitPos;
        assembly {
            // signed arithmetic shift right
            wordPos := sar(8, tick)
            bitPos := and(tick, 0xff)
        }
        assertEq(int256(wordPos), tick >> 8);
        assertEq(bitPos, uint8(int8(tick % 256)));
    }

    function testFuzz_Compress(int24 tick, int24 _tickSpacing) public pure {
        _tickSpacing = int24(bound(_tickSpacing, 1, 200));
        int24 compressed = tick / _tickSpacing;
        if (tick < 0 && tick % _tickSpacing != 0) compressed--;
        assertEq(TickBitmap.compress(tick, _tickSpacing), compressed);
    }

    function testFuzz_FlipTick(int24 tick) public {
        assertEq(wrapper.isInitialized(tick), ogWrapper.isInitialized(tick));
        wrapper.flipTick(tick);
        ogWrapper.flipTick(tick);
        assertEq(wrapper.isInitialized(tick), ogWrapper.isInitialized(tick));
    }

    function testFuzz_NextInitializedTickWithinOneWord(int24 tick, uint8 nextBitPos, bool lte) public {
        tick = int24(bound(tick, TickMath.MIN_TICK, TickMath.MAX_TICK));
        int24 compressed = lte ? tick : tick + 1;
        int16 wordPos = int16(compressed >> 8);
        uint8 bitPos = uint8(int8(compressed % 256));
        if (lte) {
            nextBitPos = uint8(bound(nextBitPos, 0, bitPos));
        } else {
            nextBitPos = uint8(bound(nextBitPos, bitPos, 255));
        }
        // Choose the next initialized tick within one word at random and flip it.
        int24 nextInitializedTick;
        assembly {
            nextInitializedTick := add(shl(8, wordPos), nextBitPos)
        }
        wrapper.flipTick(nextInitializedTick);
        ogWrapper.flipTick(nextInitializedTick);
        (int24 next, bool initialized) = wrapper.nextInitializedTickWithinOneWord(tick, lte);
        (int24 ogNext, bool ogInitialized) = ogWrapper.nextInitializedTickWithinOneWord(tick, lte);
        assertEq(next, nextInitializedTick);
        assertEq(next, ogNext);
        assertEq(initialized, ogInitialized);
    }

    function testGas_NextInitializedTickWithinOneWord() public {
        int24 tick;
        bool initialized;
        for (int16 wordPos = -128; wordPos < 128; ++wordPos) {
            uint8 bitPos = uint8(pseudoRandom(uint16(wordPos)) & 0xff);
            assembly {
                tick := add(shl(8, wordPos), bitPos)
            }
            wrapper.flipTick(tick);
        }
        tick = 128 << 8;
        while (tick > -128 << 8) {
            (tick, initialized) = wrapper.nextInitializedTickWithinOneWord(tick - 1, true);
            if (tick % 256 != 0) {
                assertTrue(initialized);
            }
        }
    }

    function testGas_NextInitializedTickWithinOneWord_Og() public {
        int24 tick;
        bool initialized;
        for (int16 wordPos = -128; wordPos < 128; ++wordPos) {
            uint8 bitPos = uint8(pseudoRandom(uint16(wordPos)) & 0xff);
            assembly {
                tick := add(shl(8, wordPos), bitPos)
            }
            ogWrapper.flipTick(tick);
        }
        tick = 128 << 8;
        while (tick > -128 << 8) {
            (tick, initialized) = ogWrapper.nextInitializedTickWithinOneWord(tick - 1, true);
            if (tick % 256 != 0) {
                assertTrue(initialized);
            }
        }
    }

    /// @notice Test nextInitializedTickWithinOneWord in a fork
    function test_NextInitializedTickWithinOneWord_LTE() public {
        createFork();
        uint256 numIters = dex == DEX.PancakeSwapV3 ? 10 : 256;
        int24 tick = currentTick();
        int16 wordPos = type(int16).min;
        uint256 tickWord;
        unchecked {
            for (uint256 counter; counter < numIters; ++counter) {
                (tick, , wordPos, tickWord) = TickBitmap.nextInitializedTickWithinOneWord(
                    V3PoolCallee.wrap(pool),
                    tick - 1,
                    tickSpacing,
                    true,
                    wordPos,
                    tickWord
                );
            }
        }
    }

    /// @notice Test nextInitializedTickWithinOneWord in a fork
    function test_NextInitializedTickWithinOneWord_GT() public {
        createFork();
        uint256 numIters = dex == DEX.PancakeSwapV3 ? 10 : 256;
        int24 tick = currentTick();
        int16 wordPos = type(int16).min;
        uint256 tickWord;
        unchecked {
            for (uint256 counter; counter < numIters; ++counter) {
                (tick, , wordPos, tickWord) = TickBitmap.nextInitializedTickWithinOneWord(
                    V3PoolCallee.wrap(pool),
                    tick,
                    tickSpacing,
                    false,
                    wordPos,
                    tickWord
                );
            }
        }
    }

    /// @notice Test nextInitializedTick in a fork
    function test_NextInitializedTick_LTE() public {
        createFork();
        uint256 numIters = dex == DEX.PancakeSwapV3 ? 10 : 256;
        int24 tick = currentTick();
        bool initialized;
        int16 wordPos = type(int16).min;
        uint256 tickWord;
        for (uint256 counter; counter < numIters; ) {
            (tick, initialized, wordPos, tickWord) = TickBitmap.nextInitializedTickWithinOneWord(
                V3PoolCallee.wrap(pool),
                tick - 1,
                tickSpacing,
                true,
                wordPos,
                tickWord
            );
            if (initialized) ++counter;
            if (tick < TickMath.MIN_TICK) {
                console2.log("MIN_TICK", tick);
                break;
            }
        }
        int24 finalTick = tick;
        tick = currentTick();
        wordPos = type(int16).min;
        for (uint256 counter; counter < numIters; ++counter) {
            (tick, wordPos, tickWord) = TickBitmap.nextInitializedTick(
                V3PoolCallee.wrap(pool),
                tick - 1,
                tickSpacing,
                true,
                wordPos,
                tickWord
            );
        }
        assertEq(tick, finalTick);
    }

    /// @notice Test nextInitializedTick in a fork
    function test_NextInitializedTick_GT() public {
        createFork();
        uint256 numIters = dex == DEX.PancakeSwapV3 ? 10 : 256;
        int24 tick = currentTick();
        bool initialized;
        int16 wordPos = type(int16).min;
        uint256 tickWord;
        for (uint256 counter; counter < numIters; ) {
            (tick, initialized, wordPos, tickWord) = TickBitmap.nextInitializedTickWithinOneWord(
                V3PoolCallee.wrap(pool),
                tick,
                tickSpacing,
                false,
                wordPos,
                tickWord
            );
            if (initialized) ++counter;
            if (tick > TickMath.MAX_TICK) {
                console2.log("MAX_TICK", tick);
                break;
            }
        }
        int24 finalTick = tick;
        tick = currentTick();
        wordPos = type(int16).min;
        for (uint256 counter; counter < numIters; ++counter) {
            (tick, wordPos, tickWord) = TickBitmap.nextInitializedTick(
                V3PoolCallee.wrap(pool),
                tick,
                tickSpacing,
                false,
                wordPos,
                tickWord
            );
        }
        assertEq(tick, finalTick);
    }
}

contract TickBitmapPCSTest is TickBitmapTest {
    function setUp() public override {
        dex = DEX.PancakeSwapV3;
        super.setUp();
    }
}
