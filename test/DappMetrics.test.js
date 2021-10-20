// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");

let signer0, signer1;
let store;
let metrics;
const dappAddress = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
const dappAddress2 = "0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec"

const dappName = "Best Dapp";
const dappNetwork = "Ethereum";
const dappChainId = 1;
const dappUri =  "http://myaddress.com"

beforeEach(async function () {
  const signers = await ethers.getSigners();
  [signer0, signer1] = [signers[0], signers[1]];

  const CheddaDappStore = await ethers.getContractFactory("CheddaDappStore");
  store = await CheddaDappStore.deploy();
  await store.deployed();

  const DappMetrics = await ethers.getContractFactory("DappMetrics");
  metrics = await DappMetrics.deploy(store.address);
  await metrics.deployed();
});


describe("DappMetrics", function () {
  it("Can rate dapp", async function () {
    await store.addDapp(
      dappName,
      dappNetwork,
      dappChainId,
      dappAddress,
      dappUri,
    );

    let averageRating = await metrics.averageRating(dappAddress)
    expect(averageRating).to.equal(0);

    await metrics.addRating(dappAddress, 500);
    averageRating = await metrics.averageRating(dappAddress);
    expect(averageRating).to.equal(500);

    await metrics.connect(signer1).addRating(dappAddress, 300);

    averageRating = await metrics.averageRating(dappAddress);
    expect(averageRating).to.equal(400);
  });


  it("Can review dapp", async function () {
    await store.addDapp(
      dappName,
      dappNetwork,
      dappChainId,
      dappAddress,
      dappUri
    );

    let reviews = await metrics.getReviews(dappAddress);
    console.log("reviews are: ", reviews);
    let averageRating = await metrics.averageRating(dappAddress);
    expect(reviews.length).to.equal(0);
    expect(averageRating).to.equal(0);

    await metrics.addReview(dappAddress, "http://myreview.com", 500);
    reviews = await metrics.getReviews(dappAddress);
    averageRating = await metrics.averageRating(dappAddress)
    expect(reviews.length).to.equal(1);
    expect(averageRating).to.equal(500);
  });
});
