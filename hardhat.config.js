require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-web3")
require("hardhat-gas-reporter");
require("solidity-coverage"); 
require("hardhat-deploy")
require('dotenv').config()

// require("./helper-hardhat-config")

const fs = require("fs");
const { task } = require("hardhat/config");
const privateKey = fs.readFileSync(".secret").toString().trim() || "01234567890123456789";
const privateKey2 = fs.readFileSync(".secret2").toString().trim() || "01234567890123456789";
const infuraId = fs.readFileSync(".infuraid").toString().trim() || "";

const LINK_TOKEN_ABI = [{ "inputs": [{ "internalType": "address", "name": "recipient", "type": "address" }, { "internalType": "uint256", "name": "amount", "type": "uint256" }], "name": "transfer", "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }], "stateMutability": "nonpayable", "type": "function" }]

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task("balance", "Prints an account's balance")
   .addParam("account", "The account's address")
   .setAction(async taskArgs => {
     const account = web3.utils.toChecksumAddress(taskArgs.account)
     const balance = await web3.eth.getBalance(account)
 
     console.log(web3.utils.fromWei(balance, "ether"), "ETH")
   })

task("link-balance", "Check LINK balance of address")
.addOptionalParam("address", "The address to check")
.setAction(async taskArgs => {
      //Create connection to LINK token contract and initiate the transfer
      const address = taskArgs.address || await hre.ethers.getSigners()[0]
      const linkContractAddr = getLinkContractAddress()
      const linkTokenContract = new ethers.Contract(linkContractAddr, LINK_TOKEN_ABI)
      var result = await linkTokenContract.balance(address)
      console.log(`Link token balance of ${address} is `, result.toString())
})
 
//  module.exports = {}
 
 task("fund-link", "Funds a contract with LINK")
   .addParam("contract", "The address of the contract that requires LINK")
   .addOptionalParam("link", "Set the LINK token address")
   .setAction(async taskArgs => {
     const contractAddr = taskArgs.contract
     const networkId = network.name
     console.log("Funding contract ", contractAddr, " on network ", networkId)
     linkContractAddr = getLinkContractAddress()

     console.log('link contract address is ', linkContractAddr)
     
     //Fund with 1 LINK token
     const amount = web3.utils.toHex(1e17)
 
     //Get signer information
     const accounts = await hre.ethers.getSigners()
     const signer = accounts[0]
     console.log('sending from ', signer.address)
 
     //Create connection to LINK token contract and initiate the transfer
     const linkTokenContract = new ethers.Contract(linkContractAddr, LINK_TOKEN_ABI, signer)
     var result = await linkTokenContract.transfer(contractAddr, amount).then(function (transaction) {
       console.log('Contract ', contractAddr, ' funded with 0.1 LINK. Transaction Hash: ', transaction.hash)
     })
   })
 
 task("request-data", "Calls an API Consumer Contract to request external data")
   .addParam("contract", "The address of the API Consumer contract that you want to call")
   .addOptionalParam("oracle", "Oracle contract address", '0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e')
   .addOptionalParam("jobId", "Job Id of the job you wish to use", "29fa9aa13bf1468788b7cc4a500a45b8")
   .addOptionalParam("payment", "Payment in LINK tokens required", '1000000000000000000')
   .addOptionalParam("url", "URL to access", 'https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=USD')
   .addOptionalParam("path", "JSON path to traverse", 'USD')
   .addOptionalParam("times", "Multiplier if using an integer", '100')
   .setAction(async taskArgs => {
 
     const contractAddr = taskArgs.contract
     const networkId = network.name
     console.log("Calling API Consumer contract ", contractAddr, " on network ", networkId)
     const API_CONSUMER_ABI = [{ "inputs": [{ "internalType": "address", "name": "_link", "type": "address" }], "stateMutability": "nonpayable", "type": "constructor" }, { "anonymous": false, "inputs": [{ "indexed": true, "internalType": "bytes32", "name": "id", "type": "bytes32" }], "name": "ChainlinkCancelled", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "internalType": "bytes32", "name": "id", "type": "bytes32" }], "name": "ChainlinkFulfilled", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "internalType": "bytes32", "name": "id", "type": "bytes32" }], "name": "ChainlinkRequested", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "internalType": "address", "name": "previousOwner", "type": "address" }, { "indexed": true, "internalType": "address", "name": "newOwner", "type": "address" }], "name": "OwnershipTransferred", "type": "event" }, { "inputs": [{ "internalType": "bytes32", "name": "_requestId", "type": "bytes32" }, { "internalType": "uint256", "name": "_payment", "type": "uint256" }, { "internalType": "bytes4", "name": "_callbackFunctionId", "type": "bytes4" }, { "internalType": "uint256", "name": "_expiration", "type": "uint256" }], "name": "cancelRequest", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "_oracle", "type": "address" }, { "internalType": "bytes32", "name": "_jobId", "type": "bytes32" }, { "internalType": "uint256", "name": "_payment", "type": "uint256" }, { "internalType": "string", "name": "_url", "type": "string" }, { "internalType": "string", "name": "_path", "type": "string" }, { "internalType": "int256", "name": "_times", "type": "int256" }], "name": "createRequestTo", "outputs": [{ "internalType": "bytes32", "name": "requestId", "type": "bytes32" }], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "data", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "bytes32", "name": "_requestId", "type": "bytes32" }, { "internalType": "uint256", "name": "_data", "type": "uint256" }], "name": "fulfill", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "getChainlinkToken", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "isOwner", "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "owner", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "newOwner", "type": "address" }], "name": "transferOwnership", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "withdrawLink", "outputs": [], "stateMutability": "nonpayable", "type": "function" }]
 
     //Get signer information
     const accounts = await hre.ethers.getSigners()
     const signer = accounts[0]
 
     //Create connection to API Consumer Contract and call the createRequestTo function
     const apiConsumerContract = new ethers.Contract(contractAddr, API_CONSUMER_ABI, signer)
     var result = await apiConsumerContract.createRequestTo(taskArgs.oracle,
       ethers.utils.toUtf8Bytes(taskArgs.jobId),
       taskArgs.payment,
       taskArgs.url,
       taskArgs.path,
       taskArgs.times).then(function (transaction) {
         console.log('Contract ', contractAddr, ' external data request successfully called. Transaction Hash: ', transaction.hash)
         console.log("Run the following to read the returned result:")
         console.log("npx hardhat read-data --contract ", contractAddr)
 
       })
   })
 
 task("read-data", "Calls an API Consumer Contract to read data obtained from an external API")
   .addParam("contract", "The address of the API Consumer contract that you want to call")
   .setAction(async taskArgs => {
 
     const contractAddr = taskArgs.contract
     const networkId = network.name
     console.log("Reading data from API Consumer contract ", contractAddr, " on network ", networkId)
     const API_CONSUMER_ABI = [{ "inputs": [{ "internalType": "address", "name": "_link", "type": "address" }], "stateMutability": "nonpayable", "type": "constructor" }, { "anonymous": false, "inputs": [{ "indexed": true, "internalType": "bytes32", "name": "id", "type": "bytes32" }], "name": "ChainlinkCancelled", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "internalType": "bytes32", "name": "id", "type": "bytes32" }], "name": "ChainlinkFulfilled", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "internalType": "bytes32", "name": "id", "type": "bytes32" }], "name": "ChainlinkRequested", "type": "event" }, { "anonymous": false, "inputs": [{ "indexed": true, "internalType": "address", "name": "previousOwner", "type": "address" }, { "indexed": true, "internalType": "address", "name": "newOwner", "type": "address" }], "name": "OwnershipTransferred", "type": "event" }, { "inputs": [{ "internalType": "bytes32", "name": "_requestId", "type": "bytes32" }, { "internalType": "uint256", "name": "_payment", "type": "uint256" }, { "internalType": "bytes4", "name": "_callbackFunctionId", "type": "bytes4" }, { "internalType": "uint256", "name": "_expiration", "type": "uint256" }], "name": "cancelRequest", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "_oracle", "type": "address" }, { "internalType": "bytes32", "name": "_jobId", "type": "bytes32" }, { "internalType": "uint256", "name": "_payment", "type": "uint256" }, { "internalType": "string", "name": "_url", "type": "string" }, { "internalType": "string", "name": "_path", "type": "string" }, { "internalType": "int256", "name": "_times", "type": "int256" }], "name": "createRequestTo", "outputs": [{ "internalType": "bytes32", "name": "requestId", "type": "bytes32" }], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "data", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "bytes32", "name": "_requestId", "type": "bytes32" }, { "internalType": "uint256", "name": "_data", "type": "uint256" }], "name": "fulfill", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "getChainlinkToken", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "isOwner", "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "owner", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "newOwner", "type": "address" }], "name": "transferOwnership", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "withdrawLink", "outputs": [], "stateMutability": "nonpayable", "type": "function" }]
 
     //Get signer information
     const accounts = await hre.ethers.getSigners()
     const signer = accounts[0]
 
     //Create connection to API Consumer Contract and call the createRequestTo function
     const apiConsumerContract = new ethers.Contract(contractAddr, API_CONSUMER_ABI, signer)
     var result = await apiConsumerContract.data().then(function (data) {
       console.log('Data is: ', web3.utils.hexToNumber(data._hex))
     })
   })

