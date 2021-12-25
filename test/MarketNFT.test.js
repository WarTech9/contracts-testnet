// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");

let MarketNFT;
let nft;
let feeRecipient;
let tokenRecipient;

const mintFee = ethers.utils.parseUnits("0.1", "ether");
const tokenURI = "https://ipfs/token/myHash";
const metadataURI = "https://ipfs/metadata/myHash";

beforeEach(async function () {
  const signers = await ethers.getSigners();
  [feeRecipient, tokenRecipient] = [signers[0], signers[1]];
  MarketNFT = await ethers.getContractFactory("MarketNFT");
  nft = await MarketNFT.deploy(mintFee, feeRecipient.address, metadataURI, "Chedda NFT", "CNFT");
  await nft.deployed();
});

describe("MarketNFT", function () {
  it("Can mint", async function () {
    expect(await nft.totalSupply()).to.equal(0);

    await nft.mint(tokenRecipient.address, tokenURI, { value: mintFee });
    expect(await nft.totalSupply()).to.equal(1);
    await nft.connect(tokenRecipient).approve(feeRecipient.address, 1);
    expect(await nft.tokenURI(1)).to.equal(tokenURI);

    expect(await nft.ownerOf(1)).to.equal(tokenRecipient.address);
  });
  
  it("Can get an item", async function() {
    
  })
});
