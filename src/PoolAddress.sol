// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @notice The identifying key of the pool
struct PoolKey {
    address token0;
    address token1;
    uint24 fee;
}

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-periphery/blob/main/contracts/libraries/PoolAddress.sol)
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
        assembly ("memory-safe") {
            // Sort `tokenA` and `tokenB`
            let diff := mul(xor(tokenA, tokenB), lt(tokenB, tokenA))
            mstore(key, xor(tokenA, diff))
            mstore(add(key, 0x20), xor(tokenB, diff))
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
        assembly ("memory-safe") {
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
        assembly ("memory-safe") {
            let fmp := mload(0x40)
            mstore(fmp, factory)
            fmp := add(fmp, 0x0b)
            mstore8(fmp, 0xff)
            mstore(add(fmp, 0x15), keccak256(key, 0x60))
            mstore(add(fmp, 0x35), POOL_INIT_CODE_HASH)
            pool := and(
                keccak256(fmp, 0x55),
                0xffffffffffffffffffffffffffffffffffffffff
            )
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
        assembly ("memory-safe") {
            // Sort `tokenA` and `tokenB`
            let diff := mul(xor(tokenA, tokenB), lt(tokenB, tokenA))
            tokenA := xor(tokenA, diff)
            tokenB := xor(tokenB, diff)
        }
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
        assembly ("memory-safe") {
            // Get the free memory pointer.
            let fmp := mload(0x40)
            // Hash the pool key.
            mstore(fmp, tokenA)
            mstore(add(fmp, 0x20), tokenB)
            mstore(add(fmp, 0x40), fee)
            let poolHash := keccak256(fmp, 0x60)
            // abi.encodePacked(hex'ff', factory, poolHash, POOL_INIT_CODE_HASH)
            mstore(fmp, factory)
            fmp := add(fmp, 0x0b)
            mstore8(fmp, 0xff)
            mstore(add(fmp, 0x15), poolHash)
            mstore(add(fmp, 0x35), POOL_INIT_CODE_HASH)
            // Compute the CREATE2 pool address and clean the upper bits.
            pool := and(
                keccak256(fmp, 0x55),
                0xffffffffffffffffffffffffffffffffffffffff
            )
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
        assembly ("memory-safe") {
            // Get the free memory pointer.
            let fmp := mload(0x40)
            // Hash the pool key.
            calldatacopy(fmp, key.offset, 0x60)
            let poolHash := keccak256(fmp, 0x60)
            // abi.encodePacked(hex'ff', factory, poolHash, POOL_INIT_CODE_HASH)
            mstore(fmp, factory)
            fmp := add(fmp, 0x0b)
            mstore8(fmp, 0xff)
            mstore(add(fmp, 0x15), poolHash)
            mstore(add(fmp, 0x35), POOL_INIT_CODE_HASH)
            // Compute the CREATE2 pool address and clean the upper bits.
            pool := and(
                keccak256(fmp, 0x55),
                0xffffffffffffffffffffffffffffffffffffffff
            )
        }
    }
}
