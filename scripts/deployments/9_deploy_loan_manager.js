const hre = require("hardhat");
const ethers = require("ethers")
const fs = require('fs');
const networkName = hre.network.name

const addresses = require(`../../addresses/${networkName}/registry.json`)

let registry
let loanManager

async function main() {
  CheddaAddressRegistry = await hre.ethers.getContractFactory("CheddaAddressRegistry");
  registry = await CheddaAddressRegistry.attach(addresses.registry)

  const CheddaLoanManager = await hre.ethers.getContractFactory("CheddaLoanManager");
  const wrappedNativeTokenAddress = await registry.wrappedNativeToken()
  console.log('wrapped native token address = ', wrappedNativeTokenAddress)
  loanManager = await CheddaLoanManager.deploy(wrappedNativeTokenAddress);
  await loanManager.deployed()

  await loanManager.updateRegistry(registry.address)
  await registry.setLoanManager(loanManager.address)

  console.log("LoanManager deployed to:", loanManager.address);
  await save()
}


async function save() {
  let config = `
  {
    "loanManager": "${loanManager.address}"
  }

  `
  let data = JSON.stringify(config)
  let filename = `./addresses/${networkName}/loanmanager.json`
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
