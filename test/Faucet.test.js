// const { expect } = require("chai");
const { expect } = require('chai')
const { ethers } = require('hardhat')

let token
let account0
let account1
let faucet

beforeEach(async function () {
  const signers = await ethers.getSigners()
  ;[account0, account1] = [signers[0], signers[1]]

  const Token = await ethers.getContractFactory('Token')
  token = await Token.deploy('My Token', 'TOKEN')

  const Faucet = await ethers.getContractFactory('Faucet')
  faucet = await Faucet.deploy()
})

describe('Faucet', () => {
  it('can fill', async () => {
    const amount0 = ethers.utils.parseUnits('10000', 'ether')

    await token.approve(faucet.address, amount0)
    await faucet.fill(token.address, amount0)
    const balanceOfFaucet = await faucet.balanceOf(token.address)
    console.log('balanceOfFaucet = ', balanceOfFaucet)
    expect(balanceOfFaucet).to.equal(amount0)

    const amountToDrip = await faucet.amountToDrip()
    await faucet.connect(account1).drip(token.address)
    const balanceOfAccount1 = await token.balanceOf(account1.address)
    console.log('balanceOfAccount1 = ', balanceOfAccount1)
    expect(balanceOfAccount1).to.equal(amountToDrip)
  })
})
