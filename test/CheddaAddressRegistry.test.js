// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");

let CheddaAddressRegistry;
let registry;

beforeEach(async function () {
    const signers = await ethers.getSigners();
    [feeRecipient, tokenRecipient] = [signers[0], signers[1]];
    CheddaAddressRegistry = await ethers.getContractFactory("CheddaAddressRegistry");
    registry = await CheddaAddressRegistry.deploy();
});

describe("CheddaAddressRegistry", function () {
    it("Can update dappstore", async function () {
        let Dappstore = await ethers.getContractFactory("CheddaDappStore")
        let store = await Dappstore.deploy()
        await registry.setDappStore(store.address)
        let address = await registry.dappStore()
        expect(store.address).to.equal(address)
    });

    it("Can update Dapp Explorer", async function () {
        let Dappstore = await ethers.getContractFactory("CheddaDappStore")
        let store = await Dappstore.deploy()
        
        let CheddaDappExplorer = await ethers.getContractFactory("CheddaDappExplorer")
        let explorer = await CheddaDappExplorer.deploy()
        
        await registry.setDappStore(explorer.address)
        let address = await registry.dappStore()
        expect(explorer.address).to.equal(address)
    });


    it("Can update Market", async function () {
        let CheddaMarket = await ethers.getContractFactory("CheddaMarket")
        let market = await CheddaMarket.deploy()
        
        await registry.setMarket(market.address)
        const address = await registry.market()
        expect(market.address).to.equal(address)
    });


    it("Can update Market Explorer", async function () {
        let CheddaMarketExplorer = await ethers.getContractFactory("CheddaMarketExplorer")
        let explorer = await CheddaMarketExplorer.deploy()
        
        await registry.setMarketExplorer(explorer.address)
        let address = await registry.marketExplorer()
        expect(explorer.address).to.equal(address)
    });

});
