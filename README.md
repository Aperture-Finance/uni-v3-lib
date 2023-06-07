# Uni V3 Lib

[![Lint](https://github.com/Aperture-Finance/uni-v3-lib/actions/workflows/lint.yml/badge.svg)](https://github.com/Aperture-Finance/uni-v3-lib/actions/workflows/lint.yml)
[![Test](https://github.com/Aperture-Finance/uni-v3-lib/actions/workflows/test.yml/badge.svg)](https://github.com/Aperture-Finance/uni-v3-lib/actions/workflows/test.yml)

The `uni-v3-lib` by Aperture Finance is a suite of Solidity libraries that have been imported and rewritten from
Uniswap's [v3-core](https://github.com/Uniswap/v3-core) and [v3-periphery](https://github.com/Uniswap/v3-periphery)
repositories. The goal of this project is to provide external integrators with a set of libraries that are crucial for
interaction with the Uniswap V3 protocol.

## Overview

This repository focuses on certain libraries from Uniswap's repositories that are considered to be most useful for
external integrators, e.g. `SqrtPriceMath` and `TickMath`. We have modified these libraries to make them compatible with
modern Solidity compilers (versions greater than 0.8.0). Instead of simply changing the pragma and accepting the default
safe math behavior, most functions have been optimized using inline assembly for less gas. Additional
libraries `PoolCaller` and `NPMCaller` have been added to interact with the Uniswap V3 protocol more efficiently by
omitting the `extcodesize` check and manipulating the stack and memory directly. Additional helpers,
like `nextInitializedTick` which searches for the next initialized tick beyond one word, are also included. Optimization
heuristics and techniques are documented by extensive annotations in the source code.

**Gas Usage Comparison**

| Library       | Test                       | Original | Optimized | Gas Efficiency |
|---------------|----------------------------|----------|-----------|----------------|
| BitMath       | testGas_LSB                | 303324   | 211488    | 30.26%         |
| BitMath       | testGas_MSB                | 286673   | 229272    | 20.00%         |
| SqrtPriceMath | testGas_GetAmount0Delta    | 285432   | 266947    | 6.47%          |
| SqrtPriceMath | testGas_GetAmount1Delta    | 273563   | 219187    | 19.88%         |
| SwapMath      | testGas_ComputeSwapStep    | 531437   | 430173    | 19.03%         |
| TickMath      | testGas_GetSqrtRatioAtTick | 168533   | 147560    | 12.45%         |
| TickMath      | testGas_GetTickAtSqrtRatio | 307781   | 260917    | 15.24%         |

The gas measured is the total gas used by the test transaction, including the gas used to call the test wrapper
contract. The actual percentage difference in gas for the internal library functions is higher than the numbers shown
above.

## Libraries

The following libraries are included:

```ml
BitMath — "Functionality for computing bit properties of an unsigned integer"
CallbackValidation — "Provides validation for callbacks from Uniswap V3 Pools"
FullMath — "Contains 512-bit math functions"
LiquidityAmounts — "Provides functions for computing liquidity amounts from token amounts and prices"
LiquidityMath — "Math library for adding a signed liquidity delta to liquidity"
NPMCaller — "Gas efficient library to call `INonfungiblePositionManager` assuming it exists"
PoolAddress — "Provides functions for deriving a pool address from the factory, tokens, and the fee"
PoolCaller — "Gas efficient library to call `IUniswapV3Pool` assuming the pool exists"
SqrtPriceMath — "Functions based on Q64.96 sqrt price and liquidity"
SwapMath — "Computes the result of a swap within ticks"
TernaryLib — "Library for efficient ternary operations"
TickBitmap — "Packed tick initialized state library"
TickMath — "Math library for computing sqrt prices from ticks and vice versa"
UnsafeMath — "Math functions that do not check inputs or outputs"
```

## Installation

We've utilized [Foundry](https://github.com/foundry-rs/foundry) as our testing framework. Please follow the Foundry's
installation instructions if you want to run the tests. Otherwise, you can simply install the dependencies using Yarn:

```shell
yarn install
```

## Testing

The libraries in this repository have undergone rigorous fuzz testing using Foundry to ensure that they are equivalent
to the original libraries and that the optimizations have been effective. For testing against the exact same bytecode
compiled with Solidity 0.7.6, we adopt the following approach:

1. The original Uniswap libraries are exposed by test wrapper contracts in `src/test` and compiled with Hardhat using
   the Solidity 0.7.6 compiler.
2. We use the Forge cheatcode `vm.etch` to create these test wrappers using the bytecode from the Hardhat artifacts.
3. We verify the equivalence between the modified libraries and the original ones using Foundry's fuzz testing.
4. The effectiveness of optimizations can be assessed by tests prefixed by `testGas` in the gas snapshot.

To run the tests, first compile the original Uniswap libraries using Hardhat:

```shell
yarn hardhat compile
forge test
```

## Contributions

Contributions are welcome. Please ensure that any modifications pass all tests before submitting a pull request.

## Acknowledgements

This repository is either inspired by or directly modified from:

- [Uniswap V3](https://github.com/Uniswap/v3-core)
- [Uniswap V3 Periphery](https://github.com/Uniswap/v3-periphery)
- [Solmate](https://github.com/transmissions11/solmate)
- [Solady](https://github.com/Vectorized/solady)

## Disclaimer

The `uni-v3-lib` is experimental software and is provided on an "as is" and "as available" basis. Aperture Finance does
not offer any warranties and will not be responsible for any loss incurred through any use of this library.

While `uni-v3-lib` has undergone extensive testing, it may still have parts that could exhibit unexpected behavior when
used in conjunction with other code or might not operate correctly in future versions of Solidity.

Users are strongly urged to conduct their own comprehensive tests when incorporating `uni-v3-lib` into their projects to
ensure its correct operation within their specific code context. Use of this library is at the user's own risk.

## License

This project is licensed under the terms of the GNU General Public License v2.0 (GPL-2.0).
