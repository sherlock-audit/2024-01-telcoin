import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { CouncilMember, TestTelcoin, TestStream } from "../../typechain-types";

describe("CouncilMember", () => {
    let admin: SignerWithAddress;
    let support: SignerWithAddress;
    let member: SignerWithAddress;
    let holder: SignerWithAddress;
    let councilMember: CouncilMember;
    let telcoin: TestTelcoin;
    let stream: TestStream;

    let target: SignerWithAddress;
    let id: number = 0;
    let governanceRole: string = ethers.keccak256(ethers.toUtf8Bytes("GOVERNANCE_COUNCIL_ROLE"));
    let supportRole: string = ethers.keccak256(ethers.toUtf8Bytes("SUPPORT_ROLE"));

    beforeEach(async () => {
        [admin, support, member, holder, target] = await ethers.getSigners();

        const TestTelcoinFactory = await ethers.getContractFactory("TestTelcoin", admin);
        telcoin = await TestTelcoinFactory.deploy(admin.address);

        const TestStreamFactory = await ethers.getContractFactory("TestStream", admin);
        stream = await TestStreamFactory.deploy(await telcoin.getAddress());

        const CouncilMemberFactory = await ethers.getContractFactory("CouncilMember", admin);
        councilMember = await CouncilMemberFactory.deploy();

        await councilMember.initialize(await telcoin.getAddress(), "Test Council", "TC", await stream.getAddress(), target.address, id);
        // await councilMember.revokeRole(ethers.keccak256(ethers.toUtf8Bytes("DEFUALT_ADMIN")), admin.address);
        await councilMember.grantRole(governanceRole, admin.address);
        await councilMember.grantRole(supportRole, support.address);
    });

    describe("Values", () => {
        describe("Getters", () => {
            it("GOVERNANCE_COUNCIL_ROLE", async () => {
                expect(await councilMember.GOVERNANCE_COUNCIL_ROLE()).to.equal(governanceRole);
            });

            it("SUPPORT_ROLE", async () => {
                expect(await councilMember.SUPPORT_ROLE()).to.equal(supportRole);
            });

            it("TELCOIN address", async () => {
                expect(await councilMember.TELCOIN()).to.equal(await telcoin.getAddress());
            });

            it("stream address", async () => {
                expect(await councilMember._stream()).to.equal(await stream.getAddress());
            });

            it("target address", async () => {
                expect(await councilMember._target()).to.equal(target.address);
            });

            it("id", async () => {
                expect(await councilMember._id()).to.equal(id);
            });

            it("has governance role", async () => {
                expect(await councilMember.hasRole(governanceRole, admin.address)).to.equal(true);
            });

            it("has support role", async () => {
                expect(await councilMember.hasRole(supportRole, support.address)).to.equal(true);
            });

            it("has AccessControlEnumerableUpgradeable interface", async () => {
                expect(await councilMember.supportsInterface('0x5bfad1a8')).to.equal(true);
            });

            it("has ERC721EnumerableUpgradeable interface", async () => {
                expect(await councilMember.supportsInterface('0x79f154c4')).to.equal(true);
            });
        });

        describe("Setters", () => {
            describe("updateStream", () => {
                describe("Failure", () => {
                    it("updateStream should fail when caller does not have role", async () => {
                        await expect(councilMember.connect(support).updateStream(support.address)).to.be.reverted;
                    });
                });

                describe("Success", () => {
                    it("updateStream", async () => {
                        await expect(councilMember.updateStream(support.address)).emit(councilMember, 'StreamUpdated').withArgs(support.address);
                        expect(await councilMember._stream()).to.equal(support.address);
                    });
                });
            })

            describe("updateTarget", () => {
                describe("Failure", () => {
                    it("updateTarget should fail when caller does not have role", async () => {
                        await expect(councilMember.connect(support).updateTarget(support.address)).to.be.reverted;
                    });
                });

                describe("Success", () => {
                    it("updateTarget", async () => {
                        await expect(councilMember.updateTarget(support.address)).emit(councilMember, 'TargetUpdated').withArgs(support.address);
                        expect(await councilMember._target()).to.equal(support.address);
                    });
                });
            })

            describe("updateID", () => {
                describe("Failure", () => {
                    it("updateID should fail when caller does not have role", async () => {
                        await expect(councilMember.connect(support).updateID(1)).to.be.reverted;
                    });
                });

                describe("Success", () => {
                    it("updateID", async () => {
                        await expect(councilMember.updateID(1)).emit(councilMember, 'IDUpdated').withArgs(1);
                        expect(await councilMember._id()).to.equal(1);
                    });
                });
            })
        });
    });

    describe("mutative", () => {
        beforeEach(async () => {
            telcoin.transfer(await stream.getAddress(), 100000);
        });

        describe("mint", () => {
            it("mint a single NFT", async () => {
                await expect(councilMember.mint(member.address)).emit(councilMember, 'Transfer');
                expect(await councilMember.totalSupply()).to.equal(1);
                expect(await councilMember.balanceOf(member.address)).to.equal(1);
                expect(await councilMember.ownerOf(0)).to.equal(member.address);
            });
        });

        describe("approve", () => {
            beforeEach(async () => {
                await expect(councilMember.mint(member.address));
                expect(await councilMember.balanceOf(support.address)).to.equal(0);
            });

            describe("Failure", () => {
                it("approval is created for and only for designated address", async () => {
                    await expect(councilMember.connect(holder).transferFrom(member.address, support.address, 0)).to.be.reverted;
                    expect(await councilMember.balanceOf(support.address)).to.equal(0);
                });
            });

            describe("Success", () => {
                it("approval is created for and only for designated address", async () => {
                    await expect(councilMember.connect(admin).approve(support.address, 0)).emit(councilMember, 'Approval');
                    await expect(councilMember.connect(support).transferFrom(member.address, support.address, 0)).to.be.not.reverted;
                    expect(await councilMember.balanceOf(support.address)).to.equal(1);
                });
            });
        });

        describe("burn", () => {
            beforeEach(async () => {
                telcoin.transfer(await stream.getAddress(), 100000);
                await expect(councilMember.mint(member.address)).to.not.reverted;
                await expect(councilMember.mint(support.address)).to.not.reverted;
                await expect(councilMember.mint(await stream.getAddress())).to.not.reverted;
            });

            describe("Failure", () => {
                it("the correct removal is made", async () => {
                    await expect(councilMember.burn(0, member.address)).to.not.reverted;
                    await expect(councilMember.burn(1, support.address)).to.not.reverted;
                    await expect(councilMember.burn(2, support.address)).to.revertedWith("CouncilMember: must maintain council");
                });
            });

            describe("Success", () => {
                it("the correct removal is made", async () => {
                    await expect(councilMember.burn(1, support.address)).emit(councilMember, "Transfer");
                });
            });
        });

        describe("removeFromOffice", () => {
            beforeEach(async () => {
                await expect(councilMember.mint(member.address));
                await expect(councilMember.mint(support.address));
            });

            describe("Success", () => {
                it("the correct removal is made", async () => {
                    await expect(councilMember.removeFromOffice(member.address, support.address, 0, member.address)).to.not.reverted;
                    expect(await councilMember.balanceOf(member.address)).to.equal(0);
                    expect(await councilMember.balanceOf(support.address)).to.equal(2);
                });
            });
        });
    });

    describe("tokenomics", () => {
        beforeEach(async () => {
            telcoin.transfer(await stream.getAddress(), 100000);
        });

        describe("mint", () => {
            it("correct balance accumulation", async () => {
                await expect(councilMember.mint(member.address)).to.not.reverted;
                expect(await telcoin.balanceOf(member.address)).to.equal(0);
                // // mint(0) => 0 TEL
                expect(await councilMember.balances(0)).to.equal(0);

                await expect(councilMember.mint(support.address)).to.not.reverted;
                expect(await telcoin.balanceOf(member.address)).to.equal(0);
                expect(await telcoin.balanceOf(support.address)).to.equal(0);
                // mint(1) => 100 TEL
                expect(await councilMember.balances(0)).to.equal(100);
                // mint(1) => 0 TEL
                expect(await councilMember.balances(1)).to.equal(0);

                await expect(councilMember.mint(await councilMember.getAddress())).to.not.reverted;
                expect(await telcoin.balanceOf(member.address)).to.equal(0);
                expect(await telcoin.balanceOf(support.address)).to.equal(0);
                expect(await telcoin.balanceOf(await councilMember.getAddress())).to.equal(200);
                // mint(1) => 50 TEL + mint(2) => 100 TEL
                expect(await councilMember.balances(0)).to.equal(150);
                // mint(2) => 50 TEL
                expect(await councilMember.balances(1)).to.equal(50);
                // // mint(2) => 0 TEL
                expect(await councilMember.balances(2)).to.equal(0);
            });
        });

        describe("burn", () => {
            it("the correct removal is made", async () => {
                await expect(councilMember.mint(member.address)).to.not.reverted;
                await expect(councilMember.mint(support.address)).to.not.reverted;
                await expect(councilMember.mint(await councilMember.getAddress())).to.not.reverted;

                expect(await telcoin.balanceOf(await councilMember.getAddress())).to.equal(200);
                await expect(councilMember.burn(2, holder.address)).to.not.reverted;
                expect(await telcoin.balanceOf(await councilMember.getAddress())).to.equal(267);

                //100 TEL / totalSupply() = 33 + runningBalance 1 TEL

                // mint(0) => 0 TEL + mint(1) => 100 TEL + mint(2) => 50 TEL + burn(2) => 33 TEL
                expect(await councilMember.balances(0)).to.equal(183);
                // mint(1) => 0 TEL + mint(2) => 50 TEL + burn(2) => 33 TEL
                expect(await councilMember.balances(1)).to.equal(83);
                // mint(2) => 0 TEL + burn(2) => 33 TEL
                expect(await telcoin.balanceOf(holder.address)).to.equal(33);
            });
        });

        describe("removeFromOffice", () => {
            it("funds remain with old office holder", async () => {
                await expect(councilMember.mint(member.address));
                await expect(councilMember.mint(support.address));

                await expect(councilMember.removeFromOffice(member.address, support.address, 0, member.address)).to.not.reverted;
                // mint(0) => 100 TEL + mint(1) => 50 TEL
                expect(await telcoin.balanceOf(member.address)).to.equal(150);
                // mint(0) => 0 TEL + mint(1) => 0 TEL
                expect(await telcoin.balanceOf(support.address)).to.equal(0);
                // mint(1) => 50 TEL
                expect(await telcoin.balanceOf(await councilMember.getAddress())).to.equal(50);
            });

            it("funds sent to different holder", async () => {
                await expect(councilMember.mint(member.address));
                await expect(councilMember.mint(support.address));

                await expect(councilMember.removeFromOffice(member.address, support.address, 0, support.address)).to.not.reverted;
                // mint(0) => 0 TEL + mint(1) => 0 TEL
                expect(await telcoin.balanceOf(member.address)).to.equal(0);
                // mint(0) => 100 TEL + mint(1) => 50 TEL
                expect(await telcoin.balanceOf(support.address)).to.equal(150);
                // mint(1) => 50 TEL
                expect(await telcoin.balanceOf(await councilMember.getAddress())).to.equal(50);
            });
        });

        describe("claim", () => {
            it("claiming rewards", async () => {
                await expect(councilMember.mint(member.address));
                await expect(councilMember.connect(member).claim(0, 100)).to.not.reverted;
                expect(await councilMember.balances(0)).to.equal(0);

                await expect(councilMember.mint(support.address)).to.not.reverted;
                await expect(councilMember.connect(member).claim(0, 200)).to.be.revertedWith("CouncilMember: withdrawal amount is higher than balance");
                await expect(councilMember.connect(member).claim(0, 100)).to.not.reverted;
                expect(await councilMember.balances(0)).to.equal(50);
                expect(await councilMember.balances(1)).to.equal(50);

                await expect(councilMember.mint(member.address)).to.not.reverted;
                expect(await councilMember.balances(0)).to.equal(100);
                expect(await councilMember.balances(1)).to.equal(100);
                expect(await councilMember.balances(2)).to.equal(0);
                await expect(councilMember.connect(member).claim(0, 100)).to.not.reverted;
                expect(await councilMember.balances(0)).to.equal(33);
                expect(await councilMember.balances(1)).to.equal(133);
                expect(await councilMember.balances(2)).to.equal(33);

                expect(await telcoin.balanceOf(member.address)).to.equal(300);
                expect(await telcoin.balanceOf(support.address)).to.equal(0);
                expect(await telcoin.balanceOf(await councilMember.getAddress())).to.equal(200);
            });
        });

        describe("retrieve", () => {
            it("minting does not affect claims, but does increase balance", async () => {
                await expect(councilMember.mint(member.address));
                expect(await telcoin.balanceOf(member.address)).to.equal(0);
                // mint(0) => 0 TEL
                expect(await councilMember.balances(0)).to.equal(0);

                await expect(councilMember.retrieve()).to.not.reverted;
                // mint(0) => 0 TEL + retrieve() => 100 TEL
                expect(await councilMember.balances(0)).to.equal(100);

                await expect(councilMember.mint(support.address)).to.not.reverted;
                // mint(0) => 0 TEL + retrieve() => 100 TEL + mint(1) => 100 TEL
                expect(await councilMember.balances(0)).to.equal(200);

                await expect(councilMember.retrieve()).to.not.reverted;
                // mint(0) => 0 TEL + retrieve() => 100 TEL + mint(1) => 100 TEL+ retrieve() => 50 TEL
                expect(await councilMember.balances(0)).to.equal(250);
                // retrieve() => 50 TEL
                expect(await councilMember.balances(1)).to.equal(50);
            });
        });

        describe("erc20Rescue", () => {
            it("rescue tokens", async () => {
                await telcoin.transfer(await councilMember.getAddress(), 100000);
                await expect(councilMember.connect(support).erc20Rescue(await telcoin.getAddress(), support.address, await telcoin.balanceOf(await councilMember.getAddress()))).to.not.reverted;
                expect(await telcoin.balanceOf(support.address)).to.equal(100000);
            });
        });
    });
});
//supportsInterface 