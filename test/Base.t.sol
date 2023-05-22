// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {INonfungiblePositionManager} from "../src/interfaces/INonfungiblePositionManager.sol";

/// @dev Base test class for all tests.
abstract contract BaseTest is Test {
    IUniswapV3Factory internal constant factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    INonfungiblePositionManager internal constant npm =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    function setUp() public virtual {}

    /// @dev Deploy a test wrapper with `name` to `lib` using `vm.etch`.
    function makeOriginalLibrary(address lib, string memory name) internal {
        string memory file = string.concat(
            vm.projectRoot(),
            "/artifacts/src/test/",
            name,
            ".sol/",
            name,
            ".json"
        );
        bytes memory deployedBytecode = vm.parseJsonBytes(
            vm.readFile(file),
            ".deployedBytecode"
        );
        vm.etch(lib, deployedBytecode);
    }
}
