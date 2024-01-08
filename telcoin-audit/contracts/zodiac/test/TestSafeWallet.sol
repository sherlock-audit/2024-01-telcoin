// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../enums/Operation.sol";

//TESTING ONLY
contract TestSafeWallet {
    bytes public _data;

    function execTransactionFromModule(
        address,
        uint256,
        bytes calldata data,
        Enum.Operation
    ) external returns (bool success) {
        _data = data;
        return true;
    }
}
