// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPancakeV3Factory} from "@pancakeswap/v3-core/contracts/interfaces/IPancakeV3Factory.sol";
import {IPancakeV3Pool} from "@pancakeswap/v3-core/contracts/interfaces/IPancakeV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {INonfungiblePositionManager} from "src/interfaces/INonfungiblePositionManager.sol";
import {TickBitmap} from "src/TickBitmap.sol";
import {TickMath} from "src/TickMath.sol";

/// @dev Base test class for all tests.
abstract contract BaseTest is Test {
    address internal factory;
    INonfungiblePositionManager internal npm;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal token0;
    address internal token1;
    uint24 internal fee;
    address internal pool;
    int24 internal tickSpacing;
    // `dex` is used to determine which DEX to use for the test.
    // The default value is `UniswapV3` as that is the zero value.
    BaseTest.DEX internal dex;

    enum DEX {
        UniswapV3,
        PancakeSwapV3
    }

    function setUp() public virtual {}

    function createFork() internal {
        vm.createSelectFork("mainnet", 17000000);
        if (dex == DEX.UniswapV3) {
            factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
            npm = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
            fee = 3000;
            pool = IUniswapV3Factory(factory).getPool(WETH, USDC, fee);
        } else {
            factory = 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865;
            npm = INonfungiblePositionManager(0x46A15B0b27311cedF172AB29E4f4766fbE7F4364);
            fee = 500;
            pool = IPancakeV3Factory(factory).getPool(WETH, USDC, fee);
        }
        tickSpacing = IUniswapV3Pool(pool).tickSpacing();
        token0 = IUniswapV3Pool(pool).token0();
        token1 = IUniswapV3Pool(pool).token1();
        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(address(npm), "NPM");
        vm.label(pool, "pool");
    }

    function boundUint160(uint160 x) internal view returns (uint160) {
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

    /// @dev Normalize tick to align with tick spacing
    function matchSpacing(int24 tick) internal view returns (int24) {
        int24 _tickSpacing = tickSpacing;
        return TickBitmap.compress(tick, _tickSpacing) * _tickSpacing;
    }

    function currentTick() internal view returns (int24 tick) {
        if (dex == DEX.UniswapV3) {
            (, tick, , , , , ) = IUniswapV3Pool(pool).slot0();
        } else {
            (, tick, , , , , ) = IPancakeV3Pool(pool).slot0();
        }
    }
}
