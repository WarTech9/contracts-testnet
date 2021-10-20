// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");

let CheddaNFT;
let nft;
let feeRecipient;
let tokenRecipient;

const mintFee = ethers.utils.parseUnits("0.1", "ether");
const tokenURI = "https://ipfs/myHash";

beforeEach(async function () {
  const signers = await ethers.getSigners();
  [feeRecipient, tokenRecipient] = [signers[0].address, signers[1].address];
  CheddaNFT = await ethers.getContractFactory("CheddaNFT");
  nft = await CheddaNFT.deploy(mintFee, feeRecipient);
  await nft.deployed();
});

describe("CheddaNFT", function () {
  it("Can mint", async function () {
    expect(await nft.totalSupply()).to.equal(0);

    await nft.mint(tokenRecipient, tokenURI, { value: mintFee });
    expect(await nft.totalSupply()).to.equal(1);

    expect(await nft.tokenURI(1)).to.equal(tokenURI);

    expect(await nft.ownerOf(1)).to.equal(tokenRecipient);
  });
});
