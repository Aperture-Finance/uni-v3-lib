// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {PoolAddress} from "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import {IPoolAddress} from "./interfaces/IPoolAddress.sol";

/// @dev Expose internal functions to test the PoolAddress library.
contract PoolAddressTest is IPoolAddress {
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external pure override returns (PoolKey memory key) {
        PoolAddress.PoolKey memory _key = PoolAddress.getPoolKey(
            tokenA,
            tokenB,
            fee
        );
        /// @solidity memory-safe-assembly
        assembly {
            key := _key
        }
    }

    function computeAddress(
        address factory,
        PoolKey memory key
    ) external pure override returns (address pool) {
        PoolAddress.PoolKey memory _key;
        /// @solidity memory-safe-assembly
        assembly {
            _key := key
        }
        return PoolAddress.computeAddress(factory, _key);
    }
}
