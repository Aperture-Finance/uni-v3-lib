// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {BitMath as OgBitMath} from "@uniswap/v3-core/contracts/libraries/BitMath.sol";
import {BitMath} from "src/BitMath.sol";

/// @title Test contract for BitMath
contract BitMathTest is Test {
    function testFuzz_MSB(uint256 x) public {
        x = bound(x, 1, type(uint256).max);
        assertEq(
            BitMath.mostSignificantBit(x),
            OgBitMath.mostSignificantBit(x)
        );
    }

    function testFuzz_LSB(uint256 x) public {
        x = bound(x, 1, type(uint256).max);
        assertEq(
            BitMath.leastSignificantBit(x),
            OgBitMath.leastSignificantBit(x)
        );
    }

    function testGas_MSB() public pure {
        for (uint256 i = 1; i < 256; ++i) {
            BitMath.mostSignificantBit(1 << i);
        }
    }

    function testGas_MSB_Og() public pure {
        for (uint256 i = 1; i < 256; ++i) {
            OgBitMath.mostSignificantBit(1 << i);
        }
    }

    function testGas_LSB() public pure {
        for (uint256 i = 1; i < 256; ++i) {
            BitMath.leastSignificantBit(1 << i);
        }
    }

    function testGas_LSB_Og() public pure {
        for (uint256 i = 1; i < 256; ++i) {
            OgBitMath.leastSignificantBit(1 << i);
        }
    }
}
