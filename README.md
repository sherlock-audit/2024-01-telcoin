
# Telcoin contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the issue page in your private contest repo (label issues as med or high)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

### Q: On what chains are the smart contracts going to be deployed?
All smart contracts will be deployed to Polygon and eventually the Telcoin Network. Some of the contracts will also be deployed to Ethereum.
___

### Q: Which ERC20 tokens do you expect will interact with the smart contracts? 
For the most part, the most common token will be Telcoin, however various liquidity pool tokens will also be involved.
___

### Q: Which ERC721 tokens do you expect will interact with the smart contracts? 
We expect our council NFTs to interact with the Sablier streams which are ERC721 tokens. The interfaces for these tokens have been provided under `contracts/sablier/interfaces`.
___

### Q: Do you plan to support ERC1155?
Currently there is no plan to support any token other than ERC20s or ERC721s.
___

### Q: Which ERC777 tokens do you expect will interact with the smart contracts? 
N/A
___

### Q: Are there any FEE-ON-TRANSFER tokens interacting with the smart contracts?

No
___

### Q: Are there any REBASING tokens interacting with the smart contracts?

No
___

### Q: Are the admins of the protocols your contracts integrate with (if any) TRUSTED or RESTRICTED?
TRUSTED
___

### Q: Is the admin/owner of the protocol/contracts TRUSTED or RESTRICTED?
TRUSTED
___

### Q: Are there any additional protocol roles? If yes, please explain in detail:
No
___

### Q: Is the code/contract expected to comply with any EIPs? Are there specific assumptions around adhering to those EIPs that Watsons should be aware of?
Interacting contracts are expected to behave like typical ERC20s or ERC721s.
___

### Q: Please list any known issues/acceptable risks that should not result in a valid finding.
N/A
___

### Q: Please provide links to previous audits (if any).
N/A
___

### Q: Are there any off-chain mechanisms or off-chain procedures for the protocol (keeper bots, input validation expectations, etc)?
We expect to use an automated system such as Defender auto tasks or Gelato (network) integrations. 
___

### Q: In case of external protocol integrations, are the risks of external contracts pausing or executing an emergency withdrawal acceptable? If not, Watsons will submit issues related to these situations that can harm your protocol's functionality.
Acceptable
___

### Q: Do you expect to use any of the following tokens with non-standard behaviour with the smart contracts?
No
___

### Q: Add links to relevant protocol resources
- Sablier https://app.sablier.com
  - Docs https://docs.sablier.com
  - GitHub https://github.com/sablier-labs
- Snapshot https://snapshot.org/#/
  - Docs https://docs.snapshot.org
  - GitHub https://github.com/snapshot-labs
- Synthetix https://snapshot.org/#/
  - Docs https://developer.synthetix.io
  - GitHub https://github.com/Synthetixio
- Gnosis https://www.gnosisguild.org
  - Zodiac Docs https://zodiac.wiki/index.php/ZODIAC.WIKI
  - Reality Docs https://zodiac.wiki/index.php/Category:Reality_Module
  - Zodiac GitHub https://github.com/gnosis/zodiac
  - Reality GitHub https://github.com/gnosis/zodiac-module-reality
___



# Audit scope


[telcoin-audit @ 83b50e15be708dffec5d96695ab187348b52f2c1](https://github.com/telcoin/telcoin-audit/tree/83b50e15be708dffec5d96695ab187348b52f2c1)
- [telcoin-audit/contracts/protocol/core/TelcoinDistributor.sol](telcoin-audit/contracts/protocol/core/TelcoinDistributor.sol)
- [telcoin-audit/contracts/sablier/core/CouncilMember.sol](telcoin-audit/contracts/sablier/core/CouncilMember.sol)
- [telcoin-audit/contracts/telx/abstract/RewardsDistributionRecipient.sol](telcoin-audit/contracts/telx/abstract/RewardsDistributionRecipient.sol)
- [telcoin-audit/contracts/telx/core/StakingRewardsFactory.sol](telcoin-audit/contracts/telx/core/StakingRewardsFactory.sol)
- [telcoin-audit/contracts/telx/core/StakingRewardsManager.sol](telcoin-audit/contracts/telx/core/StakingRewardsManager.sol)
- [telcoin-audit/contracts/zodiac/core/SafeGuard.sol](telcoin-audit/contracts/zodiac/core/SafeGuard.sol)

