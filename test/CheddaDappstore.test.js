// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");

let CheddaDappStore;
let dappStore;

const dappName = "My Awesome Dapp";
const dappNetwork = "Ethereum";
const dappChainId = 1;
const dappAddress = "0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec";
const dappUri = "https://app.myawesomedapp.com";

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

});
