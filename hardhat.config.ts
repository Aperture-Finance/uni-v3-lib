import "@nomicfoundation/hardhat-foundry";
import { HardhatUserConfig } from "hardhat/config";
import { SolidityUserConfig } from "hardhat/types/config";

const DEFAULT_COMPILER_SETTINGS = {
  version: "0.8.18",
  settings: {
    optimizer: {
      enabled: true,
      runs: 2 ** 32 - 1,
    },
    metadata: {
      bytecodeHash: "none",
    },
  },
};

const OLD_COMPILER_SETTINGS = {
  version: "0.7.6",
  settings: {
    optimizer: {
      enabled: true,
      runs: 2 ** 32 - 1,
    },
    metadata: {
      bytecodeHash: "none",
    },
  },
};

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  solidity: {
    compilers: [DEFAULT_COMPILER_SETTINGS, OLD_COMPILER_SETTINGS],
    overrides: {
      "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol": OLD_COMPILER_SETTINGS,
    },
  } as SolidityUserConfig,
};

export default config;
