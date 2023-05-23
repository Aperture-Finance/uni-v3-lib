// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ITickMath {
    function getSqrtRatioAtTick(
        int24 tick
    ) external pure returns (uint160 sqrtPriceX96);

    function getTickAtSqrtRatio(
        uint160 sqrtPriceX96
    ) external pure returns (int24 tick);
}
