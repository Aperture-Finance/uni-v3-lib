// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IPoolAddressWrapper} from "src/test/interfaces/IPoolAddressWrapper.sol";
import {PoolAddress} from "src/PoolAddress.sol";

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
contract PoolAddressTest is Test {
    address constant factory = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    // Wrapper that exposes the original PoolAddress library.
    IPoolAddressWrapper wrapper = IPoolAddressWrapper(makeAddr("wrapper"));
    PoolAddressCallable caller;

    /// @dev Deploy a test wrapper with `name` to `lib` using `vm.etch`.
    function makeOriginalLibrary(address lib, string memory name) internal {
        string memory file = string.concat(
            vm.projectRoot(),
            "/artifacts/src/test/",
            name,
            ".sol/",
            name,
            ".json"
        );
        bytes memory deployedBytecode = vm.parseJsonBytes(
            vm.readFile(file),
            ".deployedBytecode"
        );
        vm.etch(lib, deployedBytecode);
    }

    function setUp() public {
        caller = new PoolAddressCallable();
        makeOriginalLibrary(address(wrapper), "PoolAddressWrapper");
    }

    function testFuzz_ComputeAddress(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        assertEq(
            PoolAddress.computeAddress(factory, tokenA, tokenB, fee),
            wrapper.computeAddress(
                factory,
                wrapper.getPoolKey(tokenA, tokenB, fee)
            )
        );
    }

    function testFuzz_ComputeAddressFromKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        assertEq(
            PoolAddress.computeAddress(
                factory,
                PoolAddress.getPoolKey(tokenA, tokenB, fee)
            ),
            wrapper.computeAddress(
                factory,
                wrapper.getPoolKey(tokenA, tokenB, fee)
            )
        );
    }

    function testFuzz_computeAddressCalldata(
        address tokenA,
        address tokenB,
        uint24 fee
    ) public {
        vm.assume(tokenA != tokenB);
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        assertEq(
            caller.computeAddressCalldata(
                factory,
                abi.encode(PoolAddress.getPoolKey(tokenA, tokenB, fee))
            ),
            wrapper.computeAddress(
                factory,
                wrapper.getPoolKey(tokenA, tokenB, fee)
            )
        );
    }
}
