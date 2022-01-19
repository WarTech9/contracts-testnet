// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const moment = require("moment");

let drop;
let feeRecipient;
let tokenRecipient;

const mintFee = ethers.utils.parseUnits("0.1", "ether");
const tokenURI = "https://ipfs/token/myHash";
const metadataURI = "https://ipfs/metadata/myHash";
const tokenAddress = '0x942940777Bd572789d72C8EcfA41f211F290167C'

beforeEach(async function () {
  const signers = await ethers.getSigners();
  [feeRecipient, tokenRecipient] = [signers[0], signers[1]];
  const NFTWhitelistDrop = await ethers.getContractFactory("NFTWhitelistDrop");
  const start = moment().unix()
  const end = moment().add(1, 'days').unix()
  drop = await NFTWhitelistDrop.deploy(start, end, tokenAddress, metadataURI);
});

describe("MarketNFT", function () {
  it("Can enter", async function () {
      await drop.enter()
      let entries = await drop.getEntries()
      console.log('entries = ', entries)
      expect(entries.length).to.equal(1)
      await drop.connect(tokenRecipient).enter()
      entries = await drop.getEntries()
      expect(entries.length).to.equal(2)
  });

});
