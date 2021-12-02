require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");

const fs = require("fs");
const privateKey = fs.readFileSync(".secret").toString().trim() || "01234567890123456789";
const privateKey2 = fs.readFileSync(".secret2").toString().trim() || "01234567890123456789";
const infuraId = fs.readFileSync(".infuraid").toString().trim() || "";

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
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
      gasPrice: 1000000000000,
    },
    harmonytest: {
      url: "https://api.s0.b.hmny.io",
      accounts: [privateKey, privateKey2],
      chainId: 1666700000,
      gas: 8500000,
      gasPrice: 1000000000000,
    },
    iotextest: {
      url: "https://babel-api.testnet.iotex.io",
      accounts: [privateKey, privateKey2],
      chainId: 4690,
      gas: 8500000,
      gasPrice: 1000000000000,
    },
    iotexmain: {
      url: "https://babel-api.mainnet.iotex.io",
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
      gasPrice: 8000000000,
      gas: 2100000,
      timeout: 120000,
    },
    matic: {
      // Infura
      // url: `https://polygon-mainnet.infura.io/v3/${infuraId}`,
      url: "https://rpc-mainnet.maticvigil.com",
      accounts: [privateKey],
      gasPrice: 8000000000,
      gas: 2100000,
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
