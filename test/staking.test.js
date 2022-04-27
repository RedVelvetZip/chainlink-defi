const { inputToConfig } = require("@ethereum-waffle/compiler")
const { ethers, deployments } = require("hardhat")

describe("Staking Test", async function() {
    let staking, rewardToken, deployer, stakeAmount

    beforeEach(async function() {
        const accounts = await ethers.getSigners()
        deployer = accounts[0]
        await deployments.fixture(["all"])
        staking = await ethers.getContractAt("Staking")
        rewardToken = await ethers.getContractAt("RewardToken")
        stakeAmount = ethers.utils.parseEther("100000")
    })

    it("Allows users to stake and claim rewards", async function () {
        await rewardToken.approve(staking.address, stakeAmount)
        await staking.stake(stakeAmount)
        const startingEarned = await staking.earned(deployer.address)

        console.log(`Starting Earned ${startingEarned}`)
    })
})