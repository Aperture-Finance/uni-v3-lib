// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./PoolKey.sol";
import "./TernaryLib.sol";

/// @title Provides functions for deriving a pool address from the deployer, tokens, and the fee
/// @author Aperture Finance
/// @author Modified from PancakeSwapV3 (https://www.npmjs.com/package/@pancakeswap/v3-periphery?activeTab=code and look for contracts/libraries/PoolAddress.sol)
/// @dev Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// However, this is safe because "Note that you do not need to update the free memory pointer if there is no following
/// allocation, but you can only use memory starting from the current offset given by the free memory pointer."
/// according to https://docs.soliditylang.org/en/latest/assembly.html#memory-safety.
library PoolAddressPancakeSwapV3 {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0x6ce8eb472fa82df5469c6ab6d485f17c3ad13c8cd7af59b3d4a8026c5ce0f7e2;

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return key The pool details with ordered token0 and token1 assignments
    function getPoolKey(address tokenA, address tokenB, uint24 fee) internal pure returns (PoolKey memory key) {
        (tokenA, tokenB) = TernaryLib.sort2(tokenA, tokenB);
        /// @solidity memory-safe-assembly
        assembly {
            // Must inline this for best performance
            mstore(key, tokenA)
            mstore(add(key, 0x20), tokenB)
            mstore(add(key, 0x40), fee)
        }
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param token0 The first token of a pool, already sorted
    /// @param token1 The second token of a pool, already sorted
    /// @param fee The fee level of the pool
    /// @return key The pool details with ordered token0 and token1 assignments
    function getPoolKeySorted(address token0, address token1, uint24 fee) internal pure returns (PoolKey memory key) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(key, token0)
            mstore(add(key, 0x20), token1)
            mstore(add(key, 0x40), fee)
        }
    }

    /// @notice Deterministically computes the pool address given the deployer and PoolKey
    /// @param deployer The PancakeSwapV3 deployer contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address deployer, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        return computeAddressSorted(deployer, key);
    }

    /// @notice Deterministically computes the pool address given the deployer and PoolKey
    /// @dev Assumes PoolKey is sorted
    /// @param deployer The PancakeSwapV3 deployer contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddressSorted(address deployer, PoolKey memory key) internal pure returns (address pool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the free memory pointer.
            let fmp := mload(0x40)
            // abi.encodePacked(hex'ff', deployer, poolHash, POOL_INIT_CODE_HASH)
            // Prefix the deployer address with 0xff.
            mstore(0, or(deployer, 0xff0000000000000000000000000000000000000000))
            mstore(0x20, keccak256(key, 0x60))
            mstore(0x40, POOL_INIT_CODE_HASH)
            // Compute the CREATE2 pool address and clean the upper bits.
            pool := and(keccak256(0x0b, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)
            // Restore the free memory pointer.
            mstore(0x40, fmp)
        }
    }

    /// @notice Deterministically computes the pool address given the deployer, tokens, and the fee
    /// @param deployer The PancakeSwapV3 deployer contract address
    /// @param tokenA One of the tokens in the pool, unsorted
    /// @param tokenB The other token in the pool, unsorted
    /// @param fee The fee tier of the pool
    function computeAddress(
        address deployer,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (address pool) {
        (tokenA, tokenB) = TernaryLib.sort2(tokenA, tokenB);
        return computeAddressSorted(deployer, tokenA, tokenB, fee);
    }

    /// @notice Deterministically computes the pool address given the deployer, tokens, and the fee
    /// @dev Assumes tokens are sorted
    /// @param deployer The PancakeSwapV3 deployer contract address
    /// @param token0 The first token of a pool, already sorted
    /// @param token1 The second token of a pool, already sorted
    /// @param fee The fee tier of the pool
    function computeAddressSorted(
        address deployer,
        address token0,
        address token1,
        uint24 fee
    ) internal pure returns (address pool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the free memory pointer.
            let fmp := mload(0x40)
            // Hash the pool key.
            mstore(0, token0)
            mstore(0x20, token1)
            mstore(0x40, fee)
            let poolHash := keccak256(0, 0x60)
            // abi.encodePacked(hex'ff', deployer, poolHash, POOL_INIT_CODE_HASH)
            // Prefix the deployer address with 0xff.
            mstore(0, or(deployer, 0xff0000000000000000000000000000000000000000))
            mstore(0x20, poolHash)
            mstore(0x40, POOL_INIT_CODE_HASH)
            // Compute the CREATE2 pool address and clean the upper bits.
            pool := and(keccak256(0x0b, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)
            // Restore the free memory pointer.
            mstore(0x40, fmp)
        }
    }

    /// @notice Deterministically computes the pool address given the deployer and PoolKey
    /// @dev Uses PoolKey in calldata and assumes PoolKey is sorted
    /// @param deployer The PancakeSwapV3 deployer contract address
    /// @param key The abi encoded PoolKey of the V3 pool
    /// @return pool The contract address of the V3 pool
    function computeAddressCalldata(address deployer, bytes calldata key) internal pure returns (address pool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the free memory pointer.
            let fmp := mload(0x40)
            // Hash the pool key.
            calldatacopy(0, key.offset, 0x60)
            let poolHash := keccak256(0, 0x60)
            // abi.encodePacked(hex'ff', deployer, poolHash, POOL_INIT_CODE_HASH)
            // Prefix the deployer address with 0xff.
            mstore(0, or(deployer, 0xff0000000000000000000000000000000000000000))
            mstore(0x20, poolHash)
            mstore(0x40, POOL_INIT_CODE_HASH)
            // Compute the CREATE2 pool address and clean the upper bits.
            pool := and(keccak256(0x0b, 0x55), 0xffffffffffffffffffffffffffffffffffffffff)
            // Restore the free memory pointer.
            mstore(0x40, fmp)
        }
    }
}
