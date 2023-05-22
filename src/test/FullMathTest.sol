// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import {IFullMath} from "./interfaces/IFullMath.sol";

/// @dev Expose internal functions to test the FullMath library.
contract FullMathTest is IFullMath {
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure override returns (uint256 result) {
        return FullMath.mulDiv(a, b, denominator);
    }

    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure override returns (uint256 result) {
        return FullMath.mulDivRoundingUp(a, b, denominator);
    }
}
