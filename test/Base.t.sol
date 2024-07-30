// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPancakeV3Factory} from "@pancakeswap/v3-core/contracts/interfaces/IPancakeV3Factory.sol";
import {IPancakeV3Pool} from "@pancakeswap/v3-core/contracts/interfaces/IPancakeV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {TickBitmap} from "src/TickBitmap.sol";
import {TickMath} from "src/TickMath.sol";
import {ICommonNonfungiblePositionManager} from "src/interfaces/ICommonNonfungiblePositionManager.sol";

// Partial interface for the SlipStream factory. SlipStream factory is named "CLFactory" and "CL" presumably stands for concentrated liquidity.
// https://github.com/velodrome-finance/slipstream/blob/main/contracts/core/interfaces/ICLFactory.sol
interface ISlipStreamCLFactory {
    /// @notice Returns the pool address for a given pair of tokens and a tick spacing, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param tickSpacing The tick spacing of the pool
    /// @return pool The pool address
    function getPool(address tokenA, address tokenB, int24 tickSpacing) external view returns (address pool);
}

interface ISlipStreamCLPool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            bool unlocked
        );
}

/// @dev Base test class for all tests.
abstract contract BaseTest is Test {
    address internal factory;
    ICommonNonfungiblePositionManager internal npm;
    address internal WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal token0;
    address internal token1;
    uint24 internal fee;
    int24 internal tickSpacingSlipStream;
    address internal pool;
    int24 internal tickSpacing;
    // `dex` is used to determine which DEX to use for the test.
    // The default value is `UniswapV3` as that is the zero value.
    BaseTest.DEX internal dex;

    enum DEX {
        UniswapV3,
        PancakeSwapV3,
        SlipStream
    }

    function setUp() public virtual {}

    function createFork() internal {
        if (dex == DEX.UniswapV3) {
            vm.createSelectFork("mainnet", 17000000);
            WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
            factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
            npm = ICommonNonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
            fee = 3000;
            pool = IUniswapV3Factory(factory).getPool(WETH, USDC, fee);
        } else if (dex == DEX.PancakeSwapV3) {
            vm.createSelectFork("mainnet", 17000000);
            factory = 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865;
            WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
            npm = ICommonNonfungiblePositionManager(0x46A15B0b27311cedF172AB29E4f4766fbE7F4364);
            fee = 500;
            pool = IPancakeV3Factory(factory).getPool(WETH, USDC, fee);
        } else {
            vm.createSelectFork("base", 17406959);
            factory = 0x5e7BB104d84c7CB9B682AaC2F3d509f5F406809A;
            npm = ICommonNonfungiblePositionManager(0x827922686190790b37229fd06084350E74485b72);
            WETH = 0x4200000000000000000000000000000000000006;
            USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
            tickSpacingSlipStream = 100;
            pool = ISlipStreamCLFactory(factory).getPool(WETH, USDC, tickSpacingSlipStream);
        }
        tickSpacing = IUniswapV3Pool(pool).tickSpacing();
        token0 = IUniswapV3Pool(pool).token0();
        token1 = IUniswapV3Pool(pool).token1();
        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(address(npm), "NPM");
        vm.label(pool, "pool");
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

    /// @dev Normalize tick to align with tick spacing
    function matchSpacing(int24 tick) internal view returns (int24) {
        int24 _tickSpacing = tickSpacing;
        return TickBitmap.compress(tick, _tickSpacing) * _tickSpacing;
    }

    function currentTick() internal view returns (int24 tick) {
        if (dex == DEX.UniswapV3) {
            (, tick, , , , , ) = IUniswapV3Pool(pool).slot0();
        } else if (dex == DEX.PancakeSwapV3) {
            (, tick, , , , , ) = IPancakeV3Pool(pool).slot0();
        } else {
            (, tick, , , , ) = ISlipStreamCLPool(pool).slot0();
        }
    }
}
