// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { time } from "console";
import { ethers, run } from "hardhat";
import { hrtime } from "process";
import { Presale } from "../typechain/Presale";
import { Presale__factory } from "../typechain/factories/Presale__factory";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const presale:Presale = await Presale__factory.connect(process.env.CONTRACT!,  await ethers.getSigner("0x7bF9b4bB202735608f0DFfb2cbCBB49aD7d49dbC"))

  await presale.setSaleOpen(process.env.STATE! == "true" ? true : false);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
