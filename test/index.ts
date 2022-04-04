import { expect } from "chai";
import { ethers } from "hardhat";

import { Presale } from "../typechain/Presale";
import { Presale__factory } from "../typechain/factories/Presale__factory"
import { ERC20 } from "../typechain/ERC20";

describe("Presale", function () {
  let PaidWithToken:any;
  let Presale:any;
  let paidWithToken:ERC20;
  let presale:Presale;

  let owner:any;
  let addr1:any;
  let addr2:any;
  let addr3:any;
  let addrs:any;

  const defaultBnbPrice = ethers.utils.parseUnits("375.9");

  beforeEach(async () => {
    [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
    PaidWithToken = await ethers.getContractFactory("TestToken");
    Presale = await ethers.getContractFactory("Presale");

    paidWithToken = await PaidWithToken.connect(addr3).deploy("Paid With Token", "PWT", 100_000_000);

    presale = await Presale.deploy(addr1.address, addr2.address);

    await presale.deployed();

    await presale.setApprovedTokens([paidWithToken.address], [true]);
    await presale.setState(true);


  });
  it("Should allow contributing", async () => {
    const amount = ethers.utils.parseEther("100");
    await paidWithToken.connect(addr3).approve(presale.address, amount);
    await presale.connect(addr3).contribute(paidWithToken.address, amount);
  });
});
