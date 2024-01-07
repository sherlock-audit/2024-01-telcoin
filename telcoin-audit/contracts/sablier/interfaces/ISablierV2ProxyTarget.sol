// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

interface ISablierV2Lockup {}

/// @title ISablierV2ProxyTarget
/// @notice Proxy target with stateless scripts for interacting with Sablier V2, designed to be used by
/// stream senders.
/// @dev Intended for use with an instance of PRBProxy through delegate calls. Any standard calls will be reverted.
interface ISablierV2ProxyTarget {
    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER-V2-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Cancels multiple streams across different lockup contracts.
    ///
    /// @dev Notes:
    /// - All refunded assets are forwarded to the proxy owner.
    /// - It is assumed that `assets` includes all assets associated with the stream ids in `batch`. If any asset
    /// is missing, the refunded amount will be left in the proxy.
    ///
    /// Requirements:
    /// - Must be delegate called.

    /// @notice Mirror for {ISablierV2Lockup.withdrawMax}.
    /// @dev Must be delegate called.
    function withdrawMax(
        ISablierV2Lockup lockup,
        uint256 streamId,
        address to
    ) external;
}
