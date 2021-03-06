
const hre = require("hardhat");
const ethers = require("ethers")
const fs = require('fs');
const networkName = hre.network.name

const addresses = require(`../../addresses/${networkName}/registry.json`)

let registry
let market

async function main() {
  console.log('registry address is ', addresses.registry)
  CheddaAddressRegistry = await hre.ethers.getContractFactory("CheddaAddressRegistry");
  registry = await CheddaAddressRegistry.attach(addresses.registry)

  const CheddaMarket = await hre.ethers.getContractFactory("CheddaMarket");
  market = await CheddaMarket.deploy();
  await market.deployed()

  console.log("CheddaMarket deployed to:", market.address);
  await market.updateRegistry(registry.address)
  await registry.setMarket(market.address)
  await save()
}


async function save() {
  const provider = new ethers.providers.JsonRpcProvider();
  const network = await provider.getNetwork()
  let config = `
  {
    "market": "${market.address}"
  }

  `
  console.log("network is: ", network)
  let data = JSON.stringify(config)
  let filename = `./addresses/${networkName}/market.json`
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
