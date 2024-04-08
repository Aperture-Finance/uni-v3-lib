// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import "./FullMath.sol";
import "./SafeCast.sol";
import "./TernaryLib.sol";
import "./UnsafeMath.sol";

/// @title Liquidity amount functions
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-periphery/blob/main/contracts/libraries/LiquidityAmounts.sol)
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    using UnsafeMath for *;
    using SafeCast for uint256;

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        uint256 intermediate = FullMath.mulDivQ96(sqrtRatioAX96, sqrtRatioBX96);
        return FullMath.mulDiv(amount0, intermediate, TernaryLib.absDiffU160(sqrtRatioAX96, sqrtRatioBX96)).toUint128();
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the lower tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the upper tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0Sorted(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        unchecked {
            uint256 intermediate = FullMath.mulDivQ96(sqrtRatioAX96, sqrtRatioBX96);
            return FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96).toUint128();
        }
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        return
            FullMath
                .mulDiv(amount1, FixedPoint96.Q96, TernaryLib.absDiffU160(sqrtRatioAX96, sqrtRatioBX96))
                .toUint128();
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the lower tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the upper tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1Sorted(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        unchecked {
            return FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96).toUint128();
        }
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        (sqrtRatioAX96, sqrtRatioBX96) = TernaryLib.sort2U160(sqrtRatioAX96, sqrtRatioBX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0Sorted(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0Sorted(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1Sorted(sqrtRatioAX96, sqrtRatioX96, amount1);
            // liquidity = min(liquidity0, liquidity1);
            assembly {
                liquidity := xor(liquidity0, mul(xor(liquidity0, liquidity1), lt(liquidity1, liquidity0)))
            }
        } else {
            liquidity = getLiquidityForAmount1Sorted(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        unchecked {
            (sqrtRatioAX96, sqrtRatioBX96) = TernaryLib.sort2U160(sqrtRatioAX96, sqrtRatioBX96);
            return
                FullMath
                    .mulDiv(uint256(liquidity) << FixedPoint96.RESOLUTION, sqrtRatioBX96 - sqrtRatioAX96, sqrtRatioBX96)
                    .div(sqrtRatioAX96);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the lower tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the upper tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquiditySorted(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        unchecked {
            return
                FullMath
                    .mulDiv(uint256(liquidity) << FixedPoint96.RESOLUTION, sqrtRatioBX96 - sqrtRatioAX96, sqrtRatioBX96)
                    .div(sqrtRatioAX96);
        }
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        return FullMath.mulDivQ96(liquidity, TernaryLib.absDiffU160(sqrtRatioAX96, sqrtRatioBX96));
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the lower tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the upper tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquiditySorted(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        unchecked {
            return FullMath.mulDivQ96(liquidity, sqrtRatioBX96 - sqrtRatioAX96);
        }
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        (sqrtRatioAX96, sqrtRatioBX96) = TernaryLib.sort2U160(sqrtRatioAX96, sqrtRatioBX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquiditySorted(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 <= sqrtRatioBX96) {
            amount0 = getAmount0ForLiquiditySorted(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquiditySorted(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquiditySorted(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}
