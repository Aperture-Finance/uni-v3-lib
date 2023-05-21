// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.4;

import "./SqrtPriceMath.sol";

/// @title Computes the result of a swap within ticks
/// @author Aperture Finance
/// @author Modified from Uniswap (https://github.com/uniswap/v3-core/blob/main/contracts/libraries/SwapMath.sol)
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
    uint256 internal constant MAX_FEE_PIPS = 1e6;

    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much input or output amount is remaining to be swapped in/out
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    /// @return feeAmount The amount of input that will be taken as a fee
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    )
        internal
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
        bool exactIn;
        uint256 amountRemainingAbs;
        assembly {
            // exactIn = 1 if amountRemaining >= 0 else 0
            exactIn := iszero(slt(amountRemaining, 0))
            // mask = 0 if amountRemaining >= 0 else -1
            let mask := sub(exactIn, 1)
            amountRemainingAbs := xor(mask, add(mask, amountRemaining))
        }

        if (exactIn) {
            uint256 amountRemainingLessFee = FullMath.mulDiv(
                amountRemainingAbs,
                UnsafeMath.sub(MAX_FEE_PIPS, feePips),
                MAX_FEE_PIPS
            );
            amountIn = zeroForOne
                ? SqrtPriceMath.getAmount0Delta(
                    sqrtRatioTargetX96,
                    sqrtRatioCurrentX96,
                    liquidity,
                    true
                )
                : SqrtPriceMath.getAmount1Delta(
                    sqrtRatioCurrentX96,
                    sqrtRatioTargetX96,
                    liquidity,
                    true
                );
            if (amountRemainingLessFee >= amountIn) {
                // `amountIn` is capped by the target price
                sqrtRatioNextX96 = sqrtRatioTargetX96;
            } else {
                // Exhaust the remaining amount
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    amountRemainingLessFee,
                    zeroForOne
                );
            }
        } else {
            amountOut = zeroForOne
                ? SqrtPriceMath.getAmount1Delta(
                    sqrtRatioTargetX96,
                    sqrtRatioCurrentX96,
                    liquidity,
                    false
                )
                : SqrtPriceMath.getAmount0Delta(
                    sqrtRatioCurrentX96,
                    sqrtRatioTargetX96,
                    liquidity,
                    false
                );
            if (amountRemainingAbs >= amountOut) {
                // `amountOut` is capped by the target price
                sqrtRatioNextX96 = sqrtRatioTargetX96;
            } else {
                // Exhaust the remaining amount
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    amountRemainingAbs,
                    zeroForOne
                );
            }
        }

        // Whether the target price is reached
        bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

        // get the input/output amounts
        if (zeroForOne) {
            // No need to recompute `amountIn` if `amountIn` is capped by the target price when `exactIn`
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount0Delta(
                    sqrtRatioNextX96,
                    sqrtRatioCurrentX96,
                    liquidity,
                    true
                );
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount1Delta(
                    sqrtRatioNextX96,
                    sqrtRatioCurrentX96,
                    liquidity,
                    false
                );
        } else {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount1Delta(
                    sqrtRatioCurrentX96,
                    sqrtRatioNextX96,
                    liquidity,
                    true
                );
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount0Delta(
                    sqrtRatioCurrentX96,
                    sqrtRatioNextX96,
                    liquidity,
                    false
                );
        }

        // cap the output amount to not exceed the remaining output amount
        if (!exactIn && amountOut > amountRemainingAbs) {
            amountOut = amountRemainingAbs;
        }

        if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
            // we didn't reach the target, so take the remainder of the maximum input as fee
            assembly {
                feeAmount := sub(amountRemainingAbs, amountIn)
            }
        } else {
            feeAmount = FullMath.mulDivRoundingUp(
                amountIn,
                feePips,
                UnsafeMath.sub(MAX_FEE_PIPS, feePips)
            );
        }
    }

    /// @notice Computes the result of swapping some amount in given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much input amount is remaining to be swapped in
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    function computeSwapStepExactIn(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        uint256 amountRemaining,
        uint256 feePips
    )
        internal
        pure
        returns (uint160 sqrtRatioNextX96, uint256 amountIn, uint256 amountOut)
    {
        bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
        uint256 feeComplement = UnsafeMath.sub(MAX_FEE_PIPS, feePips);

        uint256 amountRemainingLessFee = FullMath.mulDiv(
            amountRemaining,
            feeComplement,
            MAX_FEE_PIPS
        );
        amountIn = zeroForOne
            ? SqrtPriceMath.getAmount0Delta(
                sqrtRatioTargetX96,
                sqrtRatioCurrentX96,
                liquidity,
                true
            )
            : SqrtPriceMath.getAmount1Delta(
                sqrtRatioCurrentX96,
                sqrtRatioTargetX96,
                liquidity,
                true
            );
        if (amountRemainingLessFee >= amountIn) {
            // `amountIn` is capped by the target price
            sqrtRatioNextX96 = sqrtRatioTargetX96;
        } else {
            // Exhaust the remaining amount
            sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                sqrtRatioCurrentX96,
                liquidity,
                amountRemainingLessFee,
                zeroForOne
            );
        }

        // Just add the fee amount if `amountIn` is capped by the target price.
        // Otherwise all of `amountRemaining` is consumed.
        amountIn = sqrtRatioTargetX96 == sqrtRatioNextX96
            ? FullMath.mulDivRoundingUp(amountIn, MAX_FEE_PIPS, feeComplement)
            : amountRemaining;
        amountOut = zeroForOne
            ? SqrtPriceMath.getAmount1Delta(
                sqrtRatioNextX96,
                sqrtRatioCurrentX96,
                liquidity,
                false
            )
            : SqrtPriceMath.getAmount0Delta(
                sqrtRatioCurrentX96,
                sqrtRatioNextX96,
                liquidity,
                false
            );
    }
}
