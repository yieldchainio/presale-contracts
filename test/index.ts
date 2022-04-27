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

    paidWithToken = await PaidWithToken.connect(addr3).deploy("Paid With Token", "PWT", 100_000_000, 18);

    presale = await Presale.deploy(addr1.address, addr2.address);

    await presale.deployed();

    await presale.setApprovedTokens([paidWithToken.address], [true]);
    await presale.setSaleOpen(true);


  });
  it("Should allow contributing", async () => {
    const amount = ethers.utils.parseEther("100");
    await paidWithToken.connect(addr3).approve(presale.address, amount);
    await presale.connect(addr3).contribute(paidWithToken.address, amount);

    await paidWithToken.connect(addr3).approve(presale.address, amount);
    await expect(
      presale.connect(addr3).contribute(addr1.address, amount)
    ).to.be.revertedWith('UnapprovedToken("0x70997970C51812dc3A010C7d01b50e0d17dc79C8")')

    const overMaxContrib = ethers.utils.parseEther("10000");
    await paidWithToken.connect(addr3).approve(presale.address, overMaxContrib);
    await expect(
      presale.connect(addr3).contribute(paidWithToken.address, overMaxContrib)
    ).to.be.revertedWith('OverMaxContribution()')

    const underMinContrib = ethers.utils.parseEther("5");
    await expect(
      presale.connect(addr3).contribute(paidWithToken.address, underMinContrib)
    ).to.be.revertedWith('UnderMinContribution()')

    await presale.setMaxContribution(0)

    const overHardCap = ethers.utils.parseEther("100000");
    await paidWithToken.connect(addr3).approve(presale.address, overHardCap);
    await expect(
      presale.connect(addr3).contribute(paidWithToken.address, overHardCap)
    ).to.be.revertedWith('OverHardCap('+amount.add(overHardCap)+')')

    await expect(
      presale.connect(addr3).contribute(paidWithToken.address, 0)
    ).to.be.revertedWith('AmountZero()')
  });

  it("Should allow withdrawal", async () => {
    await paidWithToken.connect(addr3).transfer(presale.address, ethers.utils.parseEther("100"));
    const preBalance = await paidWithToken.balanceOf(addr1.address);

    await presale.withdraw(paidWithToken.address);

    const postBalance = await paidWithToken.balanceOf(addr1.address)

    expect(
      preBalance.add(ethers.utils.parseEther("100"))
    ).to.be.equal(postBalance)
  });

  it("Should not allow to send ETH to contract", async () => {
    const tx = {
      to: presale.address,
      value: ethers.utils.parseEther("1")
    }

    await expect(
      owner.sendTransaction(tx)
    ).to.be.revertedWith("")
  })

  it("Should allow various decimals for the token", async () => {
    const token = await PaidWithToken.connect(addr3).deploy("Paid With Token", "PWT", 100_000_000, 6);

    await presale.setApprovedTokens([token.address], [true]);

    const amount = ethers.utils.parseUnits("100", 6);
    await token.connect(addr3).approve(presale.address, amount);
    await presale.connect(addr3).contribute(token.address, amount);

    const contributed = await presale.contributed();

    expect(
      contributed
    ).to.be.equal(ethers.utils.parseEther("100"))


  })
});
