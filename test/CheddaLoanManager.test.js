// const { expect } = require("chai");
const { expect } = require("chai");
const { ethers } = require("hardhat");

let MarketNFT;
let nft;
let signer0;
let borrower;
let lender;
let loanManager
let token

const mintFee = ethers.utils.parseUnits("0.1", "ether");
const tokenURI = "https://ipfs/token/myHash";
const metadataURI = "https://ipfs/metadata/myHash";
const tokenId = 1
const duration = 604800 // 7 days
const amount = ethers.utils.parseUnits("100", "ether")

beforeEach(async function () {
  const signers = await ethers.getSigners();
  [signer0, borrower, lender] = [signers[0], signers[1], signers[2]];
  MarketNFT = await ethers.getContractFactory("MarketNFT");
  nft = await MarketNFT.deploy(mintFee, signer0.address, metadataURI, "Chedda NFT", "CNFT");

  const Token = await ethers.getContractFactory("Token")
  token = await Token.deploy("X Token", "XT")

  await token.transfer(borrower.address, ethers.utils.parseUnits("1000", "ether"))
  await token.transfer(lender.address, ethers.utils.parseUnits("1000", "ether"))

  await nft.mint(borrower.address, tokenURI, { value: mintFee })
//   await nft.mint(borrower.address, tokenURI, { value: mintFee })
//   await nft.mint(borrower.address, tokenURI, { value: mintFee })


  CheddaLoanManager = await ethers.getContractFactory("CheddaLoanManager")
  loanManager = await CheddaLoanManager.deploy(token.address)

  await nft.connect(borrower).approve(loanManager.address, 1)
});

describe("CheddaLoanManager", function() {
    it("Can request a loan", async function() {
        console.log('requesting a loan')

        await loanManager.connect(borrower).requestLoan(nft.address, tokenId, amount, duration)
        let loanRequests = await loanManager.connect(borrower).getMyRequests(0)
        expect(loanRequests.length).to.equal(1)
    })

    it("Can cancel loan request", async function() {
        const amount = ethers.utils.parseUnits("100", "ether")
        await loanManager.connect(borrower).requestLoan(nft.address, tokenId, amount, duration)
        let openRequests = await loanManager.connect(borrower).getMyRequests(1) // open requests
        let cancelledRequests = await loanManager.connect(borrower).getMyRequests(2) // open requests
        expect(openRequests.length).to.equal(1)
        expect(cancelledRequests.length).to.equal(0)

        await loanManager.connect(borrower).cancelRequest(0)
        openRequests = await loanManager.connect(borrower).getMyRequests(1) // open requests
        cancelledRequests = await loanManager.connect(borrower).getMyRequests(2) // open requests
        expect(openRequests.length).to.equal(0)
        expect(cancelledRequests.length).to.equal(1)
    })

    it("Can open a loan", async function() {
        await loanManager.connect(borrower).requestLoan(nft.address, tokenId, amount, duration)
        await token.connect(lender).approve(loanManager.address, amount)
        let balance = await token.balanceOf(borrower.address)
        await loanManager.connect(lender).openLoan(0)

        balance = await token.balanceOf(borrower.address)
        let loansBorrowed = await loanManager.connect(borrower).getMyLoansAsBorrower(0)
        let loansLent = await loanManager.connect(borrower).getMyLoansAsLender(0)

        expect(loansBorrowed.length).to.equal(1)
        expect(loansLent.length).to.equal(0)

        loansLent = await loanManager.connect(lender).getMyLoansAsLender(0)
        expect(loansLent.length).to.equal(1)
    }) 

    it("Can get the repayment amount", async function() {
        const repaymentAmount = await loanManager.calculateRepaymentAmount(ethers.utils.parseUnits("100", "ether"), 7 * 86400)
        console.log('repaymentAmount = ', ethers.utils.parseEther(repaymentAmount.toString()))
    })

    it("Can repay a loan", async function() {
        await loanManager.connect(borrower).requestLoan(nft.address, tokenId, amount, duration)
        await token.connect(lender).approve(loanManager.address, amount)
        let initialBalance = await token.balanceOf(lender.address)
        console.log('lenderBalance before loan opened = ', initialBalance)
        await loanManager.connect(lender).openLoan(0)

        let balanceAfterOpen = await token.balanceOf(lender.address)
        console.log('lenderBalance after loan opened = ', balanceAfterOpen)
        let loans = await loanManager.connect(borrower).getMyLoansAsBorrower(0)
        let loan =  loans[0]

        expect(balanceAfterOpen).to.equal(initialBalance.sub(loan.principal))

        // repay
        await token.connect(borrower).approve(loanManager.address, loan.repaymentAmount.toString())
        await loanManager.connect(borrower).repay(0)
        let balanceAfterClose = await token.balanceOf(lender.address)
        expect(balanceAfterClose).to.equal(balanceAfterOpen.add(loan.repaymentAmount))
    })

    it("Can foreclose a loan", async function() {
        await loanManager.connect(borrower).requestLoan(nft.address, tokenId, amount, 1)
        await token.connect(lender).approve(loanManager.address, amount)
        let lenderBalance = await token.balanceOf(lender.address)
        console.log('lenderBalance before loan opened = ', lenderBalance)
        await loanManager.connect(lender).openLoan(0)

        await timeout(2000)

        await loanManager.connect(lender).foreclose(0)
        let newOwner = await nft.ownerOf(1)
        console.log('newOwner = ', newOwner)
        expect(newOwner).to.equal(lender.address)
    })
})

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
}