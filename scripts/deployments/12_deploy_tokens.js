const hre = require('hardhat')
const fs = require('fs')
const { ethers } = require('hardhat')
const networkName = hre.network.name

const addresses = require(`../../addresses/${networkName}/registry.json`)

let chedda
let xChedda
let wrappedToken
let usdc
let registry
let mUSDC
let faucet
let timeout
let tokenRecipient

async function main() {
  const signers = await hre.ethers.getSigners()
  tokenRecipient = signers[1]

  const totalSupply = ethers.utils.parseUnits('1000000000', 'ether')

  // workaround for avalanche txs failing if no delay
  timeout = networkName === 'avalanchefuji' ? 5000 : 0

  console.log(`tokenRecipient is ${tokenRecipient.address}`)
  const CheddaAddressRegistry = await hre.ethers.getContractFactory(
    'CheddaAddressRegistry'
  )
  registry = await CheddaAddressRegistry.attach(addresses.registry)
  await wait(timeout)

  // deploy Chedda
  const Chedda = await hre.ethers.getContractFactory('Chedda')
  chedda = await Chedda.deploy(tokenRecipient.address)
  await chedda.deployed()
  await wait(timeout)
  registry.setChedda(chedda.address)
  console.log('Chedda address is: ', chedda.address)
  await wait(timeout)

  // deploy xChedda
  const StakedChedda = await hre.ethers.getContractFactory('StakedChedda')
  xChedda = await StakedChedda.deploy(chedda.address)
  await xChedda.deployed()
  console.log('xChedda address is: ', xChedda.address)
  await wait(timeout)

  await chedda.setVault(xChedda.address)

  // deploy USDC.c
  const USDC = await hre.ethers.getContractFactory('USDC')
  usdc = await USDC.deploy(tokenRecipient.address, totalSupply)
  await usdc.deployed()
  console.log('USDC address is: ', usdc.address)
  await wait(timeout)

  // deploy Mozz token
  const MozzUSDC = await hre.ethers.getContractFactory('CheddaBaseTokenVault')
  mUSDC = await MozzUSDC.deploy(usdc.address, 'Mozz USDC', 'mUSDC')
  await mUSDC.deployed()
  console.log('mUSDC address is: ', mUSDC.address)

  // deploy Mon token
  const Mon = await hre.ethers.getContractFactory('CheddaBaseTokenVault')
  const mon = await Mon.deploy(usdc.address, 'MON Token', 'MON')
  await mon.deployed()
  console.log('MON address is: ', mon.address)

  // deploy wrapped native token
  const WrappedToken = await hre.ethers.getContractFactory('WrappedNativeToken')
  const token = getWrappedToken()
  wrappedToken = await WrappedToken.deploy(
    token.name,
    token.symbol,
    tokenRecipient.address,
    totalSupply
  )
  await wrappedToken.deployed()
  console.log(`${token.symbol} address is: ${wrappedToken.address}`)
  await wait(timeout)

  await wait(timeout)
  // deploy Faucet
  const Faucet = await hre.ethers.getContractFactory('Faucet')
  faucet = await Faucet.deploy()
  await faucet.deployed()
  console.log('Faucet address is: ', faucet.address)
  await fillFaucet()
  await whitelistToken(wrappedToken)

  await save()
}

async function save() {
  const cheddaName = await chedda.symbol()
  const sCheddaName = await xChedda.symbol()
  const wrappedName = await wrappedToken.symbol()
  const usdcName = await usdc.symbol()
  const mUSDCName = await mUSDC.symbol()
  const config = `
  {
    "${cheddaName}": "${chedda.address}",
    "${sCheddaName}": "${xChedda.address}",
    "${wrappedName}": "${wrappedToken.address}",
    "${usdcName}": "${usdc.address}",
    "${mUSDCName}": "${mUSDC.address}",
    "Faucet": "${faucet.address}"
  }

  `
  const data = JSON.stringify(config)
  const filename = `./addresses/${networkName}/tokens.json`
  fs.writeFileSync(filename, JSON.parse(data))
  console.log(`Addresses written to file: ${filename}`)
}

function getWrappedToken() {
  switch (networkName) {
    case 'avalanchefuji':
      return { name: 'Wrapped AVAX', symbol: 'WAVAX' }
    case 'polygonmumbai':
      return { name: 'Wrapped MATIC', symbol: 'WMATIC' }
    case 'harmonytest':
      return { name: 'Wrapped ONE', symbol: 'WONE' }
    default:
      return { name: 'Wrapped ETH', symbol: 'WETH' }
  }
}

async function fillFaucet() {
  const fillAmount = ethers.utils.parseUnits('10000000', 'ether')
  console.log('filling with Chedda =>')
  await chedda.connect(tokenRecipient).approve(faucet.address, fillAmount)
  await wait(timeout)
  await faucet.connect(tokenRecipient).fill(chedda.address, fillAmount)
  await wait(timeout)

  console.log('filling with WrappedToken =>')
  await wrappedToken.connect(tokenRecipient).approve(faucet.address, fillAmount)
  await wait(timeout)
  await faucet.connect(tokenRecipient).fill(wrappedToken.address, fillAmount)
  await wait(timeout)

  console.log('filling with USDC =>')
  await usdc.connect(tokenRecipient).approve(faucet.address, fillAmount)
  await wait(timeout)
  await faucet.connect(tokenRecipient).fill(usdc.address, fillAmount)
  await wait(timeout)
}

async function whitelistToken(token) {
  await mUSDC.whitelistToken(token.address, true)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })

function wait(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms)
  })
}
