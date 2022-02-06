const { expect } = require("chai");
const { ethers } = require("hardhat");

let MarketNFT;
let nft;
let signer0;
let borrower;
let lender;
let loanManager
let token

const provider = new ethers.providers.JsonRpcProvider()
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

  CheddaLoanManager = await ethers.getContractFactory("CheddaLoanManager")
  loanManager = await CheddaLoanManager.deploy(token.address)

  await nft.connect(borrower).approve(loanManager.address, 1)
});

describe("CheddaLoanManager", function() {
    it("Can request a loan", async function() {
        console.log('requesting a loan')
        await loanManager.connect(borrower).requestLoan(nft.address, tokenId, amount, duration)
        let loanRequests = await loanManager.getLoanRequests(borrower.address, 0)
        expect(loanRequests.length).to.equal(1)
        let allLoanRequests = await loanManager.getLoanRequests(ethers.constants.AddressZero, 0)
        console.log('allRequests = ', allLoanRequests)
    })

    it("Can cancel loan request", async function() {
        const amount = ethers.utils.parseUnits("100", "ether")
        await loanManager.connect(borrower).requestLoan(nft.address, tokenId, amount, duration)
        let openRequests = await loanManager.getLoanRequests(borrower.address, 1) // open requests
        let cancelledRequests = await loanManager.getLoanRequests(borrower.address, 2) // open requests
        expect(openRequests.length).to.equal(1)
        expect(cancelledRequests.length).to.equal(0)

        await loanManager.connect(borrower).cancelRequest(openRequests[0].requestID)
        openRequests = await loanManager.getLoanRequests(borrower.address, 1) // open requests
        cancelledRequests = await loanManager.getLoanRequests(borrower.address, 2) // open requests
        expect(openRequests.length).to.equal(0)
        expect(cancelledRequests.length).to.equal(1)
    })

    it("Can open a loan in native currency", async function() {
        await loanManager.connect(borrower).requestLoan(nft.address, tokenId, amount, duration)
        const openRequests = await loanManager.getLoanRequests(borrower.address, 1)
        await loanManager.connect(lender).openLoan(openRequests[0].requestID, {value: amount})

        let loansBorrowed = await loanManager.getLoansBorrowed(borrower.address, 0)
        let loansLent = await loanManager.getLoansLent(borrower.address, 0)

        expect(loansBorrowed.length).to.equal(1)
        expect(loansLent.length).to.equal(0)

        loansLent = await loanManager.getLoansLent(lender.address, 0)
        expect(loansLent.length).to.equal(1)
    }) 

    it("Can get the repayment amount", async function() {
        const repaymentAmount = await loanManager.calculateRepaymentAmount(ethers.utils.parseUnits("100", "ether"), 7 * 86400)
        console.log('repaymentAmount = ', ethers.utils.parseEther(repaymentAmount.toString()))
    })
    
    it("Can repay a loan in token", async function() {
        await loanManager.connect(borrower).requestLoan(nft.address, tokenId, amount, duration)
        await token.connect(lender).approve(loanManager.address, amount)
        let initialBalance = await token.balanceOf(lender.address)
        const openRequests = await loanManager.getLoanRequests(borrower.address, 1)
        await loanManager.connect(lender).openLoanToken(openRequests[0].requestID)

        let balanceAfterOpen = await token.balanceOf(lender.address)
        let loans = await loanManager.connect(borrower).getLoansBorrowed(borrower.address, 0)
        let loan =  loans[0]

        expect(balanceAfterOpen).to.equal(initialBalance.sub(loan.principal))

        // repay
        await token.connect(borrower).approve(loanManager.address, loan.repaymentAmount.toString())
        await loanManager.connect(borrower).repayToken(loan.loanID)
        let balanceAfterClose = await token.balanceOf(lender.address)
        expect(balanceAfterClose).to.equal(balanceAfterOpen.add(loan.repaymentAmount))
    })

    it("Can repay a loan in native currency", async function() {
      await loanManager.connect(borrower).requestLoan(nft.address, tokenId, amount, duration)
      let initialBalance = await provider.getBalance(lender.address)
      const openRequests = await loanManager.getLoanRequests(borrower.address, 1)
      await loanManager.connect(lender).openLoan(openRequests[0].requestID, {value: amount})

      let balanceAfterOpen = await provider.getBalance(lender.address)
      let loans = await loanManager.connect(borrower).getLoansBorrowed(borrower.address, 0)
      let loan =  loans[0]

      // repay
      await loanManager.connect(borrower).repay(loan.loanID, {value: loan.repaymentAmount})
      let balanceAfterClose = await provider.getBalance(lender.address)
      // can't use equality since balanceAfterOpen will be balanceAfterClose + repaymentAmount - gas
      expect(balanceAfterClose.gt(balanceAfterOpen)).to.be.true
    })

    it("Can foreclose a loan", async function() {
        await loanManager.connect(borrower).requestLoan(nft.address, tokenId, amount, 1)
        await token.connect(lender).approve(loanManager.address, amount)
        let lenderBalance = await token.balanceOf(lender.address)
        const openRequests = await loanManager.getLoanRequests(borrower.address, 1)
        await loanManager.connect(lender).openLoan(openRequests[0].requestID, {value: amount})

        await timeout(2000)
        let loans = await loanManager.connect(borrower).getLoansBorrowed(borrower.address, 0)
        const loan = loans[0]
        await loanManager.connect(lender).foreclose(loan.loanID)
        let newOwner = await nft.ownerOf(1)
        expect(newOwner).to.equal(lender.address)
    })

    it("Can get open loan requests on an nft", async function() {
        const amount = ethers.utils.parseUnits("100", "ether")
        await loanManager.connect(borrower).requestLoan(nft.address, tokenId, amount, duration)
        let openRequests = await loanManager.getLoanRequests(borrower.address, 1) // open requests 
        expect(openRequests.length).to.equal(1)
        let openRequestId = await loanManager.openRequests(nft.address, tokenId)
        let loanRequest = await loanManager.requests(openRequestId)
        expect(loanRequest.requestID).to.equal(openRequestId)
        expect(loanRequest.amount).to.equal(amount)
        expect(loanRequest.tokenID).to.equal(tokenId)
        expect(loanRequest.borrower).to.equal(borrower.address)
    })
})

function timeout(ms) {
    return new Promise(resolve => setTimeout(resolve, ms))
}
