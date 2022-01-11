const hre = require("hardhat");
const ethers = require("ethers")
const fs = require('fs')
const networkName = hre.network.name

const addresses = require(`../../addresses/${networkName}/registry.json`)

let dappStore
let registry

async function main() {
  console.log('registry address is ', addresses.registry)
  CheddaAddressRegistry = await hre.ethers.getContractFactory("CheddaAddressRegistry");
  registry = await CheddaAddressRegistry.attach(addresses.registry)

  const CheddaDappStore = await hre.ethers.getContractFactory("CheddaDappStore");
  dappStore = await CheddaDappStore.deploy();
  
  console.log("CheddaDappStore deployed to:", dappStore.address);
  await dappStore.updateRegistry(registry.address)
  await registry.setDappStore(dappStore.address)
  await save()
}

async function save() {
  const provider = new ethers.providers.JsonRpcProvider();
  const network = await provider.getNetwork()
  let config = `
  {
    "dappStore": "${dappStore.address}"
  }

  `
  let data = JSON.stringify(config)
  let filename = `./addresses/${networkName}/dappstore.json`
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
