# Uni V3 Lib

[![Lint](https://github.com/Aperture-Finance/uni-v3-lib/actions/workflows/lint.yml/badge.svg)](https://github.com/Aperture-Finance/uni-v3-lib/actions/workflows/lint.yml)
[![Test](https://github.com/Aperture-Finance/uni-v3-lib/actions/workflows/test.yml/badge.svg)](https://github.com/Aperture-Finance/uni-v3-lib/actions/workflows/test.yml)
[![npm version](https://img.shields.io/npm/v/@aperture_finance/uni-v3-lib/latest.svg)](https://www.npmjs.com/package/@aperture_finance/uni-v3-lib/v/latest)

The `uni-v3-lib` by Aperture Finance consists of a suite of Solidity libraries that have been imported and rewritten
from Uniswap's [v3-core](https://github.com/Uniswap/v3-core) and [v3-periphery](https://github.com/Uniswap/v3-periphery)
repositories. This project aims to equip external integrators with a set of libraries crucial for interaction with the
Uniswap V3 protocol.

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
| BitMath       | testGas_LSB                | 291088   | 193393    | 33.56%         |
| BitMath       | testGas_MSB                | 274437   | 213472    | 22.21%         |
| SqrtPriceMath | testGas_GetAmount0Delta    | 280254   | 256572    | 8.45%          |
| SqrtPriceMath | testGas_GetAmount1Delta    | 268385   | 209212    | 22.05%         |
| SwapMath      | testGas_ComputeSwapStep    | 526558   | 386504    | 26.60%         |
| TickMath      | testGas_GetSqrtRatioAtTick | 168547   | 146478    | 13.09%         |
| TickMath      | testGas_GetTickAtSqrtRatio | 307790   | 252577    | 17.94%         |

*The gas measured is the total gas used by the test transaction, including the gas used to call the test wrapper
contract. The actual percentage difference in gas for the internal library functions is higher than the numbers shown
above.*

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
SafeCast — "Library for safely casting between types"
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

1. The original Uniswap libraries are exposed by test wrapper contracts in `src/test` and compiled using the Solidity
   0.7.6 compiler.
2. We use the Forge cheatcode `deployCode` to create these test wrappers using the bytecode from the artifacts.
3. We verify the equivalence between the modified libraries and the original ones using Foundry's fuzz testing.
4. The effectiveness of optimizations can be assessed by tests prefixed by `testGas` in the gas snapshot.

To run the tests:

```shell
forge test
```

## Inline Assembly 

The libraries in this repository make use of [in-line assembly](https://docs.soliditylang.org/en/latest/assembly.html) for fine-grained control and optimizations. Knowledge of ABI encoding is required to understand how to calculate calldata length and parameter offsets. Helpful links:

- [ABI Specification](https://docs.soliditylang.org/en/latest/abi-spec.html#formal-specification-of-the-encoding)
- [HashEx Online ABI Encoder Tool](https://abi.hashex.org)
- [Solidity Memory Layout](https://docs.soliditylang.org/en/latest/internals/layout_in_memory.html)

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
