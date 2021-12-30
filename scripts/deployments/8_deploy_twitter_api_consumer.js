const hre = require("hardhat");
const ethers = require("ethers")
const fs = require('fs');

const linkAddress = "0x326c977e6efc84e512bb9c30f76e30c160ed06fb"
const oracle = "0xc8D925525CA8759812d0c299B90247917d4d4b7C"
const jobId = "99b1b806a8f84b14a254230ccf094747"
const jobIdBytes = ethers.utils.toUtf8Bytes(jobId)
const fee = ethers.utils.parseUnits("0.01", "ether")

let consumer

async function main() {
  const TwitterAPIConsumer = await hre.ethers.getContractFactory("TwitterAPIConsumer");
  consumer = await TwitterAPIConsumer.deploy(linkAddress, oracle, jobIdBytes, fee.toString());

  console.log("TwitterAPIConsumer deployed to:", consumer.address);
  await save()
}

async function save() {
  const provider = new ethers.providers.JsonRpcProvider();
  const network = await provider.getNetwork()
  let config = `
  {
    "consumer": "${consumer.address}"
  }

  `
  console.log("network is: ", network)
  let data = JSON.stringify(config)
  let filename = `./addresses/consumer.json`
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
