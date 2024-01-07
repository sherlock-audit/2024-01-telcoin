import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { TelcoinDistributor, TestNFT, TestTelcoin, TestSafeWallet } from "../../typechain-types";

describe("TelcoinDistributor", () => {
    let owner: SignerWithAddress;
    let proposer: SignerWithAddress;
    let challenger: SignerWithAddress;
    let other: SignerWithAddress;
    let telcoinDistributor: TelcoinDistributor;
    let councilNFT: TestNFT;
    let telcoin: TestTelcoin;
    let safeWallet: TestSafeWallet;

    let challengePeriod: number = 60;

    async function advanceTime(time: number) {
        await ethers.provider.send("evm_increaseTime", [time]);
        await ethers.provider.send("evm_mine");
    }

    beforeEach("setup", async () => {
        [owner, proposer, challenger, other] = await ethers.getSigners();

        const TestNFTFactory = await ethers.getContractFactory("TestNFT", owner);
        councilNFT = await TestNFTFactory.deploy();

        const TestTelcoinFactory = await ethers.getContractFactory("TestTelcoin", owner);
        telcoin = await TestTelcoinFactory.deploy(owner.address);

        const TestSafeWalletFactory = await ethers.getContractFactory("TestSafeWallet", owner);
        safeWallet = await TestSafeWalletFactory.deploy();

        const telcoinDistributorFactory = await ethers.getContractFactory("TelcoinDistributor", owner);

        telcoinDistributor = await telcoinDistributorFactory.deploy(await telcoin.getAddress(), challengePeriod, await councilNFT.getAddress());
        councilNFT.mint(proposer.address, 0);
        councilNFT.mint(challenger.address, 1);
    });

    describe("Static Values", () => {
        it("safeWallet", async () => {
            expect(await telcoinDistributor.TELCOIN()).to.equal(await telcoin.getAddress());
        });

        it("challengePeriod", async () => {
            expect(await telcoinDistributor.challengePeriod()).to.equal(60);
        });

        it("councilNft", async () => {
            expect(await telcoinDistributor.councilNft()).to.equal(await councilNFT.getAddress());
        });
    });

    describe("Set values", () => {
        it("should set challenge period successfully", async () => {
            await expect(telcoinDistributor.connect(owner).setChallengePeriod(120))
                .to.emit(telcoinDistributor, 'ChallengePeriodUpdated')
                .withArgs(120);
            expect(await telcoinDistributor.challengePeriod()).to.equal(120);
        });

        it("should pause", async () => {
            await expect(telcoinDistributor.connect(owner).pause());
        });

        it("should not pause", async () => {
            await expect(telcoinDistributor.connect(proposer).pause()).to.be.revertedWithCustomError(telcoinDistributor, "OwnableUnauthorizedAccount");
        });

        it("should unpause", async () => {
            await expect(telcoinDistributor.connect(owner).unpause());
        });

        it("should not unpause", async () => {
            await expect(telcoinDistributor.connect(proposer).unpause()).to.be.revertedWithCustomError(telcoinDistributor, "OwnableUnauthorizedAccount");
        });
    });

    describe("Propose Transaction", () => {
        it('should revert if the caller is not a council member', async () => {
            const totalWithdrawl = 1000;
            const destinations = [proposer.address];
            const amounts = [totalWithdrawl];

            await expect(telcoinDistributor.connect(other).proposeTransaction(totalWithdrawl, destinations, amounts)).to.be.revertedWith("TelcoinDistributor: Caller is not Council Member");
        });

        it('should revert if paused', async () => {
            const totalWithdrawl = 1000;
            const destinations = [proposer.address];
            const amounts = [totalWithdrawl];

            await expect(telcoinDistributor.connect(owner).pause());
            await expect(telcoinDistributor.connect(proposer).proposeTransaction(totalWithdrawl, destinations, amounts)).to.be.revertedWithCustomError(telcoinDistributor, "EnforcedPause");
        });

        it('should propose a transaction successfully and emit an event', async () => {
            const totalWithdrawl = 1000;
            const destinations = [proposer.address];
            const amounts = [totalWithdrawl];

            await expect(telcoinDistributor.connect(proposer).proposeTransaction(totalWithdrawl, destinations, amounts)).to.emit(telcoinDistributor, "TransactionProposed");
        });
    });

    describe("Challenge Transaction", () => {
        beforeEach("setup", async () => {
            const totalWithdrawl = 1000;
            const destinations = [proposer.address];
            const amounts = [totalWithdrawl];

            await expect(telcoinDistributor.connect(proposer).proposeTransaction(totalWithdrawl, destinations, amounts)).to.emit(telcoinDistributor, "TransactionProposed");
            await advanceTime(50);
        });

        it('should revert if paused', async () => {
            await expect(telcoinDistributor.connect(owner).pause());
            await expect(telcoinDistributor.connect(proposer).challengeTransaction(0)).to.be.revertedWithCustomError(telcoinDistributor, "EnforcedPause");
        });

        it('should revert if the caller is not a council member', async () => {
            await expect(telcoinDistributor.connect(other).challengeTransaction(0)).to.be.revertedWith("TelcoinDistributor: Caller is not Council Member");
        });

        it("should refuse invalid index", async () => {
            await expect(telcoinDistributor.connect(proposer).challengeTransaction(1)).revertedWith('TelcoinDistributor: Invalid index');
        });

        it("should refuse expired timestamp", async () => {
            await advanceTime(50);
            await expect(telcoinDistributor.connect(proposer).challengeTransaction(0)).revertedWith("TelcoinDistributor: Challenge period has ended");
        });

        it("should allow non-challenger transaction", async () => {
            await expect(telcoinDistributor.connect(proposer).challengeTransaction(0)).to.emit(telcoinDistributor, "TransactionChallenged");
        });
    });

    describe("Execute Transaction", () => {
        beforeEach("setup", async () => {
            const totalWithdrawl = 1000;
            const destinations = [proposer.address];
            const amounts = [totalWithdrawl];

            await expect(telcoinDistributor.connect(proposer).proposeTransaction(totalWithdrawl, destinations, amounts)).to.emit(telcoinDistributor, "TransactionProposed");
            await advanceTime(50);
        });

        it('should revert if the caller is not a council member', async () => {
            await advanceTime(50);
            await expect(telcoinDistributor.connect(other).executeTransaction(0)).to.be.revertedWith("TelcoinDistributor: Caller is not Council Member");
        });

        it('should revert if paused', async () => {
            await expect(telcoinDistributor.connect(owner).pause());
            await expect(telcoinDistributor.connect(proposer).executeTransaction(0)).to.be.revertedWithCustomError(telcoinDistributor, "EnforcedPause");
        });

        it('should revert if invalid index', async () => {
            await advanceTime(50);
            await expect(telcoinDistributor.connect(proposer).executeTransaction(1)).to.be.revertedWith("TelcoinDistributor: Invalid index");
        });

        it('should revert if challenged', async () => {
            await expect(telcoinDistributor.connect(proposer).challengeTransaction(0)).to.be.not.reverted;
            await advanceTime(50);
            await expect(telcoinDistributor.connect(proposer).executeTransaction(0)).to.be.revertedWith("TelcoinDistributor: transaction has been challenged");
        });

        it('should revert if challenge period is ongoing', async () => {
            await expect(telcoinDistributor.connect(proposer).executeTransaction(0)).to.be.revertedWith("TelcoinDistributor: Challenge period has not ended");
        });

        it('should revert if already executed', async () => {
            await advanceTime(50);
            await telcoin.connect(owner).approve(telcoinDistributor.getAddress(), 1000000)
            await expect(telcoinDistributor.connect(proposer).executeTransaction(0));
            await expect(telcoinDistributor.connect(owner).executeTransaction(0)).to.be.revertedWith("TelcoinDistributor: transaction has been previously executed");
        });

        it('should execute a transaction successfully', async () => {
            await advanceTime(50);
            await telcoin.connect(owner).approve(telcoinDistributor.getAddress(), 1000000)
            await expect(telcoinDistributor.connect(proposer).executeTransaction(0));
        });
    });
});