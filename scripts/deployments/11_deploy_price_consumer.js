const hre = require("hardhat");
const fs = require('fs');
const networkName = hre.network.name

const addresses = require(`../../addresses/${networkName}/registry.json`)
const priceFeed = require(`../../addresses/${networkName}/chainlinkPriceFeed.json`)

let registry
let consumer

async function main() {
  CheddaAddressRegistry = await hre.ethers.getContractFactory("CheddaAddressRegistry");
  registry = await CheddaAddressRegistry.attach(addresses.registry)

  const ChainlinkPriceConsumerV3 = await hre.ethers.getContractFactory("ChainlinkPriceConsumerV3");
  consumer = await ChainlinkPriceConsumerV3.deploy(priceFeed.address);
  await consumer.deployed()
  console.log('price feed address is: ', priceFeed.address)
  console.log('consumer deployed to address: ', consumer.address)
  await registry.setPriceConsumer(consumer.address)
  console.log('registry updated')

  console.log("PriceConsumerV3 deployed to:", consumer.address);
  await save()
}


async function save() {
  let config = `
  {
    "priceConsumer": "${consumer.address}"
  }

  `
  let data = JSON.stringify(config)
  let filename = `./addresses/${networkName}/price-consumer.json`
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
