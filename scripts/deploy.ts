import { ethers, deployments, upgrades } from "hardhat";

export async function deploy() {
  const salt = process.env.SALT || ethers.utils.formatBytes32String("salt");

  const [deployer] = await ethers.getSigners();

  const Ticket = await deployments.deploy("Ticket", {from: deployer.address, deterministicDeployment: salt})
  console.log("Ticket deployed to:", Ticket.address);
  // Deploying
  const LotteryFactory = await ethers.getContractFactory("Lottery");
  const Lottery = await upgrades.deployProxy(LotteryFactory, [salt, Ticket.address]);
  await Lottery.deployed();

  console.log("Lottery deployed to:", Lottery.address);
  // console.log(Lottery);
  // return Lottery;

  // Upgrading
  // const LotteryV2 = await ethers.getContractFactory("LotteryV2");
  // const upgraded = await upgrades.upgradeProxy(instance.address, LotterytV2);
}