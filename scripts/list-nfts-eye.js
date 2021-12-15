const hre = require("hardhat");
const ethers = require("ethers")
const marketAddress = require("../addresses/market.json")
const explorerAddress = require("../addresses/market-explorer.json")

const fs = require('fs');

const geekConfig = {
    name: "Weird Geek",
    symbol: "WGK",
    metadataURI: "https://s3.amazonaws.com/chedda.store/nfts/weird-geek/metadata/_collection.json",
    baseURI: "https://s3.amazonaws.com/chedda.store/nfts/weird-geek/metadata",
}

const config = {
    name: "Fancy Eye",
    symbol: "EYE",
    metadataURI: "https://s3.amazonaws.com/chedda.store/nfts/fancy-eye/json/_collection.json",
    baseURI: "https://s3.amazonaws.com/chedda.store/nfts/fancy-eye/metadata",
}
let market
let nft
let explorer

const startIndex = 1
const endIndex = 100
let feeRecipient;
let tokenRecipient;
const mintFee = ethers.utils.parseUnits("0.001", "ether");

  // Steps:
  // 1. Deploy NFT Market
  // 2. Deploy Chedda NFT
  // 3. Loop through available json files and mint each one
  // 4. List each for sale
async function initialize() {
    const signers = await hre.ethers.getSigners();
    [feeRecipient, tokenRecipient] = [signers[0], signers[1]];
    console.log(`{feeRecipient: ${feeRecipient.address}, tokenRecipient: ${tokenRecipient.address}}`)
    
    const CheddaMarket = await hre.ethers.getContractFactory("CheddaMarket");
    market = await CheddaMarket.attach(marketAddress.market);
    console.log('CheddaMarket attached to address: ', market.address)

    const CheddaMarketExplorer = await hre.ethers.getContractFactory("CheddaMarketExplorer");
    explorer = await CheddaMarketExplorer.attach(explorerAddress.marketExplorer)
    console.log('CheddaMarketExplorer attached to address: ', explorer.address)

    const CheddaNFT = await hre.ethers.getContractFactory("CheddaNFT")
    nft = await CheddaNFT.deploy(mintFee, feeRecipient.address, config.name, config.symbol, config.metadataURI);
    await nft.deployed();
    console.log(`Deployed NFT = ${nft}`)
    return nft
}

function randomNumber() {
    return (Math.ceil( Math.random() * 20 ) + 1).toString()
}
async function listCollection(nft) {
    let txs = []
    for (let i = startIndex; i <= endIndex; i++) {
        console.log(`***** Processing index ${i}`)
        let metadataURI = getTokenURI(i)
        let tokenId = await mintNFT(tokenRecipient.address, metadataURI, mintFee)
        console.log(`*** Minted tokenID: ${JSON.stringify(tokenId)}`)
        let tx = await listNFT(nft.address, i)
        txs.push(tx)
        console.log(`*** Listed ${tokenId} => ${tx}`)
    }
    let allItems = await explorer.getAllItems()
    console.log('allItems = ', allItems)
    return txs
}

async function mintNFT(recipientAddress, tokenURI, mintFee) {
    tokenId = await nft.mint(recipientAddress, tokenURI, { value: mintFee });
    return tokenId;
}

async function listNFT(tokenAddress, tokenId) {
    await nft.connect(tokenRecipient).approve(market.address, tokenId);
    let listPrice = ethers.utils.parseUnits(randomNumber(), "ether")
    let tx = await market
      .connect(tokenRecipient)
      .listItemForSale(tokenAddress, tokenId, listPrice);
      return tx
}

function getTokenURI(tokenId) {
    return `${config.baseURI}/${tokenId}.json`
}


async function save(nft) {
    const provider = new ethers.providers.JsonRpcProvider();
    const network = await provider.getNetwork()
    let json = `
    {
      "${config.name}": "${nft.address}"
    }
  
    `
    let data = JSON.stringify(json)
    fs.writeFileSync(`${network.name}-${config.symbol}.addresses.json`, JSON.parse(data))
}

async function main() {
    let nft = await initialize()
    await listCollection(nft)
    await save(nft)
}

main()