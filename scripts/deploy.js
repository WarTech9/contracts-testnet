// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const ethers = require("ethers")
const fs = require('fs');

let dappStore
let dappMetrics

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const CheddaStore = await hre.ethers.getContractFactory("CheddaDappStore");
  dappStore = await CheddaStore.deploy();
  await dappStore.deployed();

  const DappMetrics = await hre.ethers.getContractFactory("DappMetrics");
  dappMetrics = await DappMetrics.deploy(dappStore.address);
  await dappMetrics.deployed();

  console.log("CheddaDappStore deployed to:", dappStore.address);
  console.log("DappMetrics deployed to:", dappMetrics.address);
  await save()
}


async function save() {
  const provider = new ethers.providers.JsonRpcProvider();
  const network = await provider.getNetwork()
  let config = `
  {
    "dappStore": "${dappStore.address}",
    "dappMetrics": "${dappMetrics.address}"
  }

  `
  console.log("network is: ", network)
  let data = JSON.stringify(config)
  fs.writeFileSync(`${network.name}.addresses.json`, JSON.parse(data))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
