const { ethers, upgrades } = require("hardhat");

async function main() {
  // Deploying
  const Lottery = await ethers.getContractFactory("Lottery");
  const instance = await upgrades.deployProxy(Lottery, [42]);
  await instance.deployed();

  // Upgrading
  // const TicketV2 = await ethers.getContractFactory("LotteryV2");
  // const upgraded = await upgrades.upgradeProxy(instance.address, TicketV2);
}

main();