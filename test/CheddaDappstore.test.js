// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");

let CheddaDappStore;
let dappStore;

const dappName = "My Awesome Dapp";
const dappNetwork = "Ethereum";
const dappChainId = 1;
const dappAddress = "0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec";
const dappUri = "https://app.myawesomedapp.com"
const dappCategory = "defi"

beforeEach(async function () {
  CheddaDappStore = await ethers.getContractFactory("CheddaDappStore");
  dappStore = await CheddaDappStore.deploy();
  await dappStore.deployed();
});

describe("CheddaDappStore", function () {
  it("Can add and remove dapp", async function () {
    let numberOfDapps = await dappStore.numberOfDapps();
    expect(numberOfDapps).to.equal(0);

    await dappStore.addDapp(
      dappName,
      dappNetwork,
      dappChainId,
      dappAddress,
      dappCategory,
      dappUri
    );
    numberOfDapps = await dappStore.numberOfDapps();
    expect(numberOfDapps).to.equal(1);

    const dapp = await dappStore.getDappAtIndex(0);
    console.log("Dapp is ", dapp);
    expect(dapp.name).to.equal(dappName);
    expect(dapp.contractAddress).to.equal(dappAddress);
    expect(dapp.chainID).to.equal(dappChainId);
    expect(dapp.network).to.equal(dappNetwork);
    expect(dapp.metadataURI).to.equal(dappUri);

    const dapp2Name = "My Awesome Dapp";
    const dapp2Network = "Ethereum";
    const dapp2ChainId = 1;
    const dapp2Address = "0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec";
    const dapp2Uri = "https://app.myawesomedapp.com";

    await dappStore.addDapp(
      dapp2Name,
      dapp2Network,
      dapp2ChainId,
      dapp2Address,
      dappCategory,
      dapp2Uri
    );

    const newNumberOfDapps = await dappStore.numberOfDapps();
    expect(newNumberOfDapps).to.equal(2);
    const dapp2 = await dappStore.getDappAtIndex(1);
    expect(dapp2.name).to.equal(dapp2Name);
    expect(dapp2.contractAddress).to.equal(dapp2Address);
    expect(dapp2.chainID).to.equal(dapp2ChainId);
    expect(dapp2.network).to.equal(dapp2Network);
    expect(dapp2.metadataURI).to.equal(dapp2Uri);
  });

  it("Can remove dapp", async function () {
    await dappStore.addDapp(
      dappName,
      dappNetwork,
      dappChainId,
      dappAddress,
      dappCategory,
      dappUri
    );
    let numberOfDapps = await dappStore.numberOfDapps();
    expect(numberOfDapps).to.equal(1);

    await dappStore.removeDapp(dappAddress);
    numberOfDapps = await dappStore.numberOfDapps();
    expect(numberOfDapps).to.equal(0);
  });

  it("Can like and dislike dapp", async function () {
    await dappStore.addDapp(
      dappName,
      dappNetwork,
      dappChainId,
      dappAddress,
      dappCategory,
      dappUri
    );
    let likes = await dappStore.likes(dappAddress);
    expect(likes).to.equal(0);

    await dappStore.likeDapp(dappAddress);
    likes = await dappStore.getLikes(dappAddress);
    expect(likes).to.equal(1);

    await dappStore.likeDapp(dappAddress);
    likes = await dappStore.getLikes(dappAddress);
    expect(likes).to.equal(2);

    await dappStore.unlikeDapp(dappAddress);
    likes = await dappStore.getDislikes(dappAddress);
    expect(likes).to.equal(1);

    await dappStore.unlikeDapp(dappAddress);
    likes = await dappStore.getDislikes(dappAddress);
    expect(likes).to.equal(2);
  });


  it("Can categorize dapps", async function() {
    const defi = "DeFi"
    const nft = "NFT"
    
    await dappStore.addDapp(
      "UniSwap",
      dappNetwork,
      dappChainId,
      "0x8626f6940e2eb28930efb4cef49b2d1f2c9c1199",
      defi,
      dappUri
    ); 
    await dappStore.addDapp(
      "SushiSwap",
      dappNetwork,
      dappChainId,
      "0xbda5747bfd65f08deb54cb465eb87d40e51b197e",
      defi,
      dappUri
    );

    await dappStore.addDapp(
      "Bloot",
      dappNetwork,
      dappChainId,
      "0xdd2fd4581271e230360230f9337d5c0430bf44c0",
      nft,
      dappUri
    );

    const numberInDefi = await dappStore.numberOfDappsInCategory(defi)
    expect(numberInDefi).to.equal(2)

    const numberInNFT = await dappStore.numberOfDappsInCategory(nft)
    expect(numberInNFT).to.equal(1)

    const defiDapps = await dappStore.getDappsInCategory(defi)
    expect(defiDapps.length).to.equal(2)
  });
});
