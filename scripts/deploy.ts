// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { time } from "console";
import { ethers, run } from "hardhat";
import { hrtime } from "process";
import { Presale } from "../typechain/Presale";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Presale:any = await ethers.getContractFactory("Presale");
  const presale:Presale = await Presale.deploy(process.env.BENEFICIARY!, process.env.ORACLE!);

  await presale.deployed();
  await presale.setSaleOpen(true);

  console.log("Presale deployed to:", presale.address);

  const tokens = process.env.TOKENS!.split(",")
  await presale.setApprovedTokens(tokens, Array(tokens.length).fill(true))

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
