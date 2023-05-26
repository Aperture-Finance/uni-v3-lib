// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ILiquidityMath} from "src/test/interfaces/ILiquidityMath.sol";
import {LiquidityMath} from "src/LiquidityMath.sol";
import "./Base.t.sol";

contract LiquidityMathWrapper is ILiquidityMath {
    function addDelta(uint128 x, int128 y) external pure returns (uint128) {
        return LiquidityMath.addDelta(x, y);
    }
}

/// @dev Tests for FullMath
contract LiquidityMathTest is BaseTest {
    // Wrapper that exposes the original LiquidityMath library.
    ILiquidityMath internal ogWrapper = ILiquidityMath(makeAddr("original"));
    LiquidityMathWrapper internal wrapper;

    function setUp() public override {
        wrapper = new LiquidityMathWrapper();
        makeOriginalLibrary(address(ogWrapper), "LiquidityMathTest");
    }

    /// @notice Test the revert reason for underflow
    function testRevert_LS() public {
        vm.expectRevert(bytes("LS"));
        wrapper.addDelta(0, -1);
    }

    /// @notice Test the revert reason for overflow
    function testRevert_LA() public {
        vm.expectRevert(bytes("LA"));
        wrapper.addDelta(type(uint128).max, 1);
    }

    /// @notice Test the equivalence of the original and new `addDelta`
    function testFuzz_AddDelta(uint128 x, int128 y) public {
        try ogWrapper.addDelta(x, y) returns (uint128 z) {
            assertEq(z, LiquidityMath.addDelta(x, y));
        } catch Error(string memory reason) {
            vm.expectRevert(bytes(reason));
            wrapper.addDelta(x, y);
        }
    }

    /// @notice Benchmark the gas cost of `addDelta`
    function testGas_AddDelta() public view {
        uint128 x;
        int128 y;
        for (uint i; i < 100; ++i) {
            x = uint128(uint256(keccak256(abi.encodePacked(i))));
            y = int128(int256(uint256(keccak256(abi.encodePacked(i + 1)))));
            try wrapper.addDelta(x, y) {} catch {}
        }
    }

    /// @notice Benchmark the gas cost of the original `addDelta`
    function testGas_AddDelta_Og() public view {
        uint128 x;
        int128 y;
        for (uint i; i < 100; ++i) {
            x = uint128(uint256(keccak256(abi.encodePacked(i))));
            y = int128(int256(uint256(keccak256(abi.encodePacked(i + 1)))));
            try ogWrapper.addDelta(x, y) {} catch {}
        }
    }
}
