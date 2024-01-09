//SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../core/BaseGuard.sol";

/**
 * @title SafeGuard
 * @author Amir M. Shirif
 * @notice A Telcoin Laboratories Contract
 * @notice Designed to protect against non-compliant votes
 */
contract SafeGuard is BaseGuard, Ownable {
    error PreviouslyVetoed(bytes32 hash);

    // Mapping of transaction hash to its veto status
    mapping(bytes32 => bool) public transactionHashes;
    uint256[] public nonces;

    constructor() Ownable(_msgSender()) {}

    /**
     * @notice Allows the contract owner to veto a transaction by its hash
     * @dev restricted to onlyOwner
     * @param transactionHash Hash of the transaction to be vetoed
     * @param nonce Nonce of the transaction
     */
    function vetoTransaction(
        bytes32 transactionHash,
        uint256 nonce
    ) public onlyOwner {
        // Revert if the transaction has already been vetoed
        if (transactionHashes[transactionHash])
            revert PreviouslyVetoed(transactionHash);
        // Mark the transaction as vetoed
        transactionHashes[transactionHash] = true;
        // Add the nonce of the transaction to the nonces array
        nonces.push(nonce);
    }

    /**
     * @dev Checks if a transaction has been vetoed by its hash
     * @param to Address of the recipient of the transaction
     * @param value Value of the transaction
     * @param data Data of the transaction
     * @param operation Operation of the transaction
     */
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes memory,
        address
    ) external view override {
        // cycles through possible transactions
        for (uint256 i = 0; i < nonces.length; i++) {
            bytes32 transactionHash = IReality(_msgSender()).getTransactionHash(
                to,
                value,
                data,
                operation,
                nonces[i]
            );
            require(
                !transactionHashes[transactionHash],
                "SafeGuard: transaction has been vetoed"
            );
        }
    }

    // not used
    function checkAfterExecution(bytes32, bool) external view override {}
}
