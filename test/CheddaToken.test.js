// const { expect } = require("chai");
const { expect } = require('chai')
const { BigNumber } = require('ethers')
const { ethers, network } = require('hardhat')

let chedda
let xChedda
let account0
let account1

beforeEach(async function () {
  const signers = await ethers.getSigners()
  ;[account0, account1] = [signers[0], signers[1]]

  const Chedda = await ethers.getContractFactory('Chedda')
  chedda = await Chedda.deploy(account0.address)

  const StakedChedda = await ethers.getContractFactory('StakedChedda')
  xChedda = await StakedChedda.deploy(chedda.address)

  await chedda.setVault(xChedda.address)
})

describe('Chedda', () => {
  it('Check total supply and token vault', async () => {
    const totalSupply = await chedda.totalSupply()
    console.log('totalSupply = ', ethers.utils.formatEther(totalSupply))
    expect(totalSupply).to.not.equal(BigNumber.from(0))

    const tokenVault = await chedda.tokenVault()
    expect(tokenVault).to.equal(xChedda.address)

    const apr = await chedda.apr()
    console.log('apr = ', apr)
  })

  it('Can mint new tokens to staking vault', async () => {
    // mine some blocks to move time past start
    await network.provider.send('evm_increaseTime', [3600])
    await network.provider.send('evm_mine')

    const initialTotalSupply = await chedda.totalSupply()
    await chedda.rebase()
    const newTotalSupply = await chedda.totalSupply()
    console.log('newtotalSupply = ', ethers.utils.formatEther(newTotalSupply))
    await expect(newTotalSupply.gt(initialTotalSupply)).to.be.true
    const vaultBalance = await chedda.balanceOf(xChedda.address)
    expect(vaultBalance).to.equal(newTotalSupply.sub(initialTotalSupply))
  })

  it('Can stake tokens', async () => {
    const initialBalance = ethers.utils.parseEther('1000000')
    await chedda.transfer(account1.address, initialBalance)

    const balanceOfAccount1 = await chedda.balanceOf(account1.address)
    expect(balanceOfAccount1).to.equal(initialBalance)
    console.log(
      'balanceOfACcount1 = ',
      ethers.utils.formatEther(balanceOfAccount1)
    )

    await chedda.connect(account1).approve(xChedda.address, initialBalance)
    await xChedda.connect(account1).stake(initialBalance)

    const vaultShares = await xChedda.balanceOf(account1.address)
    console.log('vaultShares = ', vaultShares)

    const newBalance = await chedda.balanceOf(account1.address)
    expect(newBalance).to.equal(BigNumber.from(0))
    console.log('newBalance = ', newBalance)

    // mine some blocks to move time past start
    await network.provider.send('evm_increaseTime', [3600])
    await network.provider.send('evm_mine')

    await xChedda.connect(account1).unstake(vaultShares)
    const balanceAfterUnstake = await chedda.balanceOf(account1.address)
    console.log(
      'balanceAfterUnstake = ',
      ethers.utils.formatEther(balanceAfterUnstake)
    )
    expect(balanceAfterUnstake.gt(initialBalance)).to.equal(true)
  })
})
