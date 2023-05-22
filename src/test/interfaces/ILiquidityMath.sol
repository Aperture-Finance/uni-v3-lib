// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ILiquidityMath {
    function addDelta(uint128 x, int128 y) external pure returns (uint128 z);
}
