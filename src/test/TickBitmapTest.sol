// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@uniswap/v3-core/contracts/libraries/TickBitmap.sol";
import "./interfaces/ITickBitmap.sol";

/// @dev Expose internal functions to test the TickBitmap library.
contract TickBitmapTest is ITickBitmap {
    using TickBitmap for mapping(int16 => uint256);

    mapping(int16 => uint256) public bitmap;

    function flipTick(int24 tick) external override {
        bitmap.flipTick(tick, 1);
    }

    function nextInitializedTickWithinOneWord(
        int24 tick,
        bool lte
    ) external view override returns (int24 next, bool initialized) {
        return bitmap.nextInitializedTickWithinOneWord(tick, 1, lte);
    }

    // returns whether the given tick is initialized
    function isInitialized(int24 tick) external view override returns (bool) {
        (int24 next, bool initialized) = bitmap
            .nextInitializedTickWithinOneWord(tick, 1, true);
        return next == tick ? initialized : false;
    }
}
