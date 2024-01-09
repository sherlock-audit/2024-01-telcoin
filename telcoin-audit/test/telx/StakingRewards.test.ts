import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { TestToken, StakingRewards } from "../../typechain-types";

describe("StakingRewards", function () {
    let deployer: SignerWithAddress;
    let stakerOne: SignerWithAddress;
    let stakerTwo: SignerWithAddress;
    let recover: SignerWithAddress;

    let rewardsToken: TestToken;
    let stakingToken: TestToken;
    let stakingRewards: StakingRewards;

    let currentTime: bigint;

    const REWARD_AMOUNT = ethers.parseEther("100");
    const STAKE_AMOUNT = ethers.parseEther("50");
    const SEVEN_DAYS_IN_SECONDS = 604800n;

    beforeEach(async function () {
        [deployer, stakerOne, stakerTwo, recover] = await ethers.getSigners();

        const TokenFactory = await ethers.getContractFactory("TestToken");
        rewardsToken = await TokenFactory.deploy(deployer.address);
        stakingToken = await TokenFactory.deploy(deployer.address);

        const StakingRewards = await ethers.getContractFactory("StakingRewards");
        stakingRewards = await StakingRewards.deploy(deployer.address, await rewardsToken.getAddress(), await stakingToken.getAddress());

        await stakingToken.connect(deployer).transfer(stakerOne.address, STAKE_AMOUNT);
        await stakingToken.connect(deployer).transfer(stakerTwo.address, STAKE_AMOUNT);

        await stakingToken.connect(stakerOne).approve(await stakingRewards.getAddress(), STAKE_AMOUNT);
        await stakingToken.connect(stakerTwo).approve(await stakingRewards.getAddress(), STAKE_AMOUNT);

        await rewardsToken.connect(deployer).transfer(await stakingRewards.getAddress(), REWARD_AMOUNT);
    });

    describe("View Values", () => {
        beforeEach(async function () {
            await stakingRewards.connect(stakerOne).stake(STAKE_AMOUNT);
            await stakingRewards.notifyRewardAmount(REWARD_AMOUNT);
            currentTime = BigInt((await ethers.provider.getBlock('latest'))!.timestamp)
        });

        it("rewardsToken", async () => {
            expect(await stakingRewards.rewardsToken()).to.equal(await rewardsToken.getAddress());
        });

        it("stakingToken", async () => {
            expect(await stakingRewards.stakingToken()).to.equal(await stakingToken.getAddress());
        });

        it("periodFinish", async () => {
            expect(await stakingRewards.periodFinish()).to.equal(currentTime + SEVEN_DAYS_IN_SECONDS);
        });

        it("rewardsDuration", async () => {
            expect(await stakingRewards.rewardsDuration()).to.equal(SEVEN_DAYS_IN_SECONDS);
        });

        it("lastUpdateTime", async () => {
            expect(await stakingRewards.lastUpdateTime()).to.equal(currentTime);
        });

        it("lastTimeRewardApplicable", async () => {
            expect(await stakingRewards.lastTimeRewardApplicable()).to.equal(currentTime);
        });

        it("totalSupply", async () => {
            expect(await stakingRewards.totalSupply()).to.equal(STAKE_AMOUNT);
        });

        it("balanceOf", async () => {
            expect(await stakingRewards.balanceOf(stakerOne.address)).to.equal(STAKE_AMOUNT);
        });

        it("getRewardForDuration", async () => {
            expect(await stakingRewards.getRewardForDuration()).to.be.lessThanOrEqual(REWARD_AMOUNT);
        });

        describe("View Values with time", () => {
            beforeEach(async function () {
                await ethers.provider.send("evm_increaseTime", [Number(SEVEN_DAYS_IN_SECONDS) / 2]);
                await ethers.provider.send("evm_mine");
            });

            it("rewardRate", async () => {
                await expect(stakingRewards.rewardRate()).to.exist;
            });

            it("rewardPerToken", async () => {
                expect(await stakingRewards.rewardPerToken()).to.be.lessThanOrEqual(REWARD_AMOUNT / BigInt(2));
            });

            it("rewardPerTokenStored", async () => {
                await stakingRewards.connect(stakerTwo).stake(STAKE_AMOUNT);
                await expect(stakingRewards.rewardPerTokenStored()).to.exist;
            });
        })
    });

    describe("mutative", () => {
        it("Should allow staking of tokens", async function () {
            await expect(stakingRewards.connect(stakerOne).stake(STAKE_AMOUNT)).to.emit(stakingRewards, 'Staked');
        });

        describe("Zero Values", () => {
            it("Should not allow staking of tokens", async function () {
                await expect(stakingRewards.connect(stakerOne).stake(0)).to.revertedWith('Cannot stake 0');
            });

            it("Should not allow withdrawal of tokens", async function () {
                await expect(stakingRewards.connect(stakerOne).withdraw(0)).to.revertedWith('Cannot withdraw 0');
            });

            it("Should allow getting reward tokens", async function () {
                await expect(stakingRewards.connect(stakerOne).getReward()).to.not.reverted;
            });
        });

        describe("Live Values", () => {
            beforeEach(async function () {
                await stakingRewards.connect(stakerOne).stake(STAKE_AMOUNT);
                await stakingRewards.connect(stakerTwo).stake(STAKE_AMOUNT);
                await stakingRewards.notifyRewardAmount(REWARD_AMOUNT);
                await ethers.provider.send("evm_increaseTime", [Number(SEVEN_DAYS_IN_SECONDS)]);
                await ethers.provider.send("evm_mine");
            });

            it("equal earnings", async function () {
                expect(await stakingRewards.earned(stakerOne.address)).to.equal(await stakingRewards.getRewardForDuration() / BigInt(2));
                expect(await stakingRewards.earned(stakerTwo.address)).to.equal(await stakingRewards.getRewardForDuration() / BigInt(2));
            });

            it("Should allow withdrawal of tokens", async function () {
                await expect(stakingRewards.connect(stakerOne).withdraw(STAKE_AMOUNT)).to.emit(stakingRewards, 'Withdrawn');
                expect(await stakingToken.balanceOf(stakerOne.address)).to.equal(STAKE_AMOUNT);
            });

            it("Should allow getting reward tokens", async function () {
                await expect(stakingRewards.connect(stakerOne).getReward()).to.emit(stakingRewards, 'RewardPaid');
                expect(await rewardsToken.balanceOf(stakerOne.address)).to.equal(await stakingRewards.getRewardForDuration() / BigInt(2));
            });

            it("Should allow exit of tokens", async function () {
                await expect(stakingRewards.connect(stakerOne).exit()).to.emit(stakingRewards, 'Withdrawn').to.emit(stakingRewards, 'RewardPaid');
                expect(await stakingToken.balanceOf(stakerOne.address)).to.equal(STAKE_AMOUNT);
                expect(await rewardsToken.balanceOf(stakerOne.address)).to.equal(await stakingRewards.getRewardForDuration() / BigInt(2));
            });
        });
    });

    describe("RESTRICTED", () => {
        beforeEach(async function () {
            await rewardsToken.connect(deployer).transfer(await stakingRewards.getAddress(), REWARD_AMOUNT);
        });

        it("recoverERC20", async function () {
            await expect(stakingRewards.connect(deployer).recoverERC20(recover.address, await rewardsToken.getAddress(), REWARD_AMOUNT)).to.emit(stakingRewards, 'Recovered');
            expect(await rewardsToken.balanceOf(recover.address)).to.equal(REWARD_AMOUNT);
        });

        it("setRewardsDuration", async function () {
            await expect(stakingRewards.connect(deployer).setRewardsDuration(1)).to.emit(stakingRewards, 'RewardsDurationUpdated');
            expect(await stakingRewards.rewardsDuration()).to.equal(BigInt(1));
        });

        it("setRewardsDistribution", async function () {
            await expect(stakingRewards.connect(deployer).setRewardsDistribution(recover.address)).to.emit(stakingRewards, 'RewardsDistributionUpdated');
            expect(await stakingRewards.rewardsDistribution()).to.equal(recover.address);
        });

        it("revert notifyRewardAmount", async function () {
            await expect(stakingRewards.notifyRewardAmount(REWARD_AMOUNT * BigInt(10))).to.revertedWith('Provided reward too high');
        });

        it("notifyRewardAmount", async function () {
            await expect(stakingRewards.notifyRewardAmount(REWARD_AMOUNT)).to.emit(stakingRewards, 'RewardAdded');

            await ethers.provider.send("evm_increaseTime", [1]);
            await ethers.provider.send("evm_mine");

            await expect(stakingRewards.notifyRewardAmount(REWARD_AMOUNT)).to.emit(stakingRewards, 'RewardAdded');
        });
    });
});