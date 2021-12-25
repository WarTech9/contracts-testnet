// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");

let CheddaMarket;
let market;
let explorer;
let registry;
let MarketNFT;
let nft;
let feeRecipient;
let tokenRecipient;
let tokenId = 1;

const mintFee = ethers.utils.parseUnits("0.1", "ether");
const price = ethers.utils.parseUnits("2.5", "ether");
const tokenURI = "https://ipfs/token/myHash";
const metadataURI = "https://ipfs/token/myHash";

beforeEach(async function () {
  const signers = await ethers.getSigners();
  [feeRecipient, tokenRecipient] = [signers[0], signers[1]];

  CheddaAddressRegistry = await ethers.getContractFactory("CheddaAddressRegistry");
  registry = await CheddaAddressRegistry.deploy()

  CheddaMarket = await ethers.getContractFactory("CheddaMarket");
  market = await CheddaMarket.deploy();
  await market.deployed();
  await market.updateRegistry(registry.address)
  await registry.setMarket(market.address)

  MarketNFT = await ethers.getContractFactory("MarketNFT");
  nft = await MarketNFT.deploy(mintFee, feeRecipient.address, "Chedda NFT", "CNFT", metadataURI);
  await nft.deployed();

  CheddaMarketExplorer = await ethers.getContractFactory("CheddaMarketExplorer");
  explorer = await CheddaMarketExplorer.deploy();
  await explorer.deployed();
  await registry.setMarketExplorer(explorer.address)
  await explorer.updateRegistry(registry.address)

  let tx = await nft.mint(tokenRecipient.address, tokenURI, { value: mintFee });
  console.log("tx = ", tx);
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
