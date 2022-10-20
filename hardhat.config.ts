import { HardhatUserConfig, task } from "hardhat/config";

// import "@nomicfoundation/hardhat-toolbox";
import "@typechain/hardhat";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import '@openzeppelin/hardhat-upgrades';
// import "hardhat-typechain";
import "hardhat-deploy";

import dotenv from 'dotenv';

dotenv.config();

const lazyImport = async (module: any) => {
  return await import(module);
};

task('deploy', 'Builds and deploys the contract on the selected network', async () => {
  const { deploy } = await lazyImport('./scripts/deploy');
  await deploy();
});

const config: HardhatUserConfig = {
  solidity: "0.8.9",
  defaultNetwork: "hardhat",
};

export default config;
