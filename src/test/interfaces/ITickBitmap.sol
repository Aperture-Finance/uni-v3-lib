// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ITickBitmap {
    function flipTick(int24 tick) external;

    function nextInitializedTickWithinOneWord(
        int24 tick,
        bool lte
    ) external view returns (int24 next, bool initialized);

    function isInitialized(int24 tick) external view returns (bool);
}
