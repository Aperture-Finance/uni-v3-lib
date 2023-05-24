// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBitMath} from "src/test/interfaces/IBitMath.sol";
import {BitMath} from "src/BitMath.sol";
import "./Base.t.sol";

contract BitMathWrapper is IBitMath {
    function mostSignificantBit(uint256 x) external pure returns (uint8 r) {
        return BitMath.mostSignificantBit(x);
    }

    function leastSignificantBit(uint256 x) external pure returns (uint8 r) {
        return BitMath.leastSignificantBit(x);
    }
}

/// @title Test contract for BitMath
contract BitMathTest is BaseTest {
    // Wrapper that exposes the original BitMath library.
    IBitMath internal ogWrapper = IBitMath(makeAddr("wrapper"));
    BitMathWrapper internal wrapper;

    function setUp() public override {
        wrapper = new BitMathWrapper();
        makeOriginalLibrary(address(ogWrapper), "BitMathTest");
    }

    function testFuzz_MSB(uint256 x) public {
        x = bound(x, 1, type(uint256).max);
        assertEq(
            wrapper.mostSignificantBit(x),
            ogWrapper.mostSignificantBit(x)
        );
    }

    function testFuzz_LSB(uint256 x) public {
        x = bound(x, 1, type(uint256).max);
        assertEq(
            wrapper.leastSignificantBit(x),
            ogWrapper.leastSignificantBit(x)
        );
    }

    function testGas_MSB() public view {
        for (uint256 i = 1; i < 256; ++i) {
            wrapper.mostSignificantBit(1 << i);
        }
    }

    function testGas_MSB_Og() public view {
        for (uint256 i = 1; i < 256; ++i) {
            ogWrapper.mostSignificantBit(1 << i);
        }
    }

    function testGas_LSB() public view {
        for (uint256 i = 1; i < 256; ++i) {
            wrapper.leastSignificantBit(1 << i);
        }
    }

    function testGas_LSB_Og() public view {
        for (uint256 i = 1; i < 256; ++i) {
            ogWrapper.leastSignificantBit(1 << i);
        }
    }
}
