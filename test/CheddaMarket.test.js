// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");

let CheddaMarket;
let market;
let CheddaNFT;
let nft;
let feeRecipient;
let tokenRecipient;
let tokenId = 1;

const mintFee = ethers.utils.parseUnits("0.1", "ether");
const price = ethers.utils.parseUnits("2.5", "ether");
const tokenURI = "https://ipfs/myHash";

beforeEach(async function () {
  const signers = await ethers.getSigners();
  [feeRecipient, tokenRecipient] = [signers[0], signers[1]];
  CheddaMarket = await ethers.getContractFactory("CheddaMarket");
  market = await CheddaMarket.deploy();
  await market.deployed();

  CheddaNFT = await ethers.getContractFactory("CheddaNFT");
  nft = await CheddaNFT.deploy(mintFee, feeRecipient.address);
  await nft.deployed();

  await nft.mint(tokenRecipient.address, tokenURI, { value: mintFee });
  console.log("tokenId = ", tokenId);
});

describe("CheddaMarket", function () {
  it("Can list item", async function () {
    await nft.connect(tokenRecipient).approve(market.address, tokenId);
    await market
      .connect(tokenRecipient)
      .listItemForSale(nft.address, tokenId, price);
    const itemsForSale = await market.itemsForSale(nft.address);
    console.log("itemsForSale = ", itemsForSale);

    expect(itemsForSale.length).to.equal(1);
  });

  it("Can buy item", async function () {
    await nft.connect(tokenRecipient).approve(market.address, tokenId);
    expect(await nft.ownerOf(tokenId)).to.equal(tokenRecipient.address);
    await market
      .connect(tokenRecipient)
      .listItemForSale(nft.address, tokenId, price);

    await market.buyItem(nft.address, tokenId, { value: price });
    expect(await nft.ownerOf(tokenId)).to.equal(feeRecipient.address);
  });

//   it("Can buy item", async function () {});
});
