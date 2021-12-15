const hre = require("hardhat");
const ethers = require("ethers")
const fs = require('fs');
const addresses = require("../../addresses/registry.json")

let dappExplorer
let registry

async function main() {
  console.log('registry address is ', addresses.registry)
  CheddaAddressRegistry = await hre.ethers.getContractFactory("CheddaAddressRegistry");
  registry = await CheddaAddressRegistry.attach(addresses.registry)

  const CheddaDappExplorer = await hre.ethers.getContractFactory("CheddaDappExplorer");
  dappExplorer = await CheddaDappExplorer.deploy();

  console.log("CheddaDappExplorer deployed to:", dappExplorer.address);
  await dappExplorer.updateRegistry(registry.address)
  await registry.setDappstoreExplorer(dappExplorer.address)
  await save()
}

async function save() {
  const provider = new ethers.providers.JsonRpcProvider();
  let config = `
  {
    "dappExplorer": "${dappExplorer.address}"
  }

  `
  let data = JSON.stringify(config)
  let filename = `./addresses/dapp-explorer.json`
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
