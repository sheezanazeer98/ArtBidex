import { HardhatUserConfig } from "hardhat/config";
import "@typechain/hardhat";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.28",
    typechain: {
    outDir: "typechain-types",
    target: "ethers-v6",
  },
};

export default config;
