// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolAddress} from "src/test/interfaces/IPoolAddress.sol";
import {CallbackValidation} from "src/CallbackValidation.sol";
import {PoolAddress, PoolKey} from "src/PoolAddress.sol";
import "./Base.t.sol";

/// @dev Expose internal functions to test the PoolAddress library.
contract PoolAddressValidator {
    function computeAddressCalldata(
        address factory,
        bytes calldata key
    ) external pure returns (address) {
        return PoolAddress.computeAddressCalldata(factory, key);
    }

    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool) {
        return
            address(
                CallbackValidation.verifyCallback(factory, tokenA, tokenB, fee)
            );
    }

    function verifyCallback(
        address factory,
        PoolKey memory poolKey
    ) external view returns (address pool) {
        return address(CallbackValidation.verifyCallback(factory, poolKey));
    }

    function verifyCallbackCalldata(
        address factory,
        bytes calldata poolKey
    ) external view returns (address pool) {
        return CallbackValidation.verifyCallbackCalldata(factory, poolKey);
    }
}

/// @dev Test contract for CallbackValidation and PoolAddress.
contract PoolAddressTest is BaseTest {
    // Wrapper that exposes the original PoolAddress library.
    IPoolAddress internal wrapper = IPoolAddress(makeAddr("original"));
    PoolAddressValidator internal validator;

    function setUp() public override {
        validator = new PoolAddressValidator();
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
    function testFuzz_ComputeAddressCalldata(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        assertEq(
            validator.computeAddressCalldata(
                address(factory),
                abi.encode(PoolAddress.getPoolKey(tokenA, tokenB, fee))
            ),
            PoolAddress.computeAddress(address(factory), tokenA, tokenB, fee)
        );
    }

    /// @notice Test `verifyCallback`.
    function testFuzz_VerifyCallback(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        PoolKey memory key = PoolAddress.getPoolKey(tokenA, tokenB, fee);
        address pool = PoolAddress.computeAddress(address(factory), key);
        vm.startPrank(pool);
        validator.verifyCallback(address(factory), tokenA, tokenB, fee);
        validator.verifyCallback(address(factory), key);
    }

    /// @notice Test `verifyCallbackCalldata` against other implementation.
    function testFuzz_VerifyCallbackCalldata(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        PoolKey memory key = PoolAddress.getPoolKey(tokenA, tokenB, fee);
        address pool = PoolAddress.computeAddress(address(factory), key);
        vm.prank(pool);
        validator.verifyCallbackCalldata(address(factory), abi.encode(key));
    }
}
