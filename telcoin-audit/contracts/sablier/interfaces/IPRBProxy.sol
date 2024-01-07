// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/// @title IPRBProxy
/// @notice Proxy contract to compose transactions on behalf of the owner.
interface IPRBProxy {
    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Delegate calls to the provided target contract by forwarding the data. It returns the data it
    /// gets back, and bubbles up any potential revert.
    ///
    /// @dev Emits an {Execute} event.
    ///
    /// Requirements:
    /// - The caller must be either the owner or an envoy with permission.
    /// - `target` must be a contract.
    ///
    /// @param target The address of the target contract.
    /// @param data Function selector plus ABI encoded data.
    /// @return response The response received from the target contract, if any.
    function execute(
        address target,
        bytes calldata data
    ) external payable returns (bytes memory response);
}
