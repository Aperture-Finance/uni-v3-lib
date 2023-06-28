// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./PoolAddress.sol";

/// @notice Provides validation for callbacks from Uniswap V3 Pools
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-periphery/blob/main/contracts/libraries/CallbackValidation.sol)
library CallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool) {
        pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, tokenA, tokenB, fee));
        require(msg.sender == address(pool));
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback(address factory, PoolKey memory poolKey) internal view returns (IUniswapV3Pool pool) {
        pool = IUniswapV3Pool(PoolAddress.computeAddressSorted(factory, poolKey));
        require(msg.sender == address(pool));
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param poolKey The abi encoded PoolKey of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallbackCalldata(address factory, bytes calldata poolKey) internal view returns (address pool) {
        pool = PoolAddress.computeAddressCalldata(factory, poolKey);
        require(msg.sender == pool);
    }
}
