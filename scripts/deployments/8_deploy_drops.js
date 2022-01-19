const hre = require("hardhat");
const ethers = require("ethers")
const fs = require('fs');
const networkName = hre.network.name

const addresses = require(`../../addresses/${networkName}/registry.json`)

let registry
let drops

async function main() {
  CheddaAddressRegistry = await hre.ethers.getContractFactory("CheddaAddressRegistry");
  registry = await CheddaAddressRegistry.attach(addresses.registry)

  const CheddaDropManager = await hre.ethers.getContractFactory("CheddaDropManager");
  drops = await CheddaDropManager.deploy();

  console.log('drops deployed to address: ', drops.address)
  await drops.updateRegistry(registry.address)
  console.log('drops updated')
  await registry.setDrops(drops.address)
  console.log('registry updated')

  console.log("DropsManager deployed to:", drops.address);
  await save()
}


async function save() {
  let config = `
  {
    "drops": "${drops.address}"
  }

  `
  let data = JSON.stringify(config)
  let filename = `./addresses/${networkName}/drops.json`
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
