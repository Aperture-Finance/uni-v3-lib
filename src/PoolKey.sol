// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @notice The identifying key of a liquidity pool
struct PoolKey {
    address token0;
    address token1;
    uint24 fee;
}
