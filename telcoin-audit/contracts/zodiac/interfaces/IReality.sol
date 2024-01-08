//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../enums/Operation.sol";

interface IReality {
    /// Returns the transaction hash for a given transaction
    /// @param to The address the transaction is being sent to
    /// @param value The amount of Ether being sent
    /// @param data The data being sent with the transaction
    /// @param operation The type of operation being performed
    /// @param nonce The nonce of the transaction
    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 nonce
    ) external view returns (bytes32);

    /// @notice Notify the contract that the arbitrator has been paid for a question, freezing it pending their decision.
    /// @dev The arbitrator contract is trusted to only call this if they've been paid, and tell us who paid them.
    /// @param question_id The ID of the question
    /// @param requester The account that requested arbitration
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    function notifyOfArbitrationRequest(
        bytes32 question_id,
        address requester,
        uint256 max_previous
    ) external;

    /// @notice Submit the answer for a question, for use by the arbitrator.
    /// @dev Doesn't require (or allow) a bond.
    /// If the current final answer is correct, the account should be whoever submitted it.
    /// If the current final answer is wrong, the account should be whoever paid for arbitration.
    /// However, the answerer stipulations are not enforced by the contract.
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded into bytes32
    /// @param answerer The account credited with this answer for the purpose of bond claims
    function submitAnswerByArbitrator(
        bytes32 question_id,
        bytes32 answer,
        address answerer
    ) external;

    /// @notice Returns the best answer for a question
    /// @param question_id The ID of the question
    function getBestAnswer(bytes32 question_id) external view returns (bytes32);
}
