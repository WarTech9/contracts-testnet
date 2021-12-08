// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");

let store;
let explorer
let registry
let xp
let rewards

const defi = "DeFi"
const nft = "NFT"

const dappName = "My Awesome Dapp";
const dappChainId = 1;
const dappAddress = "0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec";
const dappUri = "https://app.myawesomedapp.com"
const dappCategory = defi

const dapp2Name = "My Second Dapp";
const dapp2ChainId = 1;
const dapp2Address = "0xbda5747bfd65f08deb54cb465eb87d40e51b197e";
const dapp2Uri = "https://app.myawesomedapp2.com";

beforeEach(async function () {
  CheddaAddressRegistry = await ethers.getContractFactory("CheddaAddressRegistry");
  registry = await CheddaAddressRegistry.deploy()

  const CheddaXP = await ethers.getContractFactory("CheddaXP");
  xp = await CheddaXP.deploy()
  await xp.updateRegistry(registry.address)

  const CheddaRewards = await ethers.getContractFactory("CheddaRewards");
  rewards = await CheddaRewards.deploy()
  await rewards.updateRegistry(registry.address)

  console.log(`CheddaXP Deployed to ${xp.address}, rewards: ${rewards.address}`)

  const CheddaDappStore = await ethers.getContractFactory("CheddaDappStore");
  store = await CheddaDappStore.deploy()
  await store.updateRegistry(registry.address)

  const CheddaDappExplorer = await ethers.getContractFactory("CheddaDappExplorer");
  explorer = await CheddaDappExplorer.deploy()
  await explorer.updateRegistry(registry.address)

  await registry.setDappStore(store.address)
  await registry.setDappstoreExplorer(explorer.address)
  await registry.setRewards(rewards.address)
  await registry.setCheddaXP(xp.address)
});

describe("CheddaDappStore", function () {
  it("Can add and remove dapp", async function () {
    let numberOfDapps = await store.numberOfDapps();
    expect(numberOfDapps).to.equal(0);
 
    await store.addDapp(
      dappName,
      dappChainId,
      dappAddress,
      dappCategory,
      dappUri
    );
    numberOfDapps = await store.numberOfDapps();
    expect(numberOfDapps).to.equal(1);

    const dapp = await store.getDappAtIndex(0);
    console.log("Dapp is ", dapp);
    expect(dapp.name).to.equal(dappName);
    expect(dapp.contractAddress).to.equal(dappAddress);
    expect(dapp.chainID).to.equal(dappChainId);
    expect(dapp.metadataURI).to.equal(dappUri);

    const dapp2Name = "My Awesome Dapp";
    const dapp2ChainId = 1;
    const dapp2Address = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    const dapp2Uri = "https://app.myawesomedapp.com";

    await store.addDapp(
      dapp2Name,
      dapp2ChainId,
      dapp2Address,
      dappCategory,
      dapp2Uri
    );

    const newNumberOfDapps = await store.numberOfDapps();
    expect(newNumberOfDapps).to.equal(2);
    const dapp2 = await store.getDappAtIndex(1);
    expect(dapp2.name).to.equal(dapp2Name);
    expect(dapp2.contractAddress).to.equal(dapp2Address);
    expect(dapp2.chainID).to.equal(dapp2ChainId);
    expect(dapp2.metadataURI).to.equal(dapp2Uri);
  });

  it("Can remove dapp", async function () {
    await store.addDapp(
      dappName,
      dappChainId,
      dappAddress,
      dappCategory,
      dappUri
    );
    let numberOfDapps = await store.numberOfDapps();
    expect(numberOfDapps).to.equal(1);

    await store.removeDapp(dappAddress);
    numberOfDapps = await store.numberOfDapps();
    expect(numberOfDapps).to.equal(0);
  });

  it("Can categorize dapps", async function() {
    await store.addDapp(
      "UniSwap",
      dappChainId,
      "0x8626f6940e2eb28930efb4cef49b2d1f2c9c1199",
      defi,
      dappUri
    ); 

    await store.addDapp(
      "Bloot",
      dappChainId,
      "0xdd2fd4581271e230360230f9337d5c0430bf44c0",
      nft,
      dappUri
    );

    await store.addDapp(
      "SushiSwap",
      dappChainId,
      "0xbda5747bfd65f08deb54cb465eb87d40e51b197e",
      defi,
      dappUri
    );


    const numberInDefi = await store.numberOfDappsInCategory(defi)
    expect(numberInDefi).to.equal(2)

    const numberInNFT = await store.numberOfDappsInCategory(nft)
    expect(numberInNFT).to.equal(1)

    // const defiDapps = await store.dappsInCategory(defi)
    // console.log('defi dapps are: ', defiDapps)
    // expect(defiDapps.length).to.equal(2)

    const nftDapps = await store.dappsInCategory(nft)
    console.log('nft dapps are: ', nftDapps)
  });

  // it("Can get all dapps", async function() {
  //   await store.addDapp(
  //     "UniSwap",
  //     dappChainId,
  //     "0x8626f6940e2eb28930efb4cef49b2d1f2c9c1199",
  //     defi,
  //     dappUri
  //   );

  //   let dapps = await store.dapps()
  //   console.log('all dapps are: ', dapps)
  //   expect(dapps.length).to.greaterThan(0)
  // })

  // it("can feature dapps", async function() {
  //   await store.addDapp(
  //     dappName,
  //     dappChainId,
  //     dappAddress,
  //     dappCategory,
  //     dappUri
  //   );
  //   numberOfDapps = await store.numberOfDapps();
  //   expect(numberOfDapps).to.equal(1);

  //   const dapp = await store.getDappAtIndex(0);
  //   console.log("Dapp is ", dapp);
  //   expect(dapp.name).to.equal(dappName);
  //   expect(dapp.contractAddress).to.equal(dappAddress);
  //   expect(dapp.chainID).to.equal(dappChainId);
  //   expect(dapp.metadataURI).to.equal(dappUri);


  //   await store.addDapp(
  //     dapp2Name,
  //     dapp2ChainId,
  //     dapp2Address,
  //     dappCategory,
  //     dapp2Uri
  //   );
 
  //   await store.setFeaturedDapp(dapp2Address, true)
  //   const featured = await store.featuredDapps()
  //   console.log('featured = ', featured)
  //   expect(featured.length).to.equal(1)
  //   console.log('dapp is = ', featured[0].dapp)
  //   expect(featured[0].dapp.contractAddress.toLowerCase()).to.equal(dapp2Address.toLowerCase())
  // })

  // it("Can ge popular dapps", async function() {
  //   await store.addDapp(
  //     dappName,
  //     dappChainId,
  //     dappAddress,
  //     dappCategory,
  //     dappUri
  //   ); 

  //   await store.addDapp(
  //     dapp2Name,
  //     dapp2ChainId,
  //     dapp2Address,
  //     dappCategory,
  //     dapp2Uri
  //   );

  //   await explorer.addRating(dappAddress, 500)
  //   const popular = await store.popularDapps()
  //   console.log("Popular dapps are: ", popular)
  // })
});
