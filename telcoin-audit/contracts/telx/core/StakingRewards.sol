// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../abstract/RewardsDistributionRecipient.sol";

/**
 * @title Staking Rewards
 * @notice This contract handles staking and rewards for a particular token.
 * It inherits functionality from RewardsDistributionRecipient, ReentrancyGuard, and Pausable contracts.
 */
contract StakingRewards is
    RewardsDistributionRecipient,
    ReentrancyGuard,
    Pausable
{
    using Address for address;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    // Token that will be rewarded to the stakers
    IERC20 public rewardsToken;

    // Token that will be staked in the contract
    IERC20 public stakingToken;

    // Variables for reward calculations
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 7 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    // Mappings to track staker information
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    // Total supply of the staked tokens
    uint256 private _totalSupply;

    // Balances of the staked tokens
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Constructor to set initial state variables.
     * @param rewardsDistribution_ The address of the rewards distribution contract.
     * @param rewardsToken_ The address of the rewards token contract.
     * @param stakingToken_ The address of the staking token contract.
     */
    constructor(
        address rewardsDistribution_,
        IERC20 rewardsToken_,
        IERC20 stakingToken_
    ) Ownable(_msgSender()) {
        rewardsToken = rewardsToken_;
        stakingToken = stakingToken_;
        rewardsDistribution = rewardsDistribution_;
        _transferOwnership(rewardsDistribution_);
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Returns total supply of the staking tokens.
     * @return Total supply of the staking tokens.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Returns balance of the staking tokens for a given account.
     * @param account The address of the account.
     * @return Balance of the staking tokens for the account.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Returns the last timestamp where rewards were applicable.
     * @return Last timestamp where rewards were applicable.
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /**
     * @notice Calculates the amount of reward per staked token.
     * @return The amount of reward per staked token.
     */
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            ((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRate *
                1e18) /
            _totalSupply;
    }

    /**
     * @notice Calculates the earned rewards of an account.
     * @param account The address of the account.
     * @return The earned rewards of the account.
     */
    function earned(address account) public view returns (uint256) {
        // Calculate the earned reward by first multiplying the balance of the account with the difference between the current reward per token and the already paid reward per token for the account
        // Then divide by 1e18 to adjust for decimals and finally add the rewards already allocated to the account
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    /**
     * @notice Calculates the rewards for the reward duration.
     * @return The rewards for the reward duration.
     */
    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    /* ========== MUTATIVE ========== */

    /**
     * @notice Stake a certain amount of tokens.
     * @dev This function is protected by the nonReentrant modifier to prevent double spending.
     * @param amount The amount of tokens to stake.
     */
    function stake(
        uint256 amount
    ) external nonReentrant whenNotPaused updateReward(_msgSender()) {
        // Check if the staking amount is greater than 0
        require(amount > 0, "Cannot stake 0");
        // Increase the total supply of the staking token by the staked amount
        _totalSupply += amount;
        // Increase the balance of the staker by the staked amount
        _balances[_msgSender()] += amount;
        // Transfer the staked tokens from the staker to this contract
        stakingToken.safeTransferFrom(_msgSender(), address(this), amount);
        // Emit a Staked event with staker's address and staked amount
        emit Staked(_msgSender(), amount);
    }

    /**
     * @notice Withdraw a certain amount of tokens.
     * @dev This function is protected by the nonReentrant modifier to prevent double spending.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(
        uint256 amount
    ) public nonReentrant updateReward(_msgSender()) {
        // Check if the withdrawal amount is greater than 0
        require(amount > 0, "Cannot withdraw 0");
        // Decrease the total supply of the staking token by the withdrawn amount
        _totalSupply -= amount;
        // Decrease the balance of the withdrawer by the withdrawn amount
        _balances[_msgSender()] -= amount;
        // Transfer the withdrawn tokens from this contract to the withdrawer
        stakingToken.safeTransfer(_msgSender(), amount);
        // Emit a Withdrawn event with withdrawer's address and withdrawn amount
        emit Withdrawn(_msgSender(), amount);
    }

    /**
     * @notice Get the earned rewards of the caller.
     * @dev This function is protected by the nonReentrant modifier to prevent double spending.
     */
    function getReward() public nonReentrant updateReward(_msgSender()) {
        // Get the amount of reward for the caller
        uint256 reward = rewards[_msgSender()];
        // Check if the reward is greater than 0
        if (reward > 0) {
            // Reset the reward of the caller to 0
            rewards[_msgSender()] = 0;
            // Transfer the reward tokens from this contract to the caller
            rewardsToken.safeTransfer(_msgSender(), reward);
            // Emit a RewardPaid event with the caller's address and claimed reward amount
            emit RewardPaid(_msgSender(), reward);
        }
    }

    /**
     * @notice Withdraw all tokens and get the earned rewards for the caller.
     */
    function exit() external {
        withdraw(_balances[_msgSender()]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Notify the contract about the reward amount for the next period
     * @dev can only be called by the reward distribution address
     * @param reward The amount of reward for the next period
     */
    function notifyRewardAmount(
        uint256 reward
    ) external override onlyRewardsDistribution updateReward(address(0)) {
        // If the current block timestamp is after the finish of the rewards period, set the new reward rate
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            // If we're still within the rewards period, add the leftover rewards to the new reward
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }
        // Check the balance of the rewards token in this contract
        uint balance = rewardsToken.balanceOf(address(this));
        // Make sure that the new reward rate isn't higher than what the contract can currently pay out
        require(
            rewardRate <= balance / rewardsDuration,
            "Provided reward too high"
        );
        // Update the last update time and the end of the rewards period
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward); // Emit the RewardAdded event
    }

    /**
     * @notice Recover ERC20 tokens which are sent by mistake to this contract
     * @dev This can only be done by the contract owner
     * @param destination The address to which the tokens will be sent
     * @param tokenAddress The address of the token to recover
     * @param tokenAmount The amount of tokens to recover
     */
    function recoverERC20(
        address destination,
        IERC20 tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner {
        // Check if the token to recover is not the staking token, as you don't want to allow withdrawal of the staked tokens
        require(
            tokenAddress != stakingToken,
            "Cannot withdraw the staking token"
        );
        // Transfer the specified token amount from this contract to the specified destination address
        tokenAddress.safeTransfer(destination, tokenAmount);
        // Emit a Recovered event with the token's address and recovered amount
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Update the duration of the rewards
     * @dev This can only be done by the contract owner
     * @param rewardsDuration_ The new duration of the rewards
     */
    function setRewardsDuration(uint256 rewardsDuration_) external onlyOwner {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = rewardsDuration_;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    /**
     * @notice Update the reward of the account
     * @dev It's used in several external functions to calculate and update the rewards
     * @param account The address of the account
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken(); // Update the stored reward per token
        lastUpdateTime = lastTimeRewardApplicable(); // Update the last update time
        if (account != address(0)) {
            // If the account address is not the zero address, update the rewards and the paid reward per token of the account
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(IERC20 token, uint256 amount);
}