function getLinkContractAddress() {
  const networkId = network.name
  console.log("Getting link contract address for networkId: ", networkId)

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

    default: //default to kovan
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
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0, // workaround from https://github.com/sc-forks/solidity-coverage/issues/652#issuecomment-896330136 . Remove when that issue is closed.
      chainId: 1337,
    },
    localhost: {
      url: "http://localhost:8545",
      accounts: [
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
        "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
        "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a",
      ],
      chainId: 1337,
      gas: 8500000,
      gasPrice: 1000000000000,
      blockGasLimit: 124500000,
    },
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      gas: 2100000,
      gasPrice: 1000000000000,
    },
    harmonymain: {
      url: "https://api.harmony.one",
      accounts: [privateKey],
      chainId: 1666600000,
      gas: 8500000,
      gasPrice: 31000000000,
    },
    harmonytest: {
      url: "https://api.s0.b.hmny.io",
      accounts: [privateKey, privateKey2],
      chainId: 1666700000,
      gas: 8500000,
      gasPrice: 31000000000,
    },
    emeraldtest: {
      url: "https://testnet.emerald.oasis.dev",
      accounts: [privateKey, privateKey2],
      chainId: 42261,
      gas: 2984000,
      gasPrice: "auto",
    },
    emeraldmain: {
      url: "https://emerald.oasis.dev",
      accounts: [privateKey, privateKey2],
      chainId: 42262,
      gas: 8500000,
      gasPrice: 31000000000,
    },
    iotextest: {
      url: "https://babel-api.testnet.iotex.io",
      accounts: [privateKey, privateKey2],
      chainId: 4690,
      gas: 8500000,
      gasPrice: 31000000000,
    },
    iotexmain: {
      url: "https://babel-api.mainnet.iotex.io",
      accounts: [privateKey, privateKey2],
      chainId: 4689,
      gas: 8500000,
      gasPrice: 31000000000,
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
      gasPrice: 31000000000,
      timeout: 120000,
    },

    matic: {
      // Infura
      // url: `https://polygon-mainnet.infura.io/v3/${infuraId}`,
      url: "https://rpc-mainnet.maticvigil.com",
      accounts: [privateKey],
      gas: 8500000,
      gasPrice: 31000000000,
      timeout: 60000,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
