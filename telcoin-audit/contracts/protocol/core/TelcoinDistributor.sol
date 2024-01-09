// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// imports
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title TelcoinDistributor
 * @author Amir M. Shirif
 * @notice A Telcoin Laboratories Contract
 * @notice This is a Safe Wallet module that allows a proposer to propose a transaction that can be vetoed by any challenger within a challenge period.
 */
contract TelcoinDistributor is Ownable2Step, Pausable {
    // library
    using SafeERC20 for IERC20;
    // Telcoin address
    IERC20 public immutable TELCOIN;
    // An ERC721 contract that is used to determine if an account is a proposer or challenger
    IERC721 public immutable councilNft;
    // amount of time a proposal can be challenged
    uint256 public challengePeriod;
    // Array to store proposed transactions
    ProposedTransaction[] public proposedTransactions;

    // Structure to hold transaction details
    struct ProposedTransaction {
        uint256 totalWithdrawl; // Total amount of Telcoin to be taken from safe
        address[] destinations; // Locations of Telcoin dispursals
        uint256[] amounts; // Amounts of Telcoin to be sent
        uint64 timestamp; // Timestamp when the transaction was proposed
        bool challenged; // Indicates if the transaction has been challenged
        bool executed; // Indicates if the transaction has been executed
    }

    // Events for proposing and challenging transactions
    event TransactionProposed(uint256 indexed transactionId, address proposer);
    event TransactionChallenged(
        uint256 indexed transactionId,
        address challenger
    );

    // Event for updating feilds
    event ChallengePeriodUpdated(uint256 newPeriod);

    /**
     * @notice Constructs a new instance of the TelcoinDistributor contract
     * @dev Assigns the challenge period, and council NFT provided as parameters
     * @param telcoin telcoin address
     * @param period the period during which a proposed transaction can be challenged
     * @param council the NFT that will be used to determine if an account is a proposer or challenger
     */
    constructor(
        IERC20 telcoin,
        uint256 period,
        IERC721 council
    ) Ownable(_msgSender()) {
        // verifies no zero values were used
        require(
            address(telcoin) != address(0) &&
                address(council) != address(0) &&
                period != 0,
            "TelcoinDistributor: cannot intialize to zero"
        );
        // initialize telcoin address
        TELCOIN = telcoin;
        // Initialize challengePeriod duration
        challengePeriod = period;
        // Initialize councilNft address
        councilNft = council;

        // Emitting an event after proposing a transaction
        emit ChallengePeriodUpdated(challengePeriod);
    }

    /**
     * @notice Proposes a new transaction to be added to the queue
     * @dev The function checks if the sender is a proposer before allowing the transaction proposal
     * @dev A transaction proposed can be challenged during the challenge period
     * @dev A pausable function
     * @param totalWithdrawl total amount of Telcoin to be taken from safe
     * @param destinations locations of Telcoin dispursals
     * @param amounts amounts of Telcoin to be sent
     */
    function proposeTransaction(
        uint256 totalWithdrawl,
        address[] memory destinations,
        uint256[] memory amounts
    ) external onlyCouncilMember whenNotPaused {
        // Pushing the proposed transaction to the array
        proposedTransactions.push(
            ProposedTransaction({
                totalWithdrawl: totalWithdrawl,
                destinations: destinations,
                amounts: amounts,
                timestamp: uint64(block.timestamp),
                challenged: false,
                executed: false
            })
        );

        // Emitting an event after proposing a transaction
        emit TransactionProposed(proposedTransactions.length - 1, _msgSender());
    }

    /**
     * @notice Allows a challenger to challenge a proposed transaction
     * @dev The function reverts if the caller is not a challenger, the transaction timestamp is invalid,
     * or the challenge period has expired. It sets the transaction's challenged flag to true if successful.
     * @dev A pausable function
     * @param transactionId the ID of the transaction to challenge
     */
    function challengeTransaction(
        uint256 transactionId
    ) external onlyCouncilMember whenNotPaused {
        // Makes sure the id exists
        require(
            transactionId < proposedTransactions.length,
            "TelcoinDistributor: Invalid index"
        );

        // Reverts if the current time exceeds the sum of the transaction's timestamp and the challenge period
        require(
            block.timestamp <=
                proposedTransactions[transactionId].timestamp + challengePeriod,
            "TelcoinDistributor: Challenge period has ended"
        );

        // Sets the challenged flag of the proposed transaction to true
        proposedTransactions[transactionId].challenged = true;

        // Emits an event with the transaction ID and the challenger's address
        emit TransactionChallenged(transactionId, _msgSender());
    }

    /**
     * @notice Execute transaction
     * @dev A pausable function
     * @param transactionId the transaction ID.
     */
    function executeTransaction(
        uint256 transactionId
    ) external onlyCouncilMember whenNotPaused {
        // Makes sure the id exists
        require(
            transactionId < proposedTransactions.length,
            "TelcoinDistributor: Invalid index"
        );
        // Reverts if the challenge period has not expired
        require(
            block.timestamp >
                proposedTransactions[transactionId].timestamp + challengePeriod,
            "TelcoinDistributor: Challenge period has not ended"
        );
        // makes sure the transaction was not challenged
        require(
            !proposedTransactions[transactionId].challenged,
            "TelcoinDistributor: transaction has been challenged"
        );
        // makes sure the transaction was not executed previously
        require(
            !proposedTransactions[transactionId].executed,
            "TelcoinDistributor: transaction has been previously executed"
        );
        // sends out transaction
        batchTelcoin(
            proposedTransactions[transactionId].totalWithdrawl,
            proposedTransactions[transactionId].destinations,
            proposedTransactions[transactionId].amounts
        );
        //markes transaction as executed
        proposedTransactions[transactionId].executed = true;
    }

    /**
     * @notice sends Telcoin in batches
     * @dev must first approve contract for balance
     * @dev if there is not a zero difference balance at the end of the transaction the transaction will revert
     * @param totalWithdrawl the total amount of tokens to be send
     * @param destinations an array of destinations
     * @param amounts an array of send values
     */
    function batchTelcoin(
        uint256 totalWithdrawl,
        address[] memory destinations,
        uint256[] memory amounts
    ) internal {
        // stores inital balance
        uint256 initialBalance = TELCOIN.balanceOf(address(this));
        //transfers amounts
        TELCOIN.safeTransferFrom(owner(), address(this), totalWithdrawl);
        for (uint i = 0; i < destinations.length; i++) {
            TELCOIN.safeTransfer(destinations[i], amounts[i]);
        }
        //initial balance is used instead of zero
        //if 0 is used instead stray Telcoin could DNS operations
        require(
            TELCOIN.balanceOf(address(this)) == initialBalance,
            "TelcoinDistributor: must not have leftovers"
        );
    }

    /**
     * @notice Updates the challenge period for transactions
     * @dev Only the owner contract can call this function
     * @param newPeriod the updated period
     */
    function setChallengePeriod(uint256 newPeriod) public onlyOwner {
        //update period
        challengePeriod = newPeriod;
        // Emitting an event for new period
        emit ChallengePeriodUpdated(challengePeriod);
    }

    /**
     * @notice Recover ERC20 tokens from THIS contract
     * @param tokenAddress ERC20 token contract
     * @param tokenAmount amount of tokens to recover
     * @param to account to send the recovered tokens to
     */
    function recoverERC20(
        IERC20 tokenAddress,
        uint256 tokenAmount,
        address to
    ) external onlyOwner {
        tokenAddress.safeTransfer(to, tokenAmount);
    }

    /**
     * @dev Triggers stopped state
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Checks if an account is a Council Member
     */
    modifier onlyCouncilMember() {
        // checks if caller has an NFT
        require(
            councilNft.balanceOf(_msgSender()) > 0,
            "TelcoinDistributor: Caller is not Council Member"
        );
        _;
    }
}
