const hre = require("hardhat");
const ethers = require("ethers")
const fs = require('fs');
const networkName = hre.network.name

const addresses = require(`../../addresses/${networkName}/registry.json`)

let registry
let rewards

async function main() {
  console.log('registry address is ', addresses.registry)
  CheddaAddressRegistry = await hre.ethers.getContractFactory("CheddaAddressRegistry");
  registry = await CheddaAddressRegistry.attach(addresses.registry)

  const CheddaRewards = await hre.ethers.getContractFactory("CheddaRewards");
  rewards = await CheddaRewards.deploy();

  await rewards.updateRegistry(registry.address)
  await registry.setRewards(rewards.address)

  console.log("CheddaRewards deployed to:", rewards.address);
  await save()
}


async function save() {
  const provider = new ethers.providers.JsonRpcProvider();
  const network = await provider.getNetwork()
  let config = `
  {
    "rewards": "${rewards.address}"
  }

  `
  console.log("network is: ", network)
  let data = JSON.stringify(config)
  let filename = `./addresses/${networkName}/rewards.json`
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
