// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {INonfungiblePositionManager} from "src/interfaces/INonfungiblePositionManager.sol";
import {TickBitmap} from "src/TickBitmap.sol";
import {TickMath} from "src/TickMath.sol";

/// @dev Base test class for all tests.
abstract contract BaseTest is Test {
    IUniswapV3Factory internal constant factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    INonfungiblePositionManager internal constant npm =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal token0;
    address internal token1;
    uint24 internal constant fee = 3000;
    address internal pool;
    int24 internal tickSpacing;

    function setUp() public virtual {}

    function createFork() internal {
        vm.createSelectFork("mainnet", 17000000);
        pool = factory.getPool(WETH, USDC, fee);
        tickSpacing = IUniswapV3Pool(pool).tickSpacing();
        token0 = IUniswapV3Pool(pool).token0();
        token1 = IUniswapV3Pool(pool).token1();
        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(address(npm), "NPM");
        vm.label(pool, "pool");
    }

    function currentTick() internal view returns (int24 tick) {
        (, tick, , , , , ) = IUniswapV3Pool(pool).slot0();
    }

    /// @dev Normalize tick to align with tick spacing
    function matchSpacing(int24 tick) internal view returns (int24) {
        int24 _tickSpacing = tickSpacing;
        return TickBitmap.compress(tick, _tickSpacing) * _tickSpacing;
    }

    function boundUint160(uint160 x) internal pure returns (uint160) {
        return uint160(bound(x, TickMath.MIN_SQRT_RATIO, TickMath.MAX_SQRT_RATIO));
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
