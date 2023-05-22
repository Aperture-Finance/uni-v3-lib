// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma abicoder v2;

interface IPoolAddress {
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external pure returns (PoolKey memory);

    function computeAddress(
        address factory,
        PoolKey memory key
    ) external pure returns (address pool);
}
