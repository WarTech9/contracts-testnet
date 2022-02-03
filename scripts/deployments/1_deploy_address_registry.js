const hre = require("hardhat");
const ethers = require("ethers")
const fs = require('fs');
const networkName = hre.network.name
const wrappedToken = require(`../../addresses/${networkName}/wrapped-token.json`)
let registry

async function main() {
  const signers = await hre.ethers.getSigners();
  console.log('first signer = ', signers[0].address)
  CheddaAddressRegistry = await hre.ethers.getContractFactory("CheddaAddressRegistry");
  registry = await CheddaAddressRegistry.deploy();
  await registerWrappedToken()
  
  console.log("CheddaAddressRegistry deployed to:", registry.address);
  await save()
}

function checkGas() {
  
}
async function save() {
  const provider = new ethers.providers.JsonRpcProvider();
  const network = await provider.getNetwork()
  let config = `
  {
    "registry": "${registry.address}"
  }

  `
  console.log("network is: ", network)
  let data = JSON.stringify(config)
  let filename = `./addresses/${networkName}/registry.json`
  fs.writeFileSync(filename, JSON.parse(data))
  console.log(`Addresses written to file: ${filename}`)
}

async function registerWrappedToken() {
  await registry.setWrappedNativeToken(wrappedToken.address)
  console.log('set wrapped token address to ', wrappedToken.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });