// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "../interfaces/IStakingRewardsFactory.sol";
import "./StakingRewards.sol";

/**
 * @title StakingRewardsFactory
 * @author Amir M. Shirif
 * @notice A Telcoin Contract
 * @dev Implements Openzeppelin Audited Contracts
 *
 * @notice This contract creates and keeps track of instances of StakingRewards contracts.
 */
contract StakingRewardsFactory is Ownable {
    // Address of the StakingRewards implementation contract
    address public immutable stakingRewardsImplementation;

    // Stores the addresses of all StakingRewards contracts created by this factory
    StakingRewards[] public stakingRewardsContracts;

    // declares a new staking contract
    event NewStakingRewardsContract(
        uint256 indexed index,
        IERC20 indexed rewardToken,
        IERC20 indexed stakingToken,
        StakingRewards implementation
    );

    constructor(address implementation) Ownable(_msgSender()) {
        stakingRewardsImplementation = implementation;
    }

    /**
     * @notice Creates a new StakingRewards contract
     * @param rewardsDistribution The address of the rewards distribution contract.
     * @param rewardsToken The address of the rewards token contract.
     * @param stakingToken The address of the staking token contract.
     * @return The address of the newly created StakingRewards contract
     */
    function createStakingRewards(
        address rewardsDistribution,
        IERC20 rewardsToken,
        IERC20 stakingToken
    ) external onlyOwner returns (StakingRewards) {
        // create contract
        StakingRewards stakingRewards = new StakingRewards(
            rewardsDistribution,
            rewardsToken,
            stakingToken
        );

        // add contract to list
        stakingRewardsContracts.push(stakingRewards);
        //emit values associated
        emit NewStakingRewardsContract(
            getStakingRewardsContractCount() - 1,
            rewardsToken,
            stakingToken,
            StakingRewards(stakingRewards)
        );

        return StakingRewards(stakingRewards);
    }

    /**
     * @notice Get the address of the StakingRewards contract at a given index
     * @param index The index of the StakingRewards contract
     * @return The address of the StakingRewards contract
     */
    function getStakingRewardsContract(
        uint index
    ) external view returns (StakingRewards) {
        return stakingRewardsContracts[index];
    }

    /**
     * @notice Get the total number of StakingRewards contracts created by this factory
     * @return The total number of StakingRewards contracts
     */
    function getStakingRewardsContractCount() public view returns (uint) {
        return stakingRewardsContracts.length;
    }
}
