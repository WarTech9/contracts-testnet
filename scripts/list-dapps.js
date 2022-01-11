const hre = require("hardhat");
const ethers = require("ethers")
const networkName = hre.network.name

const dapplist = require(`../dapps/${networkName}/_dapplist.json`);
const addresses = require(`../addresses/${networkName}/dappstore.json`)
let dappStore

async function initialize() {
    const CheddaStore = await hre.ethers.getContractFactory("CheddaDappStore");
    dappStore = await CheddaStore.attach(addresses.dappStore);
    console.log('dappstore deployed to address: ', dappStore.address)
}

async function main() {
    await initialize()
    await readDappList()
    await save()
}

async function save() {
    const provider = new ethers.providers.JsonRpcProvider();
    const network = await provider.getNetwork()
    console.log("network is: ", network)
}

async function readDappList() {
    let polygonDapps = dapplist[networkName]
    for (const dapp of polygonDapps) {
        console.log("Dapp => ", dapp)
        let tx = await dappStore.addDapp(
            dapp.name,
            dapp.chainId,
            dapp.contractAddress,
            dapp.category,
            dapp.metadataURI
            )
        console.log('dapp added with result: ', tx)
        await tx.wait()
        console.log('tx mined: ', tx)
    }
    let dapps = await dappStore.dapps()
    console.log('dapps are: ', dapps)
}

main()