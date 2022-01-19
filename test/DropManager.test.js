// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const moment = require("moment");

let manager;
let feeRecipient;
let tokenRecipient;

const metadataURI = "https://ipfs/metadata/myHash";
const tokenAddress = '0x942940777Bd572789d72C8EcfA41f211F290167C'

beforeEach(async function () {
  const signers = await ethers.getSigners();
  [feeRecipient, tokenRecipient] = [signers[0], signers[1]];
  const CheddaDropManager = await ethers.getContractFactory("CheddaDropManager");
  manager = await CheddaDropManager.deploy();
});

describe("CheddaDropManager", function () {
  it("Can create Drop", async function () {
      const start = moment().unix()
      const end = moment().add(1, 'days').unix()
      await manager.createDrop(start, end, tokenAddress, metadataURI);
      const drops = await manager.getDrops()
      console.log('drops = ', drops)


    //   await drop.enter()
    //   let entries = await drop.getEntries()
    //   expect(entries.length).to.equal(1)
    //   await drop.connect(tokenRecipient).enter()
    //   entries = await drop.getEntries()
    //   console.log('entries = ', entries)
    //   expect(entries.length).to.equal(2)
  });

});
