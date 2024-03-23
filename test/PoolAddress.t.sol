// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolAddress} from "src/test/interfaces/IPoolAddress.sol";
import {CallbackValidation} from "src/CallbackValidation.sol";
import {CallbackValidationPancakeSwapV3} from "src/CallbackValidationPancakeSwapV3.sol";
import {PoolAddress, PoolKey} from "src/PoolAddress.sol";
import {PoolAddressPancakeSwapV3} from "src/PoolAddressPancakeSwapV3.sol";
import "./Base.t.sol";

interface IPoolAddressWrapper is IPoolAddress {
    function computeAddress(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) external pure returns (address pool);

    function computeAddressCalldata(address factory, bytes calldata key) external pure returns (address);

    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    function verifyCallback(address factory, PoolKey memory poolKey) external view returns (address pool);

    function verifyCallbackCalldata(address factory, bytes calldata poolKey) external view returns (address pool);
}

/// @dev Expose internal functions to test the PoolAddress library.
contract PoolAddressWrapper is IPoolAddressWrapper {
    function getPoolKey(address tokenA, address tokenB, uint24 fee) external pure returns (PoolKey memory key) {
        key = PoolAddress.getPoolKey(tokenA, tokenB, fee);
    }

    function computeAddress(address factory, PoolKey memory key) external pure returns (address pool) {
        return PoolAddress.computeAddress(factory, key);
    }

    function computeAddress(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) external pure returns (address pool) {
        return PoolAddress.computeAddress(factory, tokenA, tokenB, fee);
    }

    function computeAddressCalldata(address factory, bytes calldata key) external pure returns (address) {
        return PoolAddress.computeAddressCalldata(factory, key);
    }

    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool) {
        return address(CallbackValidation.verifyCallback(factory, tokenA, tokenB, fee));
    }

    function verifyCallback(address factory, PoolKey memory poolKey) external view returns (address pool) {
        return address(CallbackValidation.verifyCallback(factory, poolKey));
    }

    function verifyCallbackCalldata(address factory, bytes calldata poolKey) external view returns (address pool) {
        return CallbackValidation.verifyCallbackCalldata(factory, poolKey);
    }
}

/// @dev Expose internal functions to test the PoolAddressPancakeSwapV3 library.
contract PoolAddressPancakeSwapV3Wrapper is IPoolAddressWrapper {
    function getPoolKey(address tokenA, address tokenB, uint24 fee) external pure returns (PoolKey memory key) {
        key = PoolAddressPancakeSwapV3.getPoolKey(tokenA, tokenB, fee);
    }

    function computeAddress(address deployer, PoolKey memory key) external pure returns (address pool) {
        return PoolAddressPancakeSwapV3.computeAddress(deployer, key);
    }

    function computeAddress(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) external pure returns (address pool) {
        return PoolAddressPancakeSwapV3.computeAddress(factory, tokenA, tokenB, fee);
    }

    function computeAddressCalldata(address deployer, bytes calldata key) external pure returns (address) {
        return PoolAddressPancakeSwapV3.computeAddressCalldata(deployer, key);
    }

    function verifyCallback(
        address deployer,
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool) {
        return address(CallbackValidationPancakeSwapV3.verifyCallback(deployer, tokenA, tokenB, fee));
    }

    function verifyCallback(address deployer, PoolKey memory poolKey) external view returns (address pool) {
        return address(CallbackValidationPancakeSwapV3.verifyCallback(deployer, poolKey));
    }

    function verifyCallbackCalldata(address deployer, bytes calldata poolKey) external view returns (address pool) {
        return CallbackValidationPancakeSwapV3.verifyCallbackCalldata(deployer, poolKey);
    }
}

/// @dev Test contract for CallbackValidation and PoolAddress.
contract PoolAddressTest is BaseTest {
    // Wrapper that exposes the original PoolAddress library.
    IPoolAddress internal ogWrapper;
    IPoolAddressWrapper internal wrapper;

    function setUp() public virtual override {
        factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
        ogWrapper = IPoolAddress(deployCode("PoolAddressTest.sol"));
        wrapper = new PoolAddressWrapper();
    }

    /// @notice Test `computeAddress` against the original Uniswap library.
    function testFuzz_ComputeAddress(address tokenA, address tokenB, uint24 fee) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        assertEq(
            wrapper.computeAddress(factory, tokenA, tokenB, fee),
            ogWrapper.computeAddress(factory, ogWrapper.getPoolKey(tokenA, tokenB, fee))
        );
    }

    /// @notice Benchmark the gas cost of `computeAddress`.
    function testGas_ComputeAddress() public view {
        wrapper.computeAddress(factory, wrapper.getPoolKey(WETH, USDC, fee));
    }

    /// @notice Benchmark the gas cost of `computeAddress` from the original library.
    function testGas_ComputeAddress_Og() public view {
        ogWrapper.computeAddress(factory, ogWrapper.getPoolKey(WETH, USDC, fee));
    }

    /// @notice Test `computeAddress` against the original Uniswap library.
    function testFuzz_ComputeAddressFromKey(address tokenA, address tokenB, uint24 fee) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        assertEq(
            wrapper.computeAddress(factory, wrapper.getPoolKey(tokenA, tokenB, fee)),
            ogWrapper.computeAddress(factory, ogWrapper.getPoolKey(tokenA, tokenB, fee))
        );
    }

    /// @notice Test `computeAddressCalldata` against other implementation.
    function testFuzz_ComputeAddressCalldata(address tokenA, address tokenB, uint24 fee) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        assertEq(
            wrapper.computeAddressCalldata(factory, abi.encode(wrapper.getPoolKey(tokenA, tokenB, fee))),
            wrapper.computeAddress(factory, tokenA, tokenB, fee)
        );
    }

    /// @notice Test `verifyCallback`.
    function testFuzz_VerifyCallback(address tokenA, address tokenB, uint24 fee) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        PoolKey memory key = wrapper.getPoolKey(tokenA, tokenB, fee);
        address pool = wrapper.computeAddress(factory, key);
        vm.startPrank(pool);
        wrapper.verifyCallback(factory, tokenA, tokenB, fee);
        wrapper.verifyCallback(factory, key);
    }

    /// @notice Test `verifyCallbackCalldata` against other implementation.
    function testFuzz_VerifyCallbackCalldata(address tokenA, address tokenB, uint24 fee) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        PoolKey memory key = wrapper.getPoolKey(tokenA, tokenB, fee);
        address pool = wrapper.computeAddress(factory, key);
        vm.prank(pool);
        wrapper.verifyCallbackCalldata(factory, abi.encode(key));
    }
}

contract PoolAddressPCSTest is PoolAddressTest {
    function setUp() public override {
        factory = 0x41ff9AA7e16B8B1a8a8dc4f0eFacd93D02d071c9;
        ogWrapper = IPoolAddress(deployCode("PoolAddressPancakeSwapV3Test.sol"));
        wrapper = new PoolAddressPancakeSwapV3Wrapper();
    }
}
