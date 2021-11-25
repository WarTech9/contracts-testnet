// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");

let CheddaMarket;
let market;
let CheddaNFT;
let nft;
let nft2;
let CheddaMarketExplorer;
let explorer;
let feeRecipient;
let tokenRecipient;
let tokenId = 1;

const mintFee = ethers.utils.parseUnits("0.1", "ether");
const price = ethers.utils.parseUnits("2.5", "ether");
const tokenURI = "https://ipfs/first/myHash/";
const tokenURI2 = "https://ipfs/second/myHash/";
const metadataURI = "https://ipfs/first/myHash";
const metadataURI2 = "https://ipfs/second/myHash";

beforeEach(async function () {
  const signers = await ethers.getSigners();
  [feeRecipient, tokenRecipient] = [signers[0], signers[1]];
  CheddaMarket = await ethers.getContractFactory("CheddaMarket");
  market = await CheddaMarket.deploy();
  await market.deployed();

  console.log('before deploy')
  CheddaNFT = await ethers.getContractFactory("CheddaNFT");
  nft = await CheddaNFT.deploy(mintFee, feeRecipient.address, "Chedda NFT", "CNFT", metadataURI);
  await nft.deployed();

  nft2 = await CheddaNFT.deploy(mintFee, feeRecipient.address, "Chedda NFT", "CNFT", metadataURI2);
  await nft2.deployed();

  CheddaMarketExplorer = await ethers.getContractFactory("CheddaMarketExplorer");
  explorer = await CheddaMarketExplorer.deploy();
  await explorer.deployed();

  await market.updateMarketExplorer(explorer.address);

  console.log('before mint')
  await nft.mint(tokenRecipient.address, tokenURI + '1', { value: mintFee });
  await nft.mint(tokenRecipient.address, tokenURI + '2', { value: mintFee });
  await nft.mint(tokenRecipient.address, tokenURI + '3', { value: mintFee });

  await nft2.mint(tokenRecipient.address, tokenURI2 + '1', { value: mintFee });
  await nft2.mint(tokenRecipient.address, tokenURI2 + '2', { value: mintFee });
  await nft2.mint(tokenRecipient.address, tokenURI2 + '3', { value: mintFee });
});

describe("CheddaMarket", function () {
  it("Can list item", async function () {
      console.log('about to approve')
    await nft.connect(tokenRecipient).approve(market.address, 1);
    await nft.connect(tokenRecipient).approve(market.address, 2);
    await nft.connect(tokenRecipient).approve(market.address, 3);
    await market
      .connect(tokenRecipient)
      .listItemForSale(nft.address, 1, price);

    await market
      .connect(tokenRecipient)
      .listItemForSale(nft.address, 2, price);

    await market
      .connect(tokenRecipient)
      .listItemForSale(nft.address, 3, price);

    await nft2.connect(tokenRecipient).approve(market.address, 1);
    await nft2.connect(tokenRecipient).approve(market.address, 2);
    await nft2.connect(tokenRecipient).approve(market.address, 3);
    await market
      .connect(tokenRecipient)
      .listItemForSale(nft2.address, 1, price);

    await market
      .connect(tokenRecipient)
      .listItemForSale(nft2.address, 2, price);

    await market
      .connect(tokenRecipient)
      .listItemForSale(nft2.address, 3, price);

    const itemsForSale = await market.itemsForSale(nft.address);
    console.log("itemsForSale = ", itemsForSale);
    let collections = await explorer.getCollections()
    console.log("Collections = ", collections)

    let allItems = await explorer.getAllItems();
    console.log('allItems = ', allItems)
    // expect(itemsForSale.length).to.equal(1);
  });

  it("Can buy item", async function () {
    await nft.connect(tokenRecipient).approve(market.address, tokenId);
    expect(await nft.ownerOf(tokenId)).to.equal(tokenRecipient.address);
    await market
      .connect(tokenRecipient)
      .listItemForSale(nft.address, tokenId, price);

    await market.buyItem(nft.address, tokenId, { value: price});
    expect(await nft.ownerOf(tokenId)).to.equal(feeRecipient.address);
  });

  it("Can get a market item", async function () {
    await nft.connect(tokenRecipient).approve(market.address, 1);
    await market
      .connect(tokenRecipient)
      .listItemForSale(nft.address, 1, price);
    let marketItem = await explorer.getMarketItem(nft.address, tokenId);
    
    expect(marketItem).to.not.be.null
    expect(marketItem.nftContract).to.equal(nft.address)
    console.log('market item = ', marketItem)
  })

  it("Can get a users owned items", async function() {
    await nft.connect(tokenRecipient).approve(market.address, 1);
    await nft.connect(tokenRecipient).approve(market.address, 2);
    await nft.connect(tokenRecipient).approve(market.address, 3);
    await market
      .connect(tokenRecipient)
      .listItemForSale(nft.address, 1, price);

    let itemsOwned = await explorer.getItemsOwned(tokenRecipient.address);
    console.log('items owned 1 = ', itemsOwned)
    expect(itemsOwned.length).to.equal(1)

    await market.buyItem(nft.address, 1, { value: price});
    itemsOwned = await explorer.getItemsOwned(tokenRecipient.address);
    console.log('items owned after buyItem = ', itemsOwned)
    expect(itemsOwned.length).to.equal(0)

    itemsOwned = await explorer.getItemsOwned(feeRecipient.address);
    console.log('items owned by buyer = ', itemsOwned)
    expect(itemsOwned.length).to.equal(1)
  })

//   it("Can buy item", async function () {});
});
