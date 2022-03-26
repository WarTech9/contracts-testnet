const hre = require('hardhat')
const fs = require('fs')
const networkName = hre.network.name

const assetTokenAddress = '0x55df0aF74eE7FA170AbBF7eb3F8D43d7c20De207'
const collateralTokenAddress = '0x2c01212f051A59D88A1361db1E2041896dB4af64'
let vaultToken
let timeout

async function main() {
  // workaround for avalanche txs failing if no delay
  timeout = networkName === 'avalanchefuji' ? 5000 : 0

  // deploy vault
  const CheddaBaseTokenVault = await hre.ethers.getContractFactory(
    'CheddaBaseTokenVault'
  )
  vaultToken = await CheddaBaseTokenVault.deploy(
    assetTokenAddress,
    'Mozz USDC',
    'mUSDC'
  )
  await vaultToken.deployed()
  console.log('vaultToken address is: ', vaultToken.address)

  await wait(timeout)
  await vaultToken.whitelistToken(collateralTokenAddress, true)

  await save()
}

async function save() {
  const vaultTokenName = await vaultToken.symbol()
  const config = `
  {
    "${vaultTokenName}": "${vaultToken.address}",
  }

  `
  const data = JSON.stringify(config)
  const filename = `./addresses/${networkName}/token-vault.json`
  fs.writeFileSync(filename, JSON.parse(data))
  console.log(`Addresses written to file: ${filename}`)
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
