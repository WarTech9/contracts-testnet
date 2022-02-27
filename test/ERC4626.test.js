// const { expect } = require("chai");
const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
const { expectRevert } = require("@openzeppelin/test-helpers");

let token
let vault
let account0;
let account1;

beforeEach(async function () {
    const signers = await ethers.getSigners();
    [account0, account1] = [signers[0], signers[1]];


    const Token = await ethers.getContractFactory("Token");
    token = await Token.deploy("USD Coin", "USDC");

    const ERC4626 = await ethers.getContractFactory("CheddaBaseTokenVault");
    vault = await ERC4626.deploy(token.address, "ch" + await token.name(), await token.symbol());

});

describe("ERC4626", () => {
    it("can deposit", async () => {
        let assetsPerShare = await vault.assetsPerShare()
        console.log('assetsPerShare: ', assetsPerShare)

        const amount0 = ethers.utils.parseUnits("1200", "ether");
        const amount1 = ethers.utils.parseUnits("1300", "ether");

        await token.transfer(account1.address, amount1)

        await token.approve(vault.address, amount0)
        const tx0 = await vault.deposit(amount0, account0.address)
        await tx0.wait()

        await token.connect(account1).approve(vault.address, amount1)
        const tx1 = await vault.connect(account1).deposit(amount1, account1.address);
        await tx1.wait()


        let shares0 = await vault.balanceOf(account0.address)
        console.log('shares0 = ', shares0)

        let totalAssets = await vault.totalAssets()
        console.log("totalShares = ", totalAssets)

        let shares1 = await vault.balanceOf(account1.address)
        console.log('shares1 = ', shares1)

        totalAssets = await vault.totalAssets()
        console.log("totalShares = ", totalAssets)
    });
})