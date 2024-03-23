// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "@pancakeswap/v3-core/contracts/interfaces/IPancakeV3Pool.sol";
import "./PoolAddressPancakeSwapV3.sol";

/// @notice Provides validation for callbacks from PancakeSwapV3 Pools
/// @author Aperture Finance
/// @author Modified from PancakeSwapV3 (https://www.npmjs.com/package/@pancakeswap/v3-periphery?activeTab=code and look for contracts/libraries/CallbackValidation.sol)
library CallbackValidationPancakeSwapV3 {
    /// @notice Returns the address of a valid PancakeSwapV3 Pool
    /// @param deployer The contract address of the PancakeSwapV3 deployer
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address deployer,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (IPancakeV3Pool pool) {
        pool = IPancakeV3Pool(PoolAddressPancakeSwapV3.computeAddress(deployer, tokenA, tokenB, fee));
        require(msg.sender == address(pool));
    }

    /// @notice Returns the address of a valid PancakeSwapV3 Pool
    /// @param deployer The contract address of the PancakeSwapV3 deployer
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback(address deployer, PoolKey memory poolKey) internal view returns (IPancakeV3Pool pool) {
        pool = IPancakeV3Pool(PoolAddressPancakeSwapV3.computeAddressSorted(deployer, poolKey));
        require(msg.sender == address(pool));
    }

    /// @notice Returns the address of a valid PancakeSwapV3 Pool
    /// @param deployer The contract address of the PancakeSwapV3 deployer
    /// @param poolKey The abi encoded PoolKey of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallbackCalldata(address deployer, bytes calldata poolKey) internal view returns (address pool) {
        pool = PoolAddressPancakeSwapV3.computeAddressCalldata(deployer, poolKey);
        require(msg.sender == pool);
    }
}
