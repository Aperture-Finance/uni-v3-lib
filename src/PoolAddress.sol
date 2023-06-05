// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "./TernaryLib.sol";

/// @notice The identifying key of the pool
struct PoolKey {
    address token0;
    address token1;
    uint24 fee;
}

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-periphery/blob/main/contracts/libraries/PoolAddress.sol)
/// @dev Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// However, this is safe because "Note that you do not need to update the free memory pointer if there is no following
/// allocation, but you can only use memory starting from the current offset given by the free memory pointer."
/// according to https://docs.soliditylang.org/en/latest/assembly.html#memory-safety.
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return key The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory key) {
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
    function getPoolKeySorted(
        address token0,
        address token1,
        uint24 fee
    ) internal pure returns (PoolKey memory key) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(key, token0)
            mstore(add(key, 0x20), token1)
            mstore(add(key, 0x40), fee)
        }
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(
        address factory,
        PoolKey memory key
    ) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        return computeAddressSorted(factory, key);
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @dev Assumes PoolKey is sorted
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddressSorted(
        address factory,
        PoolKey memory key
    ) internal pure returns (address pool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the free memory pointer.
            let fmp := mload(0x40)
            // abi.encodePacked(hex'ff', factory, poolHash, POOL_INIT_CODE_HASH)
            // Prefix the factory address with 0xff.
            mstore(0, or(factory, 0xff0000000000000000000000000000000000000000))
            mstore(0x20, keccak256(key, 0x60))
            mstore(0x40, POOL_INIT_CODE_HASH)
            // Compute the CREATE2 pool address and clean the upper bits.
            pool := and(
                keccak256(0x0b, 0x55),
                0xffffffffffffffffffffffffffffffffffffffff
            )
            // Restore the free memory pointer.
            mstore(0x40, fmp)
        }
    }

    /// @notice Deterministically computes the pool address given the factory, tokens, and the fee
    /// @param factory The Uniswap V3 factory contract address
    /// @param tokenA One of the tokens in the pool, unsorted
    /// @param tokenB The other token in the pool, unsorted
    /// @param fee The fee tier of the pool
    function computeAddress(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (address pool) {
        (tokenA, tokenB) = TernaryLib.sort2(tokenA, tokenB);
        return computeAddressSorted(factory, tokenA, tokenB, fee);
    }

    /// @notice Deterministically computes the pool address given the factory, tokens, and the fee
    /// @dev Assumes tokens are sorted
    /// @param factory The Uniswap V3 factory contract address
    /// @param tokenA One of the tokens in the pool, unsorted
    /// @param tokenB The other token in the pool, unsorted
    /// @param fee The fee tier of the pool
    function computeAddressSorted(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (address pool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the free memory pointer.
            let fmp := mload(0x40)
            // Hash the pool key.
            mstore(0, tokenA)
            mstore(0x20, tokenB)
            mstore(0x40, fee)
            let poolHash := keccak256(0, 0x60)
            // abi.encodePacked(hex'ff', factory, poolHash, POOL_INIT_CODE_HASH)
            // Prefix the factory address with 0xff.
            mstore(0, or(factory, 0xff0000000000000000000000000000000000000000))
            mstore(0x20, poolHash)
            mstore(0x40, POOL_INIT_CODE_HASH)
            // Compute the CREATE2 pool address and clean the upper bits.
            pool := and(
                keccak256(0x0b, 0x55),
                0xffffffffffffffffffffffffffffffffffffffff
            )
            // Restore the free memory pointer.
            mstore(0x40, fmp)
        }
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @dev Uses PoolKey in calldata and assumes PoolKey is sorted
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The abi encoded PoolKey of the V3 pool
    /// @return pool The contract address of the V3 pool
    function computeAddressCalldata(
        address factory,
        bytes calldata key
    ) internal pure returns (address pool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the free memory pointer.
            let fmp := mload(0x40)
            // Hash the pool key.
            calldatacopy(0, key.offset, 0x60)
            let poolHash := keccak256(0, 0x60)
            // abi.encodePacked(hex'ff', factory, poolHash, POOL_INIT_CODE_HASH)
            // Prefix the factory address with 0xff.
            mstore(0, or(factory, 0xff0000000000000000000000000000000000000000))
            mstore(0x20, poolHash)
            mstore(0x40, POOL_INIT_CODE_HASH)
            // Compute the CREATE2 pool address and clean the upper bits.
            pool := and(
                keccak256(0x0b, 0x55),
                0xffffffffffffffffffffffffffffffffffffffff
            )
            // Restore the free memory pointer.
            mstore(0x40, fmp)
        }
    }
}
