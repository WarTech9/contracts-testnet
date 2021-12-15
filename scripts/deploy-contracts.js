// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const ethers = require("ethers")
const fs = require('fs');

let registry
let xp
let rewards
let dappStore
let dappExplorer
let market
let marketExplorer

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  CheddaAddressRegistry = await hre.ethers.getContractFactory("CheddaAddressRegistry");
  registry = await CheddaAddressRegistry.deploy();

  const CheddaXP = await hre.ethers.getContractFactory("CheddaXP");
  xp = await CheddaXP.deploy();
  await xp.updateRegistry(registry.address)

  const CheddaRewards = await hre.ethers.getContractFactory("CheddaRewards");
  rewards = await CheddaRewards.deploy();
  await rewards.updateRegistry(registry.address)

  const CheddaDappStore = await hre.ethers.getContractFactory("CheddaDappStore");
  dappStore = await CheddaDappStore.deploy();
  await dappStore.updateRegistry(registry.address)

  const CheddaDappExplorer = await hre.ethers.getContractFactory("CheddaDappExplorer");
  dappExplorer = await CheddaDappExplorer.deploy();
  await dappExplorer.updateRegistry(registry.address)

  const CheddaMarket = await hre.ethers.getContractFactory("CheddaMarket");
  market = await CheddaMarket.deploy();
  await market.updateRegistry(registry.address)

  const CheddaMarketExplorer = await hre.ethers.getContractFactory("CheddaMarketExplorer");
  marketExplorer = await CheddaMarketExplorer.deploy();
  await marketExplorer.updateRegistry(registry.address)
  
  await registry.setDappStore(dappStore.address)
  await registry.setDappstoreExplorer(dappExplorer.address)
  await registry.setRewards(rewards.address)
  await registry.setCheddaXP(xp.address)
  await registry.setMarket(market.address)
  await registry.setMarketExplorer(marketExplorer.address)

  console.log("CheddaAddressRegistry deployed to:", registry.address);
  await save()
}


async function save() {
  const provider = new ethers.providers.JsonRpcProvider();
  const network = await provider.getNetwork()
  let config = `
  {
    "registry": "${registry.address}",
    "xp": "${xp.address}",
    "dappStore": "${dappStore.address}",
    "dappStoreExplorer": "${dappExplorer.address}",
    "market": "${market.address}",
    "marketExplorer": "${marketExplorer.address}",
    "rewards": "${rewards.address}"
  }

  `
  console.log("network is: ", network)
  let data = JSON.stringify(config)
  let filename = `${network.name}-store.addresses.json`
  fs.writeFileSync(filename, JSON.parse(data))
  console.log(`Addresses written to file: ${filename}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
