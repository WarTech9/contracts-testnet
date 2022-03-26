require('dotenv').config()

require('@nomiclabs/hardhat-etherscan')
require('@nomiclabs/hardhat-waffle')
require('@nomiclabs/hardhat-web3')
require('hardhat-gas-reporter')
require('solidity-coverage')
require('hardhat-deploy')
require('dotenv').config()

// require("./helper-hardhat-config")

const fs = require('fs')
const { task } = require('hardhat/config')
const privateKey =
  fs.readFileSync('.secret').toString().trim() || '01234567890123456789'
const privateKey2 =
  fs.readFileSync('.secret2').toString().trim() || '01234567890123456789'
const infuraId = fs.readFileSync('.infuraid').toString().trim() || ''

const LINK_TOKEN_ABI = [
  {
    inputs: [
      { internalType: 'address', name: 'recipient', type: 'address' },
      { internalType: 'uint256', name: 'amount', type: 'uint256' },
    ],
    name: 'transfer',
    outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
    stateMutability: 'nonpayable',
    type: 'function',
  },
]

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

task('balance', "Prints an account's balance")
  .addParam('account', "The account's address")
  .setAction(async (taskArgs) => {
    const account = web3.utils.toChecksumAddress(taskArgs.account)
    const balance = await web3.eth.getBalance(account)

    console.log(web3.utils.fromWei(balance, 'ether'), 'ETH')
  })


//  module.exports = {}


function getLinkContractAddress() {
  const networkId = network.name
  console.log('Getting link contract address for networkId: ', networkId)

  //set the LINK token contract address according to the environment
  switch (networkId) {
    case 'mainnet':
      linkContractAddr = '0x514910771af9ca656af840dff83e8264ecf986ca'
      break
    case 'kovan':
      linkContractAddr = '0xa36085F69e2889c224210F603D836748e7dC0088'
      break
    case 'rinkeby':
      linkContractAddr = '0x01BE23585060835E02B77ef475b0Cc51aA1e0709'
      break
    case 'goerli':
      linkContractAddr = '0x326c977e6efc84e512bb9c30f76e30c160ed06fb'
      break
    case 'matic':
      linkContractAddr = '0xb0897686c545045afc77cf20ec7a532e3120e0f1'
      break
    case 'polygonmumbai':
      linkContractAddr = '0x326c977e6efc84e512bb9c30f76e30c160ed06fb'
      break

    default:
      //default to kovan
      linkContractAddr = '0xa36085F69e2889c224210F603D836748e7dC0088'
      break
  }
  return linkContractAddr
}
// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.8.9',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0, // workaround from https://github.com/sc-forks/solidity-coverage/issues/652#issuecomment-896330136 . Remove when that issue is closed.
      chainId: 31337,
    },
    localhost: {
      url: 'http://localhost:8545',
      accounts: [
        '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
        '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
        '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a',
      ],
      chainId: 31337,
      gas: 8500000,
      gasPrice: 1000000000000,
      blockGasLimit: 124500000,
    },
    ropsten: {
      url: process.env.ROPSTEN_URL || '',
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      gas: 2100000,
      gasPrice: 199000000000,
    },
    harmonymain: {
      url: 'https://api.harmony.one',
      accounts: [privateKey],
      chainId: 1666600000,
      gas: 8500000,
      gasPrice: 199000000000,
    },
    harmonytest: {
      url: 'https://api.s0.b.hmny.io',
      accounts: [privateKey, privateKey2],
      chainId: 1666700000,
      gas: 8500000,
      gasPrice: 31000000000,
    },
    emeraldtest: {
      url: 'https://testnet.emerald.oasis.dev',
      accounts: [privateKey, privateKey2],
      chainId: 42261,
      gas: 2984000,
      gasPrice: 'auto',
    },
    emeraldmain: {
      url: 'https://emerald.oasis.dev',
      accounts: [privateKey, privateKey2],
      chainId: 42262,
      gas: 8500000,
      gasPrice: 31000000000,
    },
    iotextest: {
      url: 'https://babel-api.testnet.iotex.io',
      accounts: [privateKey, privateKey2],
      chainId: 4690,
      gas: 8500000,
      gasPrice: 1000000000000,
    },
    iotexmain: {
      url: 'https://babel-api.mainnet.iotex.io',
      accounts: [privateKey, privateKey2],
      chainId: 4689,
      gas: 8500000,
      gasPrice: 1000000000000,
    },
    polygonmumbai: {
      // Infura
      // url: `https://polygon-mumbai.infura.io/v3/${infuraId}`,
      url: `https://polygon-mumbai.g.alchemy.com/v2/${infuraId}`,
      accounts: [privateKey, privateKey2],
      gas: 8500000,
      gasPrice: 31000000000,
      timeout: 120000,
    },
    avalanchefuji: {
      // Infura
      // url: `https://polygon-mumbai.infura.io/v3/${infuraId}`,
      url: `https://api.avax-test.network/ext/bc/C/rpc`,
      accounts: [privateKey, privateKey2],
      gas: 8000000,
      chainId: 43113,
      gasPrice: 225000000000, // 225 Gwei
      timeout: 120000,
    },

    matic: {
      // Infura
      // url: `https://polygon-mainnet.infura.io/v3/${infuraId}`,
      url: 'https://rpc-mainnet.maticvigil.com',
      accounts: [privateKey],
      gas: 8500000,
      gasPrice: 199000000000,
      timeout: 60000,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD',
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
}
