// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Rewards Distribution Recipient
 * @notice This abstract contract allows for distribution of rewards in the contract.
 * It defines functionality for setting the address of the rewards distribution contract
 * and a function to notify the reward amount which must be implemented by inheriting contracts.
 * It also has a modifier to restrict functions to being called only from the rewards distribution contract.
 * @dev Inherits from the Ownable contract from OpenZeppelin to provide basic access control.
 */
abstract contract RewardsDistributionRecipient is Ownable {
    // The address of the contract that will distribute the rewards.
    address public rewardsDistribution;

    /**
     * @notice Notify about the reward amount
     * @dev Function that contracts inheriting from RewardsDistributionRecipient need to implement.
     * @param reward The amount of the reward to distribute
     */
    function notifyRewardAmount(uint256 reward) external virtual;

    /**
     * @notice Modifier to allow only the rewards distribution contract to call certain functions
     * @dev If the function is called by any address other than the rewards distribution contract, the transaction is reverted.
     */
    modifier onlyRewardsDistribution() {
        require(
            _msgSender() == rewardsDistribution,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    /**
     * @notice Set the rewards distribution contract
     * @dev Can only be called by the owner of the contract. Updates the rewardsDistribution address.
     * @param rewardsDistribution_ The address of the new rewards distribution contract
     */
    function setRewardsDistribution(
        address rewardsDistribution_
    ) external onlyOwner {
        rewardsDistribution = rewardsDistribution_;
        emit RewardsDistributionUpdated(rewardsDistribution);
    }

    // event denotine new address in charge of updating contract
    event RewardsDistributionUpdated(address newDistribution);
}
