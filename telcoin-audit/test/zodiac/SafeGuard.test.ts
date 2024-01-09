import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { MockSafeGuard, TestReality } from "../../typechain-types";

describe("SafeGuard", () => {
    let deployer: SignerWithAddress
    let holder: SignerWithAddress
    let recipient: SignerWithAddress
    let safeGuard: MockSafeGuard
    let zodiacReality: TestReality

    beforeEach("setup", async () => {
        [deployer, holder, recipient] = await ethers.getSigners();

        const MockSafeGuardFactory = await ethers.getContractFactory("MockSafeGuard", deployer);
        safeGuard = await MockSafeGuardFactory.deploy();

        const ZodiacRealityFactory = await ethers.getContractFactory("TestReality", deployer);
        zodiacReality = await ZodiacRealityFactory.deploy();
    });

    describe("Vetoing Transactions", () => {
        describe("Veto", () => {
            it("should veto a transaction", async () => {
                let nonce = '1';
                let transactionHash = await zodiacReality.getTransactionHash(recipient.address, ethers.parseEther("1"), "0x", 0, nonce);
                expect(await safeGuard.transactionHashes(transactionHash)).to.equal(false);
                await safeGuard.connect(deployer).vetoTransaction(transactionHash, nonce);
                expect(await safeGuard.transactionHashes(transactionHash)).to.equal(true);
            });

            it("should not fail to execute non-vetoed transaction", async () => {
                await expect(safeGuard.checkTransaction(recipient.address, ethers.parseEther("1"), "0x", 0, 0, 0, 0, recipient.address, recipient.address, "0x", recipient.address)).to.not.be.reverted;
            });
        });

        describe("Veto fails", () => {
            it("should fail to execute vetoed transaction previously vetoed", async () => {
                let nonce = '1';
                let transactionHash = await zodiacReality.getTransactionHash(recipient.address, ethers.parseEther("1"), "0x", 0, nonce);
                await safeGuard.connect(deployer).vetoTransaction(transactionHash, nonce);
                await expect(safeGuard.connect(deployer).vetoTransaction(transactionHash, nonce)).to.be.reverted;
            });

            it("should fail to execute vetoed transaction", async () => {
                let nonce = '1';
                let transactionHash = await zodiacReality.getTransactionHash(recipient.address, ethers.parseEther("1"), "0x", 0, nonce);
                await safeGuard.connect(deployer).vetoTransaction(transactionHash, nonce);
                await expect(safeGuard.connect(deployer).checkTransaction(recipient.address, ethers.parseEther("1"), "0x", 0, 0, 0, 0, recipient.address, recipient.address, "0x", recipient.address)).to.be.reverted;
            });
        });
    });
});