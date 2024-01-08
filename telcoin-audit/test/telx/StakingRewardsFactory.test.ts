import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { StakingRewardsFactory, StakingRewards, TestToken } from "../../typechain-types";

describe("StakingRewards and StakingRewardsFactory", () => {
    let deployer: SignerWithAddress;
    let user: SignerWithAddress;
    let stakingRewardsFactory: StakingRewardsFactory;
    let stakingRewards: StakingRewards;
    let rewardToken: TestToken;
    let stakingToken: TestToken;

    beforeEach("setup", async () => {
        [deployer, user] = await ethers.getSigners();

        const TestTokenFactory = await ethers.getContractFactory("TestToken", deployer);
        rewardToken = await TestTokenFactory.deploy(deployer.address);
        stakingToken = await TestTokenFactory.deploy(deployer.address);

        const StakingRewardsFactory = await ethers.getContractFactory("StakingRewards", deployer);
        stakingRewards = await StakingRewardsFactory.deploy(deployer.address, rewardToken.getAddress(), stakingToken.getAddress());

        const StakingRewardsFactoryFactory = await ethers.getContractFactory("StakingRewardsFactory", deployer);
        stakingRewardsFactory = await StakingRewardsFactoryFactory.deploy(await stakingRewards.getAddress());
    });

    describe("Static Values", () => {
        it("stakingRewards", async () => {
            expect(await stakingRewardsFactory.stakingRewardsImplementation()).to.equal(await stakingRewards.getAddress());
        });
    });

    describe("Create", () => {
        it("should emit event", async () => {
            expect(await stakingRewardsFactory.createStakingRewards(await deployer.getAddress(), await rewardToken.getAddress(), await stakingToken.getAddress())).to.emit(stakingRewardsFactory, 'NewStakingRewardsContract');
        });

        it("verify number of contracts", async () => {
            await stakingRewardsFactory.createStakingRewards(await deployer.getAddress(), await rewardToken.getAddress(), await stakingToken.getAddress())
            expect(await stakingRewardsFactory.getStakingRewardsContractCount()).to.equal(1);
        });

        it("verify number of contracts", async () => {
            await stakingRewardsFactory.createStakingRewards(await deployer.getAddress(), await rewardToken.getAddress(), await stakingToken.getAddress())
            expect(await stakingRewardsFactory.getStakingRewardsContract(0)).not.to.equal(0x0000000000000000000000000000000000000000);
        });
    });
});
