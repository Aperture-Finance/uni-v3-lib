// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {TernaryLib} from "src/TernaryLib.sol";

/// @dev Test contract for TernaryLib
contract TernaryLibTest is Test {
    function test_Ternary() public pure {
        assertEq(TernaryLib.ternary(true, 1, 2), 1);
        assertEq(TernaryLib.ternary(false, 1, 2), 2);
    }

    function testFuzz_Ternary(bool condition, uint256 a, uint256 b) public pure {
        if (condition) {
            assertEq(TernaryLib.ternary(condition, a, b), a);
        } else {
            assertEq(TernaryLib.ternary(condition, a, b), b);
        }
    }

    function testFuzz_Ternary(bool condition, address a, address b) public pure {
        if (condition) {
            assertEq(TernaryLib.ternary(condition, a, b), a);
        } else {
            assertEq(TernaryLib.ternary(condition, a, b), b);
        }
    }

    function test_Abs() public pure {
        assertEq(TernaryLib.abs(1), 1);
        assertEq(TernaryLib.abs(-1), 1);
        assertEq(TernaryLib.abs(type(int256).min), 1 << 255);
    }

    function testFuzz_Abs(int256 x) public pure {
        vm.assume(x != type(int256).min);
        if (x >= 0) {
            assertEq(TernaryLib.abs(x), uint256(x));
        } else {
            assertEq(TernaryLib.abs(x), uint256(-x));
        }
    }

    function test_AbsDiff() public pure {
        assertEq(TernaryLib.absDiff(1, 2), 1);
        assertEq(TernaryLib.absDiff(2, 1), 1);
    }

    function testFuzz_AbsDiff(uint256 a, uint256 b) public pure {
        if (a > b) {
            assertEq(TernaryLib.absDiff(a, b), a - b);
        } else {
            assertEq(TernaryLib.absDiff(a, b), b - a);
        }
    }

    function test_AbsDiffU160() public pure {
        assertEq(TernaryLib.absDiffU160(1, 2), 1);
        assertEq(TernaryLib.absDiffU160(2, 1), 1);
    }

    function testFuzz_AbsDiffU160(uint160 a, uint160 b) public pure {
        if (a > b) {
            assertEq(TernaryLib.absDiffU160(a, b), a - b);
        } else {
            assertEq(TernaryLib.absDiffU160(a, b), b - a);
        }
    }

    function test_Min() public pure {
        assertEq(TernaryLib.min(1, 2), 1);
        assertEq(TernaryLib.min(2, 1), 1);
    }

    function testFuzz_Min(uint256 a, uint256 b) public pure {
        if (a < b) {
            assertEq(TernaryLib.min(a, b), a);
        } else {
            assertEq(TernaryLib.min(a, b), b);
        }
    }

    function test_Max() public pure {
        assertEq(TernaryLib.max(1, 2), 2);
        assertEq(TernaryLib.max(2, 1), 2);
    }

    function testFuzz_Max(uint256 a, uint256 b) public pure {
        if (a > b) {
            assertEq(TernaryLib.max(a, b), a);
        } else {
            assertEq(TernaryLib.max(a, b), b);
        }
    }

    function test_SwitchIf() public pure {
        (uint256 a, uint256 b) = TernaryLib.switchIf(true, 1, 2);
        assertEq(a, 2);
        assertEq(b, 1);
    }

    function testFuzz_SwitchIf(bool condition, uint256 a, uint256 b) public pure {
        (uint256 x, uint256 y) = TernaryLib.switchIf(condition, a, b);
        if (condition) {
            assertEq(x, b);
            assertEq(y, a);
        } else {
            assertEq(x, a);
            assertEq(y, b);
        }
    }

    function test_Sort2() public pure {
        (uint256 a, uint256 b) = TernaryLib.sort2(1, 2);
        assertEq(a, 1);
        assertEq(b, 2);
        (a, b) = TernaryLib.sort2(2, 1);
        assertEq(a, 1);
        assertEq(b, 2);
    }

    function testFuzz_Sort2(uint256 a, uint256 b) public pure {
        (uint256 x, uint256 y) = TernaryLib.sort2(a, b);
        if (a < b) {
            assertEq(x, a);
            assertEq(y, b);
        } else {
            assertEq(x, b);
            assertEq(y, a);
        }
    }
}
