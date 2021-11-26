// const { expect } = require("chai");
const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

let xp
let rewards;
let feeRecipient;
let tokenRecipient;

beforeEach(async function () {
    const signers = await ethers.getSigners();
    [feeRecipient, tokenRecipient] = [signers[0], signers[1]];
    const CheddaXP = await ethers.getContractFactory("CheddaXP");
    xp = await CheddaXP.deploy();

    const CheddaRewards = await ethers.getContractFactory("CheddaRewards")
    rewards = await CheddaRewards.deploy(xp.address)

    const CheddaAddressRegistry = await ethers.getContractFactory("CheddaAddressRegistry")
    const registry = await CheddaAddressRegistry.deploy()
    await registry.setRewards(rewards.address)
    await xp.updateRegistry(registry.address)
});

describe("CheddaXP", function () {
    // can only test with onlyContract() modifiers disabled
    it("Can mint", async function () {

        let totalSupply = await xp.totalSupply()
        console.log('totalSupply = ', totalSupply)

        const amount = BigNumber.from(100)
        let tx = await xp.mint(amount.toString(), feeRecipient.address)
        await tx.wait()

        totalSupply = await xp.totalSupply()
        console.log('totalSupply = ', totalSupply)

        const balance = await xp.balanceOf(feeRecipient.address)
        console.log('balance = ', balance.toString())
        expect(amount.toString()).to.equal(totalSupply.toString())
        expect(totalSupply.toString()).to.equal(balance.toString())
    });

    it("Can burn", async function() {
        const amount = BigNumber.from(100)
        let tx = await xp.mint(amount.toString(), feeRecipient.address)
        await tx.wait()

        const burnAmount = BigNumber.from(50)
        tx = await xp.connect(feeRecipient).burn(burnAmount.toString())

        let totalSupply = await xp.totalSupply()
        const balance = await xp.balanceOf(feeRecipient.address)
        expect(balance.toString()).to.equal(totalSupply.toString())
        expect(burnAmount.toString()).to.equal(totalSupply.toString())
    });
});
