// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "./IUniswapV3NonfungiblePositionManager.sol";

/// @title Non-fungible token for PancakeSwap V3 positions
/// @notice Wraps PCSV3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface IPCSV3NonfungiblePositionManager is IUniswapV3NonfungiblePositionManager {
    /// @return Returns the address of the PancakeSwap V3 deployer
    function deployer() external view returns (address);
}
