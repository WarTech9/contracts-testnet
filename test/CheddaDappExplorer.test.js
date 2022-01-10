// const { expect } = require("chai");
const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

let signer0, signer1;
let store
let explorer
let registry
let xp
let rewards

const dappAddress = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
const dappAddress2 = "0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec"

const dappName = "Best Dapp";
const dappNetwork = "Ethereum";
const dappChainId = 1;
const dappUri =  "http://myaddress.com"
const dappCategory = "defi"

beforeEach(async function () {
  const signers = await ethers.getSigners();
  [signer0, signer1] = [signers[0], signers[1]];

  CheddaAddressRegistry = await ethers.getContractFactory("CheddaAddressRegistry");
  registry = await CheddaAddressRegistry.deploy();

  const CheddaXP = await ethers.getContractFactory("CheddaXP");
  xp = await CheddaXP.deploy();
  await xp.updateRegistry(registry.address)

  const CheddaRewards = await ethers.getContractFactory("CheddaRewards");
  rewards = await CheddaRewards.deploy();
  await rewards.updateRegistry(registry.address)

  console.log(`CheddaXP Deployed to ${xp.address}, rewards: ${rewards.address}`)

  const CheddaDappStore = await ethers.getContractFactory("CheddaDappStore");
  store = await CheddaDappStore.deploy();
  await store.updateRegistry(registry.address)

  const CheddaDappExplorer = await ethers.getContractFactory("CheddaDappExplorer");
  explorer = await CheddaDappExplorer.deploy();
  await explorer.updateRegistry(registry.address)

  await registry.setDappStore(store.address)
  await registry.setDappstoreExplorer(explorer.address)
  await registry.setRewards(rewards.address)
  await registry.setCheddaXP(xp.address)

  console.log("rewards deplloyed to ", rewards.address)

});


describe("CheddaDappExplorer", function () {
  it("Can rate dapp", async function () {
    await store.addDapp(
      dappName,
      dappChainId,
      dappAddress,
      dappCategory,
      dappUri,
    );

    let averageRating = await explorer.averageRating(dappAddress)
    expect(averageRating).to.equal(0);

    await explorer.addRating(dappAddress, 500);
    averageRating = await explorer.averageRating(dappAddress);
    expect(averageRating).to.equal(500);

    await explorer.connect(signer1).addRating(dappAddress, 300);

    averageRating = await explorer.averageRating(dappAddress);
    expect(averageRating).to.equal(400);
  });


  it("Can review dapp", async function () {

    await store.addDapp(
      dappName,
      dappChainId,
      dappAddress,
      dappCategory,
      dappUri,
    );

    let reviews = await explorer.getReviews(dappAddress);
    console.log("reviews are: ", reviews);
    let averageRating = await explorer.averageRating(dappAddress);
    expect(reviews.length).to.equal(0);
    expect(averageRating).to.equal(0);

    const reviewUrl = "http://myreview.com"
    await explorer.addReview(dappAddress, reviewUrl, 500);
    reviews = await explorer.getReviews(dappAddress);
    averageRating = await explorer.averageRating(dappAddress)

    expect(reviews.length).to.equal(1);
    expect(reviews[0].contentURI).to.equal(reviewUrl)
    expect(averageRating).to.equal(500);
  });

  it("Can issue rewards", async function() {
        let recipient = "0x1cbd3b2770909d4e10f157cabc84c7264073c9ec"

        // await rewards.issueRewards(1, recipient)
        let rewardsForAction = await rewards.pointsPerAction(1)

        let balance = await xp.balanceOf(recipient)

        await store.addDapp(
          dappName,
          dappChainId,
          dappAddress,
          dappCategory,
          dappUri
        );

        balance = await xp.balanceOf(signer1.address)
        expect(balance).to.equal(BigNumber.from(0))

        let numberOfRatings = await explorer.numberOfRatings(dappAddress)
        
        await explorer.connect(signer1).addRating(dappAddress, 500);
        numberOfRatings = await explorer.numberOfRatings(dappAddress)
        averageRating = await explorer.averageRating(dappAddress);
        expect(averageRating).to.equal(500);
        expect(numberOfRatings).to.equal(BigNumber.from(1))

        await explorer.addRating(dappAddress, 100)
        numberOfRatings = await explorer.numberOfRatings(dappAddress)
        averageRating = await explorer.averageRating(dappAddress);
        expect(averageRating).to.equal(300);
        expect(numberOfRatings).to.equal(BigNumber.from(2))

        balance = await xp.balanceOf(signer1.address)
        expect(balance).to.not.equal(BigNumber.from(0))
        console.log('balance after rating = ', balance)
        console.log('number of ratings = ', numberOfRatings)
  });
});
