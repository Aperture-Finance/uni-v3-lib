// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolAddress} from "src/test/interfaces/IPoolAddress.sol";
import {PoolAddress} from "src/PoolAddress.sol";
import "./Base.t.sol";

/// @dev Expose internal functions to test the PoolAddress library.
contract PoolAddressCallable {
    function computeAddressCalldata(
        address factory,
        bytes calldata key
    ) external pure returns (address) {
        return PoolAddress.computeAddressCalldata(factory, key);
    }
}

/// @dev Test pool address computed using assembly against the original PoolAddress library.
contract PoolAddressTest is BaseTest {
    // Wrapper that exposes the original PoolAddress library.
    IPoolAddress internal wrapper = IPoolAddress(makeAddr("wrapper"));
    PoolAddressCallable internal caller;

    function setUp() public override {
        caller = new PoolAddressCallable();
        makeOriginalLibrary(address(wrapper), "PoolAddressTest");
    }

    /// @notice Test `computeAddress` against the original Uniswap library.
    function testFuzz_ComputeAddress(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        assertEq(
            PoolAddress.computeAddress(address(factory), tokenA, tokenB, fee),
            wrapper.computeAddress(
                address(factory),
                wrapper.getPoolKey(tokenA, tokenB, fee)
            )
        );
    }

    /// @notice Test `computeAddress` against the original Uniswap library.
    function testFuzz_ComputeAddressFromKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        assertEq(
            PoolAddress.computeAddress(
                address(factory),
                PoolAddress.getPoolKey(tokenA, tokenB, fee)
            ),
            wrapper.computeAddress(
                address(factory),
                wrapper.getPoolKey(tokenA, tokenB, fee)
            )
        );
    }

    /// @notice Test `computeAddressCalldata` against other implementation.
    function testFuzz_computeAddressCalldata(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        assertEq(
            caller.computeAddressCalldata(
                address(factory),
                abi.encode(PoolAddress.getPoolKey(tokenA, tokenB, fee))
            ),
            PoolAddress.computeAddress(address(factory), tokenA, tokenB, fee)
        );
    }
}
