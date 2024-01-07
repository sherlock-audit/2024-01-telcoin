// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./StakingRewardsFactory.sol";
import "./StakingRewards.sol";

/**
 * @title StakingRewardsManager
 * @notice A Telcoin Contract
 * @dev Implements Openzeppelin Audited Contracts
 *
 * @notice This contract can manage multiple Synthetix StakingRewards contracts.
 * Staking contracts managed my multisigs can avoid having to coordinate to top up contracts every staking period.
 * Instead, add staking contracts to this manager contract, approve this contract to spend the rewardToken and then topUp() can be called permissionlessly.
 */
contract StakingRewardsManager is AccessControlUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice This role grants the ability to rescue ERC20 tokens that do not rightfully belong to this contract
    bytes32 public constant BUILDER_ROLE = keccak256("BUILDER_ROLE");
    bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    /// @dev StakingRewards config
    struct StakingConfig {
        uint256 rewardsDuration;
        uint256 rewardAmount;
    }

    /// @dev Reward token for all StakingRewards contracts managed by this contract
    IERC20 public rewardToken;
    /// @dev Optional factory contract for creating new StakingRewards contracts
    StakingRewardsFactory public stakingRewardsFactory;
    /// @dev Array of managed StakingRewards contracts
    StakingRewards[] public stakingContracts;

    /// @dev Maps a StakingReward contract to boolean indicating its existence in the stakingContracts array
    mapping(StakingRewards => bool) public stakingExists;
    /// @dev Maps a StakingReward contract to its configuration (rewardsDuration and rewardAmount)
    mapping(StakingRewards => StakingConfig) public stakingConfigs;

    /// @dev Emitted when an existing StakingRewards contract is added to the stakingContracts array
    event StakingAdded(StakingRewards indexed staking, StakingConfig config);
    /// @dev Emitted when a StakingRewards contract is removed from the stakingContracts array
    event StakingRemoved(StakingRewards indexed staking);
    /// @dev Emitted when configuration for a StakingRewards contract is changed
    event StakingConfigChanged(
        StakingRewards indexed staking,
        StakingConfig config
    );
    /// @dev Emitted when the StakingRewards Factory contract is changed
    event StakingRewardsFactoryChanged(
        StakingRewardsFactory indexed stakingFactory
    );
    /// @dev Emitted when updatePeriodFinish is called on a StakingRewards contract
    event PeriodFinishUpdated(
        StakingRewards indexed staking,
        uint256 newPeriodFinish
    );
    /// @dev Emitted when a StakingRewards contract is topped up
    event ToppedUp(StakingRewards indexed staking, StakingConfig config);

    /// @notice initialize the contract
    /// @param reward The reward token of all the managed staking contracts
    function initialize(
        IERC20 reward,
        StakingRewardsFactory factory
    ) external initializer {
        //check for zero values
        require(
            address(factory) != address(0) && address(reward) != address(0),
            "StakingRewardsManager: cannot intialize to zero"
        );

        // set up default
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // set values
        rewardToken = reward;
        stakingRewardsFactory = factory;
        emit StakingRewardsFactoryChanged(factory);
    }

    /// @return length uint256 of stakingContracts array
    function stakingContractsLength() external view returns (uint256) {
        return stakingContracts.length;
    }

    /// @return length uint256 of stakingContracts array
    function getStakingContract(
        uint256 i
    ) external view returns (StakingRewards) {
        return stakingContracts[i];
    }

    /// @notice Create a new StakingRewards contract via the factory and add it to the stakingContracts array of managed contracts
    /// @param stakingToken Staking token for the new StakingRewards contract
    /// @param config Staking configuration
    function createNewStakingRewardsContract(
        IERC20 stakingToken,
        StakingConfig calldata config
    ) external onlyRole(BUILDER_ROLE) {
        // create the new staking contract
        // new staking will have owner and rewardsDistribution set to address(this)
        StakingRewards staking = StakingRewards(
            address(
                stakingRewardsFactory.createStakingRewards(
                    address(this),
                    IERC20(address(rewardToken)),
                    IERC20(stakingToken)
                )
            )
        );
        //internal call to add new contract
        _addStakingRewardsContract(staking, config);
    }

    /// @notice Add a StakingRewards contract
    /// @dev This contract must be nominated for ownership before the staking contract can be added
    /// If this contract cannot acceptOwnership of the staking contract this function will revert
    /// This function WILL NOT REVERT if `staking` does not have the right rewardToken.
    /// Do not add staking contracts with rewardToken other than the one passed to initialize this contract.
    /// @param staking Address of the StakingRewards contract to add
    /// @param config Configuration of the staking contracts
    function addStakingRewardsContract(
        StakingRewards staking,
        StakingConfig calldata config
    ) external onlyRole(BUILDER_ROLE) {
        //checking if already exists
        require(
            !stakingExists[staking],
            "StakingRewardsManager: Staking contract already exists"
        );
        //internal call to add new contract
        _addStakingRewardsContract(staking, config);
    }

    /// @notice Add a StakingRewards contract
    /// @param staking Address of the StakingRewards contract to add
    /// @param config Configuration of the staking contracts
    function _addStakingRewardsContract(
        StakingRewards staking,
        StakingConfig calldata config
    ) internal {
        // in order to manage this contract we have to own it
        // staking.acceptOwnership();
        // in order to top up rewards, we have to be rewardsDistribution. this is an onlyOwner function
        staking.setRewardsDistribution(address(this));

        // push staking onto stakingContracts array
        stakingContracts.push(staking);
        // set staking config
        stakingConfigs[staking] = config;
        // mark inclusion in the stakingContracts array
        stakingExists[staking] = true;

        emit StakingAdded(staking, config);
    }

    /// @notice Remove a StakingRewards contract from the stakingContracts array. This will remove this contract's ability to manage it
    /// @dev This function WILL NOT transfer ownership of the staking contract. To do this, call `nominateOwnerForStaking`
    /// @param i Index of staking contract to remove
    function removeStakingRewardsContract(
        uint256 i
    ) external onlyRole(BUILDER_ROLE) {
        StakingRewards staking = stakingContracts[i];

        // un-mark this staking contract as included in stakingContracts
        stakingExists[staking] = false;
        // replace the removed staking contract with the last item in the stakingContracts array
        stakingContracts[i] = stakingContracts[stakingContracts.length - 1];
        // pop the last staking contract off the array
        stakingContracts.pop();

        emit StakingRemoved(staking);
    }

    /// @notice Set the configuration for a StakingRewards contract
    /// @dev `staking` does not need to be included in `stakingContracts` for this function to succeed
    /// @param staking Address of StakingRewards contract
    /// @param config Staking config
    function setStakingConfig(
        StakingRewards staking,
        StakingConfig calldata config
    ) external onlyRole(MAINTAINER_ROLE) {
        // replacing old value
        stakingConfigs[staking] = config;
        emit StakingConfigChanged(staking, config);
    }

    /// @notice Set the StakingRewards Factory contract
    /// @dev Factory AND StakingRewards contracts must maintain their ABI
    /// @param factory Address of StakingRewards Factory contract
    function setStakingRewardsFactory(
        StakingRewardsFactory factory
    ) external onlyRole(MAINTAINER_ROLE) {
        //check for zero values
        require(
            address(factory) != address(0),
            "StakingRewardsManager: Factory cannot be set to zero"
        );
        //set new value
        stakingRewardsFactory = factory;
        emit StakingRewardsFactoryChanged(factory);
    }

    /// @notice Recover ERC20 tokens from a StakingRewards contract
    /// @dev This contract must own the staking contract
    /// @param staking The staking contract to recover tokens from
    /// @param tokenAddress Address of the ERC20 token contract
    /// @param tokenAmount Amount of tokens to recover
    /// @param to The account to send the recovered tokens to
    function recoverERC20FromStaking(
        StakingRewards staking,
        IERC20 tokenAddress,
        uint256 tokenAmount,
        address to
    ) external onlyRole(SUPPORT_ROLE) {
        // grab the tokens from the staking contract
        staking.recoverERC20(to, tokenAddress, tokenAmount);
    }

    /// @notice Recover ERC20 tokens from THIS contract
    /// @param tokenAddress Address of the ERC20 token contract
    /// @param tokenAmount Amount of tokens to recover
    /// @param to The account to send the recovered tokens to
    function recoverERC20(
        IERC20 tokenAddress,
        uint256 tokenAmount,
        address to
    ) external onlyRole(SUPPORT_ROLE) {
        //move funds
        tokenAddress.safeTransfer(to, tokenAmount);
    }

    /// @notice change ownership for a staking contract
    /// @dev This contract must currently own the staking contract
    /// @param staking The staking contract to transfer ownership of
    /// @param newOwner Account of new owner
    function transferStakingOwnership(
        StakingRewards staking,
        address newOwner
    ) external onlyRole(ADMIN_ROLE) {
        //internal emit is called
        staking.transferOwnership(newOwner);
    }

    /// @notice Top up multiple staking contracts
    /// @param source address from which tokens are taken
    /// @param indices array of staking contract indices
    function topUp(
        address source,
        uint256[] memory indices
    ) external onlyRole(EXECUTOR_ROLE) {
        for (uint i = 0; i < indices.length; i++) {
            // get staking contract and config
            StakingRewards staking = stakingContracts[i];
            StakingConfig memory config = stakingConfigs[staking];

            // will revert if block.timestamp <= periodFinish
            staking.setRewardsDuration(config.rewardsDuration);

            // pull tokens from owner of this contract to fund the staking contract
            rewardToken.transferFrom(
                source,
                address(staking),
                config.rewardAmount
            );

            // start periods
            staking.notifyRewardAmount(config.rewardAmount);

            emit ToppedUp(staking, config);
        }
    }
}
