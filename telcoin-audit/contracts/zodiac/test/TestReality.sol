//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IReality.sol";
import "../enums/Operation.sol";

//TESTING ONLY
contract TestReality is IReality {
    struct Question {
        bytes32 bestAnswer;
        address answerer;
    }

    mapping(bytes32 => Question) private questions;

    function get(string memory byteMe) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(byteMe));
    }

    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 nonce
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(to, value, data, operation, nonce));
    }

    function notifyOfArbitrationRequest(
        bytes32 question_id,
        address requester,
        uint256 max_previous
    ) external {}

    function submitAnswerByArbitrator(
        bytes32 question_id,
        bytes32 answer,
        address answerer
    ) external {
        questions[question_id].bestAnswer = answer;
        questions[question_id].answerer = answerer;
    }

    function getBestAnswer(
        bytes32 question_id
    ) external view returns (bytes32) {
        return questions[question_id].bestAnswer;
    }
}
