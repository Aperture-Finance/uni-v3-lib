// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

interface IFullMath {
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result);

    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) external pure returns (uint256 result);
}
