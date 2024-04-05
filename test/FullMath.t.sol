// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import {IFullMath} from "src/test/interfaces/IFullMath.sol";
import {FullMath} from "src/FullMath.sol";
import "./Base.t.sol";

/// @dev Tests for FullMath
contract FullMathTest is Test {
    // Wrapper that exposes the original FullMath library.
    IFullMath internal wrapper;

    function setUp() public {
        wrapper = IFullMath(deployCode("out/FullMathTest.sol/FullMathTest.json"));
    }

    /// @dev Helper function to assume that the `mulDiv` will not overflow.
    function assumeNoOverflow(uint256 a, uint256 b, uint256 denominator) internal pure {
        // Most significant 256 bits of the product.
        uint256 prod1;
        assembly {
            // Least significant 256 bits of the product.
            let prod0 := mul(a, b)
            let mm := mulmod(a, b, not(0))
            prod1 := sub(mm, add(prod0, lt(mm, prod0)))
        }
        vm.assume(denominator > prod1);
    }

    /// @notice Test `mulDiv` against the original Uniswap library.
    function testFuzz_MulDiv_Og(uint256 a, uint256 b, uint256 denominator) public view {
        assumeNoOverflow(a, b, denominator);
        assertEq(FullMath.mulDiv(a, b, denominator), wrapper.mulDiv(a, b, denominator));
    }

    /// @notice Test `mulDiv` against OpenZeppelin's.
    function testFuzz_MulDiv_OZ(uint256 a, uint256 b, uint256 denominator) public pure {
        assumeNoOverflow(a, b, denominator);
        assertEq(FullMath.mulDiv(a, b, denominator), Math.mulDiv(a, b, denominator));
    }

    /// @notice Test `mulDivRoundingUp` against the original Uniswap library.
    function testFuzz_MulDivUp_Og(uint256 a, uint256 b, uint256 denominator) public view {
        assumeNoOverflow(a, b, denominator);
        if (Math.mulDiv(a, b, denominator) < type(uint256).max) {
            assertEq(FullMath.mulDivRoundingUp(a, b, denominator), wrapper.mulDivRoundingUp(a, b, denominator));
        }
    }

    /// @notice Test `mulDivRoundingUp` against OpenZeppelin's.
    function testFuzz_MulDivUp_OZ(uint256 a, uint256 b, uint256 denominator) public pure {
        assumeNoOverflow(a, b, denominator);
        if (Math.mulDiv(a, b, denominator) < type(uint256).max) {
            assertEq(FullMath.mulDivRoundingUp(a, b, denominator), Math.mulDiv(a, b, denominator, Math.Rounding.Ceil));
        }
    }

    /// @notice Test `mulDiv96` against `mulDiv` with a denominator of `Q96`.
    function testFuzz_MulDiv96(uint256 a, uint256 b) public pure {
        assumeNoOverflow(a, b, FixedPoint96.Q96);
        assertEq(FullMath.mulDiv96(a, b), Math.mulDiv(a, b, FixedPoint96.Q96));
    }

    /// @notice Test `sqrt` against OpenZeppelin's.
    function testFuzz_Sqrt(uint256 x) public pure {
        assertEq(FullMath.sqrt(x), Math.sqrt(x));
    }
}
