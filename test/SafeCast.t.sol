// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "src/SafeCast.sol";

contract SafeCastTest is Test {
    function testRevert_ToUint160() public {
        vm.expectRevert();
        SafeCast.toUint160(1 << 160);
    }

    function testToUint160(uint256 x) public {
        if (x <= type(uint160).max) {
            assertEq(uint256(SafeCast.toUint160(x)), x);
        } else {
            vm.expectRevert();
            SafeCast.toUint160(x);
        }
    }

    function testRevert_ToUint128() public {
        vm.expectRevert();
        SafeCast.toUint128(1 << 128);
    }

    function testToUint128(uint256 x) public {
        if (x <= type(uint128).max) {
            assertEq(uint256(SafeCast.toUint128(x)), x);
        } else {
            vm.expectRevert();
            SafeCast.toUint128(x);
        }
    }

    function testRevert_ToInt128() public {
        vm.expectRevert();
        SafeCast.toInt128(uint256(1 << 127));
        vm.expectRevert();
        SafeCast.toInt128(int256(1 << 127));
        vm.expectRevert();
        SafeCast.toInt128(-int256(1 << 127) - 1);
    }

    function testToInt128() public {
        assertEq(SafeCast.toInt128(uint256(int256(type(int128).max))), type(int128).max);
    }

    function testToInt128(uint256 x) public {
        if (x <= uint128(type(int128).max)) {
            assertEq(uint128(SafeCast.toInt128(x)), x);
        } else {
            vm.expectRevert();
            SafeCast.toInt128(x);
        }
    }

    function testToInt128(int256 x) public {
        if (x <= type(int128).max && x >= type(int128).min) {
            assertEq(int256(SafeCast.toInt128(x)), x);
        } else {
            vm.expectRevert();
            SafeCast.toInt128(x);
        }
    }

    function testRevert_ToInt256() public {
        vm.expectRevert();
        SafeCast.toInt256(1 << 255);
    }

    function testToInt256() public {
        assertEq(SafeCast.toInt256(uint256(type(int256).max)), type(int256).max);
    }

    function testToInt256(uint256 x) public {
        if (x <= uint256(type(int256).max)) {
            assertEq(uint256(SafeCast.toInt256(x)), x);
        } else {
            vm.expectRevert();
            SafeCast.toInt256(x);
        }
    }
}
