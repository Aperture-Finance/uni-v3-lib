import "@nomicfoundation/hardhat-foundry";
import { HardhatUserConfig } from "hardhat/config";
import { SolidityUserConfig } from "hardhat/types/config";

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2 ** 32 - 1,
          },
          metadata: {
            bytecodeHash: 'none',
          },
        },
      },
      {
        version: "0.7.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 2 ** 32 - 1,
          },
          metadata: {
            bytecodeHash: 'none',
          },
        },
      },
    ],
  } as SolidityUserConfig,
};

export default config;
