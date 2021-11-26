// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");

let CheddaRewards;
let rewards;
let registry
let feeRecipient;
let tokenRecipient;
let xp

beforeEach(async function () {
    const signers = await ethers.getSigners();
    [feeRecipient, tokenRecipient] = [signers[0], signers[1]];

    const CheddaXP = await ethers.getContractFactory("CheddaXP");
    xp = await CheddaXP.deploy();

    CheddaAddressRegistry = await ethers.getContractFactory("CheddaAddressRegistry");
    registry = await CheddaAddressRegistry.deploy();
    await registry.setCheddaXP(xp.address)

    CheddaRewards = await ethers.getContractFactory("CheddaRewards");
    rewards = await CheddaRewards.deploy(xp.address);
    registry.setRewards(rewards.address)

    await rewards.updateRegistry(registry.address)
    await xp.updateRegistry(registry.address)

    console.log(`CheddaXP Deployed to ${xp.address}, rewards: ${rewards.address}`)
});

describe("CheddaRewards", function () {
    it("Can update dappstore", async function () {
        let recipient = "0x1cbd3b2770909d4e10f157cabc84c7264073c9ec"

        await rewards.issueRewards(1, recipient)
        let rewardsForAction = await rewards.pointsPerAction(1)

        console.log('rewardsForAction = ', rewardsForAction)
        let balance = await xp.balanceOf(recipient)
        let totalSupply = await xp.totalSupply()

        expect(balance.toString()).to.equal(rewardsForAction.toString())

        console.log('balance is ', balance)
        console.log('totalSupply is ', totalSupply)
    });
});
