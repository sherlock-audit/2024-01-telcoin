import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { StakingRewardsManager, StakingRewardsFactory, StakingRewards, TestToken } from "../../typechain-types";

describe("StakingRewards and StakingRewardsFactory", () => {
    let deployer: SignerWithAddress;
    let user: SignerWithAddress;
    let newOwner: SignerWithAddress;
    let stakingRewardsManager: StakingRewardsManager;
    let stakingRewardsFactory: StakingRewardsFactory;
    let stakingRewards: StakingRewards;
    let rewardToken: TestToken;
    let stakingToken: TestToken;

    const BUILDER_ROLE: string = ethers.keccak256(ethers.toUtf8Bytes("BUILDER_ROLE"));
    const MAINTAINER_ROLE: string = ethers.keccak256(ethers.toUtf8Bytes("MAINTAINER_ROLE"));
    const SUPPORT_ROLE: string = ethers.keccak256(ethers.toUtf8Bytes("SUPPORT_ROLE"));
    const ADMIN_ROLE: string = ethers.keccak256(ethers.toUtf8Bytes("ADMIN_ROLE"));
    const EXECUTOR_ROLE: string = ethers.keccak256(ethers.toUtf8Bytes("EXECUTOR_ROLE"));

    beforeEach("setup", async () => {
        [deployer, user, newOwner] = await ethers.getSigners();

        const TestTokenFactory = await ethers.getContractFactory("TestToken", deployer);
        rewardToken = await TestTokenFactory.deploy(deployer.address);
        stakingToken = await TestTokenFactory.deploy(deployer.address);

        const StakingRewardsFactory = await ethers.getContractFactory("StakingRewards", deployer);
        stakingRewards = await StakingRewardsFactory.deploy(deployer.address, rewardToken.getAddress(), stakingToken.getAddress());

        const StakingRewardsFactoryFactory = await ethers.getContractFactory("StakingRewardsFactory", deployer);
        stakingRewardsFactory = await StakingRewardsFactoryFactory.deploy(await stakingRewards.getAddress());

        const StakingRewardsManager = await ethers.getContractFactory("StakingRewardsManager", deployer);
        stakingRewardsManager = await StakingRewardsManager.deploy();
        await stakingRewardsManager.initialize(await rewardToken.getAddress(), await stakingRewardsFactory.getAddress());

        await stakingRewardsManager.grantRole(BUILDER_ROLE, deployer.address);
        await stakingRewardsManager.grantRole(MAINTAINER_ROLE, deployer.address);
        await stakingRewardsManager.grantRole(SUPPORT_ROLE, deployer.address);
        await stakingRewardsManager.grantRole(ADMIN_ROLE, deployer.address);
        await stakingRewardsManager.grantRole(EXECUTOR_ROLE, deployer.address);

        await stakingRewardsFactory.transferOwnership(await stakingRewardsManager.getAddress());
        await stakingRewards.transferOwnership(await stakingRewardsManager.getAddress());
    });

    describe("Static Values", () => {
        describe("Static Values", () => {
            it("BUILDER_ROLE", async () => {
                expect(await stakingRewardsManager.BUILDER_ROLE()).to.equal(BUILDER_ROLE);
            });

            it("MAINTAINER_ROLE", async () => {
                expect(await stakingRewardsManager.MAINTAINER_ROLE()).to.equal(MAINTAINER_ROLE);
            });

            it("SUPPORT_ROLE", async () => {
                expect(await stakingRewardsManager.SUPPORT_ROLE()).to.equal(SUPPORT_ROLE);
            });

            it("ADMIN_ROLE", async () => {
                expect(await stakingRewardsManager.ADMIN_ROLE()).to.equal(ADMIN_ROLE);
            });

            it("EXECUTOR_ROLE", async () => {
                expect(await stakingRewardsManager.EXECUTOR_ROLE()).to.equal(EXECUTOR_ROLE);
            });

            it("rewardToken", async () => {
                expect(await stakingRewardsManager.rewardToken()).to.equal(await rewardToken.getAddress());
            });

            it("stakingRewardsFactory", async () => {
                expect(await stakingRewardsManager.stakingRewardsFactory()).to.equal(await stakingRewardsFactory.getAddress());
            });
        });

        describe("Dynamic Values", () => {
            it("update factory", async () => {
                const StakingRewardsFactoryFactory = await ethers.getContractFactory("StakingRewardsFactory", deployer);
                let newStakingRewardsFactory = await StakingRewardsFactoryFactory.deploy(await stakingRewards.getAddress());

                await expect(stakingRewardsManager.setStakingRewardsFactory(await newStakingRewardsFactory.getAddress())).emit(stakingRewardsManager, 'StakingRewardsFactoryChanged').withArgs(await newStakingRewardsFactory.getAddress());
                expect(await stakingRewardsManager.stakingRewardsFactory()).to.equal(await newStakingRewardsFactory.getAddress());
                expect(await stakingRewardsManager.stakingRewardsFactory()).to.not.equal(await stakingRewardsFactory.getAddress());
            });

            describe("setStakingConfig", function () {
                let newStakingConfig: StakingRewardsManager.StakingConfigStruct;

                beforeEach(async function () {
                    newStakingConfig = {
                        rewardsDuration: 60 * 60 * 24 * 30, // 30 days in seconds
                        rewardAmount: ethers.parseEther("500")
                    };
                });

                it("should allow MAINTAINER_ROLE to set a staking rewards contract's config", async function () {
                    await expect(stakingRewardsManager.setStakingConfig(await stakingRewards.getAddress(), newStakingConfig))
                        .to.emit(stakingRewardsManager, "StakingConfigChanged");

                    const stakingConfig = await stakingRewardsManager.stakingConfigs(await stakingRewards.getAddress());
                    expect(stakingConfig.rewardsDuration).to.equal(newStakingConfig.rewardsDuration);
                    expect(stakingConfig.rewardAmount).to.equal(newStakingConfig.rewardAmount);
                });

                it("should fail if called by a non-MAINTAINER_ROLE account", async function () {
                    await expect(stakingRewardsManager.connect(user).setStakingConfig(await stakingRewards.getAddress(), newStakingConfig))
                        .to.be.reverted;
                });
            });

            describe("transferStakingOwnership", function () {
                let newStakingConfig: StakingRewardsManager.StakingConfigStruct;

                beforeEach(async function () {
                    newStakingConfig = {
                        rewardsDuration: 60 * 60 * 24 * 30, // 30 days in seconds
                        rewardAmount: ethers.parseEther("500")
                    };

                    await stakingRewardsManager.createNewStakingRewardsContract(await stakingToken.getAddress(), newStakingConfig);
                });

                it("should allow ADMIN_ROLE to transfer staking contract ownership", async function () {
                    await stakingRewardsManager.transferStakingOwnership(await stakingRewards.getAddress(), newOwner.address);
                    expect(await stakingRewards.owner()).to.equal(newOwner.address);
                });

                it("should fail if called by a non-ADMIN_ROLE account", async function () {
                    await expect(stakingRewardsManager.connect(user).transferStakingOwnership(await stakingRewards.getAddress(), newOwner.address))
                        .to.be.reverted;
                });
            });
        });
    });

    describe("Handle staking contracts", function () {
        let newStakingConfig: StakingRewardsManager.StakingConfigStruct;

        beforeEach(async function () {
            newStakingConfig = {
                rewardsDuration: 60 * 60 * 24 * 7, // 1 week in seconds
                rewardAmount: ethers.parseEther("1000")
            };
        });

        describe("createNewStakingRewardsContract", function () {
            let newStakingToken: TestToken;

            beforeEach(async function () {
                const TestTokenFactory = await ethers.getContractFactory("TestToken", deployer);
                newStakingToken = await TestTokenFactory.deploy(deployer.address);
            });

            it("should successfully create and add a new staking rewards contract", async function () {
                await expect(stakingRewardsManager.createNewStakingRewardsContract(await newStakingToken.getAddress(), newStakingConfig))
                    .to.emit(stakingRewardsManager, "StakingAdded");

                expect(await stakingRewardsManager.stakingContractsLength()).to.equal(1);
                expect(await stakingRewardsManager.getStakingContract(0)).to.not.be.null; // will throw out of bounds error if not valid
            });

            it("should only allow accounts with BUILDER_ROLE to create a new staking rewards contract", async function () {
                await expect(stakingRewardsManager.connect(user).createNewStakingRewardsContract(await newStakingToken.getAddress(), newStakingConfig))
                    .to.be.reverted;
            });
        });

        describe("addStakingRewardsContract", function () {
            it("should successfully add a new staking rewards contract", async function () {
                await expect(stakingRewardsManager.addStakingRewardsContract(await stakingRewards.getAddress(), newStakingConfig))
                    .to.emit(stakingRewardsManager, "StakingAdded");

                expect(await stakingRewardsManager.stakingExists(await stakingRewards.getAddress())).to.be.true;
                expect((await stakingRewardsManager.stakingConfigs(await stakingRewards.getAddress())).rewardsDuration).to.equal(newStakingConfig.rewardsDuration);
                expect((await stakingRewardsManager.stakingConfigs(await stakingRewards.getAddress())).rewardAmount).to.equal(newStakingConfig.rewardAmount);
            });

            it("should revert if trying to add an existing staking rewards contract", async function () {
                await stakingRewardsManager.addStakingRewardsContract(await stakingRewards.getAddress(), newStakingConfig);
                await expect(stakingRewardsManager.addStakingRewardsContract(await stakingRewards.getAddress(), newStakingConfig))
                    .to.be.revertedWith("StakingRewardsManager: Staking contract already exists");
            });

            it("should only allow accounts with BUILDER_ROLE to create a new staking rewards contract", async function () {
                await expect(stakingRewardsManager.connect(user).addStakingRewardsContract(await stakingRewards.getAddress(), newStakingConfig))
                    .to.be.reverted;
            });
        });

        describe("removeStakingRewardsContract", function () {
            let initialStakingContractsCount: bigint;

            beforeEach(async function () {
                await stakingRewardsManager.createNewStakingRewardsContract(await stakingToken.getAddress(), newStakingConfig);
                initialStakingContractsCount = BigInt(await stakingRewardsManager.stakingContractsLength());
            });

            it("should successfully remove a staking rewards contract", async function () {
                const indexToRemove: bigint = initialStakingContractsCount - BigInt(1);
                const stakingContractToRemove = await stakingRewardsManager.getStakingContract(indexToRemove);

                await expect(stakingRewardsManager.removeStakingRewardsContract(indexToRemove))
                    .to.emit(stakingRewardsManager, "StakingRemoved")
                    .withArgs(stakingContractToRemove);

                expect(await stakingRewardsManager.stakingContractsLength()).to.equal(indexToRemove);
                expect(await stakingRewardsManager.stakingExists(stakingContractToRemove)).to.be.false;
            });

            it("should only allow accounts with BUILDER_ROLE to remove a staking rewards contract", async function () {
                await expect(stakingRewardsManager.connect(user).removeStakingRewardsContract(initialStakingContractsCount - BigInt(1)))
                    .to.be.reverted;
            });

            it("should revert when trying to remove a contract with an invalid index", async function () {
                await expect(stakingRewardsManager.removeStakingRewardsContract(initialStakingContractsCount))
                    .to.be.reverted;
            });
        });
    });

    describe("recovery", function () {
        describe("recoverERC20FromStaking", function () {
            let tokenAmount: number = 100;

            it("should allow SUPPORT_ROLE to recover ERC20 tokens from a staking contract", async function () {
                await rewardToken.transfer(await stakingRewards.getAddress(), tokenAmount);
                expect(await rewardToken.balanceOf(await stakingRewards.getAddress())).to.equal(tokenAmount);
                expect(await rewardToken.balanceOf(user.address)).to.equal(0);
                await stakingRewardsManager.recoverERC20FromStaking(await stakingRewards.getAddress(), await rewardToken.getAddress(), tokenAmount, user.address);
                expect(await rewardToken.balanceOf(await stakingRewards.getAddress())).to.equal(0);
                expect(await rewardToken.balanceOf(user.address)).to.equal(tokenAmount);
            });

            it("should fail if called by a non-SUPPORT_ROLE account", async function () {
                await expect(stakingRewardsManager.connect(user).recoverERC20FromStaking(await stakingRewards.getAddress(), await rewardToken.getAddress(), tokenAmount, user.address))
                    .to.be.reverted;
            });
        });

        describe("recoverERC20", function () {
            let tokenAmount: number = 100;

            it("should allow SUPPORT_ROLE to recover ERC20 tokens from the contract", async function () {
                await rewardToken.transfer(await stakingRewardsManager.getAddress(), tokenAmount);
                expect(await rewardToken.balanceOf(await stakingRewardsManager.getAddress())).to.equal(tokenAmount);
                expect(await rewardToken.balanceOf(user.address)).to.equal(0);
                await stakingRewardsManager.recoverERC20(await rewardToken.getAddress(), tokenAmount, user.address);
                expect(await rewardToken.balanceOf(await stakingRewardsManager.getAddress())).to.equal(0);
                expect(await rewardToken.balanceOf(user.address)).to.equal(tokenAmount);
            });

            it("should fail if called by a non-SUPPORT_ROLE account", async function () {
                await expect(stakingRewardsManager.connect(user).recoverERC20(await stakingRewardsManager.getAddress(), tokenAmount, user.address))
                    .to.be.reverted;
            });
        });
    });

    describe("topUp", function () {
        let newStakingConfig: StakingRewardsManager.StakingConfigStruct = {
            rewardsDuration: 60 * 60 * 24 * 7, // 1 week in seconds
            rewardAmount: 100
        };

        let indices: number[] = [0, 1];
        let tokenAmount: number = 100;

        it("should allow EXECUTOR_ROLE to top up multiple staking contracts", async function () {
            await rewardToken.connect(deployer).approve(await stakingRewardsManager.getAddress(), tokenAmount * indices.length);

            await stakingRewardsManager.createNewStakingRewardsContract(await stakingToken.getAddress(), newStakingConfig);
            await stakingRewardsManager.createNewStakingRewardsContract(await stakingToken.getAddress(), newStakingConfig);

            await expect(stakingRewardsManager.connect(deployer).topUp(await deployer.address, indices))
                .to.emit(stakingRewardsManager, "ToppedUp");

            for (let index of indices) {
                let stakingContract = await stakingRewardsManager.stakingContracts(index);
                expect(await rewardToken.balanceOf(stakingContract)).to.equal(tokenAmount);
            }
        });

        it("should fail if called by a non-EXECUTOR_ROLE account", async function () {
            await expect(stakingRewardsManager.connect(user).topUp(user.address, indices)).to.be.reverted;
        });
    });
});
