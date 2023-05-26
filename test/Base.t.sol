// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {INonfungiblePositionManager} from "src/interfaces/INonfungiblePositionManager.sol";
import {TickMath} from "src/TickMath.sol";

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

    function boundUint160(uint160 x) internal view returns (uint160) {
        return
            uint160(bound(x, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO));
    }

    function pseudoRandom(uint256 seed) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(seed)));
    }

    function pseudoRandomUint160(uint256 seed) internal pure returns (uint160) {
        return uint160(pseudoRandom(seed));
    }

    function pseudoRandomUint128(uint256 seed) internal pure returns (uint128) {
        return uint128(pseudoRandom(seed));
    }

    function pseudoRandomInt128(uint256 seed) internal pure returns (int128) {
        return int128(int256(pseudoRandom(seed)));
    }
}
