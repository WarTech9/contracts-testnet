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

    CheddaAddressRegistry = await ethers.getContractFactory("CheddaAddressRegistry");
    registry = await CheddaAddressRegistry.deploy();

    const CheddaXP = await ethers.getContractFactory("CheddaXP");
    xp = await CheddaXP.deploy();
    await xp.updateRegistry(registry.address)

    CheddaRewards = await ethers.getContractFactory("CheddaRewards");
    rewards = await CheddaRewards.deploy();
    await rewards.updateRegistry(registry.address)

    await registry.setRewards(rewards.address)
    await registry.setCheddaXP(xp.address)

    console.log(`CheddaXP Deployed to ${xp.address}, rewards: ${rewards.address}`)
});

describe("CheddaRewards", function () {
    it("Can issue rewards", async function () {
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

    it("Can load leaderboard", async function() {
        let board = await rewards.leaderboard()
        let addresses = [
            {address: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",reward: 1},
            {address: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",reward: 1},
            {address: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",reward: 1},
            {address: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",reward: 1},
            {address: "0x15d34aaf54267db7d7c367839aaf71a00a2c6a65",reward: 5},
            {address: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",reward: 1},
            {address: "0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc",reward: 1},
            {address: "0x976ea74026e726554db657fa54763abd0c3a0aa9",reward: 1},
            {address: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",reward: 1},
            {address: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",reward: 3},
            {address: "0x90f79bf6eb2c4f870365e785982e1f101e93b906",reward: 4},
            {address: "0x90f79bf6eb2c4f870365e785982e1f101e93b906",reward: 4},
            {address: "0x90f79bf6eb2c4f870365e785982e1f101e93b906",reward: 4},
            {address: "0x90f79bf6eb2c4f870365e785982e1f101e93b906",reward: 4},
            {address: "0x90f79bf6eb2c4f870365e785982e1f101e93b906",reward: 4},
        ]
        console.log('board = ', board)
        for (const address of addresses) {
            await rewards.issueRewards(address.reward, address.address)
        }
        board = await rewards.leaderboard()
        console.log('board = ', board)
    })
});
