// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/ISablierV2ProxyTarget.sol";
import "../interfaces/IPRBProxy.sol";

/**
 * @title CouncilMember
 * @author Amir M. Shirif
 * @notice A Telcoin Laboratories Contract
 * @notice A contract to signify ownership council membership
 * @dev Relies on OpenZeppelin's open source smart contracts
 */
contract CouncilMember is
    ERC721EnumerableUpgradeable,
    AccessControlEnumerableUpgradeable
{
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */
    // Event fired when the stream is updated
    event StreamUpdated(IPRBProxy newStream);
    // Event fired when the target address is updated
    event TargetUpdated(address newTarget);
    // Event fired when the ID is updated
    event IDUpdated(uint256 newID);

    /* ========== STATE VARIABLES ========== */
    // The main token of this ecosystem
    IERC20 public TELCOIN;
    // Stream proxy address for this contract
    IPRBProxy public _stream;
    // here is the implentation address
    address public _target;
    // the id associated with the sablier NFT
    uint256 public _id;
    // balance left over from last rebalancing
    uint256 private runningBalance;
    // current uncliamed members balances
    uint256[] public balances;
    // Mapping of who can send each NFT index
    mapping(uint256 => address) private _tokenApproval;

    /* ========== ROLES ========== */
    // Role assigned for the governance council
    bytes32 public constant GOVERNANCE_COUNCIL_ROLE =
        keccak256("GOVERNANCE_COUNCIL_ROLE");
    // Support role for additional functionality
    bytes32 public constant SUPPORT_ROLE = keccak256("SUPPORT_ROLE");

    /* ========== INITIALIZER ========== */
    function initialize(
        IERC20 telcoin,
        string memory name_,
        string memory symbol_,
        IPRBProxy stream_,
        address target_,
        uint256 id_
    ) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        __ERC721_init(name_, symbol_);
        TELCOIN = telcoin;
        _stream = stream_;
        _target = target_;
        _id = id_;
    }

    /************************************************
     *   external functions
     ************************************************/

    /**
     * @notice Allows authorized personnel to retrieve and distribute TELCOIN to council members
     * @dev The main logic behind the TELCOIN distribution is encapsulated in this function.
     * @dev This function should be called before any significant state changes to ensure accurate distribution.
     * @dev Only the owner council members can call this function
     */
    function retrieve() external OnlyAuthorized {
        _retrieve();
    }

    /**
     * @notice Allows council members to claim their allocated amounts of TELCOIN
     * @dev Checks if the caller is the owner of the provided tokenId and if the requested amount is available.
     * @param tokenId The NFT index associated with a council member.
     * @param amount Amount of TELCOIN the council member wants to withdraw.
     */
    function claim(uint256 tokenId, uint256 amount) external {
        // Ensure the function caller is the owner of the token (council member) they're trying to claim for
        require(
            _msgSender() == ownerOf(tokenId),
            "CouncilMember: caller is not council member holding this NFT index"
        );
        // Retrieve and distribute any pending TELCOIN for all council members
        _retrieve();

        // Ensure the requested amount doesn't exceed the balance of the council member
        require(
            amount <= balances[tokenId],
            "CouncilMember: withdrawal amount is higher than balance"
        );

        // Deduct the claimed amount from the token's balance
        balances[tokenId] -= amount;
        // Safely transfer the claimed amount of TELCOIN to the function caller
        TELCOIN.safeTransfer(_msgSender(), amount);
    }

    /**
     * @notice Replace an existing council member with a new one and withdraws the old member's TELCOIN allocation
     * @dev This function is restricted to the GOVERNANCE_COUNCIL_ROLE.
     * @dev Allows TEL reward to be sent to a different address
     * @param from Address of the current council member to be replaced.
     * @param to Address of the new council member.
     * @param tokenId Token ID of the council member NFT.
     * @param rewardRecipient Address where the old member's TELCOIN will be sent.
     */
    function removeFromOffice(
        address from,
        address to,
        uint256 tokenId,
        address rewardRecipient
    ) external onlyRole(GOVERNANCE_COUNCIL_ROLE) {
        // Retrieve and distribute any pending TELCOIN for all council members
        _retrieve();
        // Withdraw all the TELCOIN rewards for the specified token to the rewardRecipient
        _withdrawAll(rewardRecipient, tokenId);
        // Transfer the token (representing the council membership) from one address to another
        _transfer(from, to, tokenId);
    }

    /************************************************
     *   view functions
     ************************************************/

    /**
     * @notice Check if the contract supports a specific interface
     * @dev Overrides the supportsInterface function from OpenZeppelin.
     * @param interfaceId ID of the interface to check for support.
     * @return True if the contract supports the interface, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        pure
        override(
            AccessControlEnumerableUpgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return
            interfaceId ==
            type(AccessControlEnumerableUpgradeable).interfaceId ||
            interfaceId == type(ERC721EnumerableUpgradeable).interfaceId;
    }

    /************************************************
     *   mutative functions
     ************************************************/

    /**
     * @notice Mint new council member NFTs
     * @dev This function also retrieves and distributes TELCOIN.
     * @dev Restricted to the GOVERNANCE_COUNCIL_ROLE.
     * @param newMember Address of the new council member.
     */
    function mint(
        address newMember
    ) external onlyRole(GOVERNANCE_COUNCIL_ROLE) {
        if (totalSupply() != 0) {
            _retrieve();
        }

        balances.push(0);
        _mint(newMember, totalSupply());
    }

    /**
     * @notice Approve a specific address for a specific NFT
     * @dev Overrides the approve function from ERC721.
     * @dev Restricted to the GOVERNANCE_COUNCIL_ROLE.
     * @param to Address to be approved.
     * @param tokenId Token ID of the NFT to be approved.
     */
    function approve(
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721)
        onlyRole(GOVERNANCE_COUNCIL_ROLE)
    {
        _tokenApproval[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @notice Burn a council member NFT
     * @dev The function retrieves and distributes TELCOIN before burning the NFT.
     * @dev Restricted to the GOVERNANCE_COUNCIL_ROLE.
     * @param tokenId Token ID of the council member NFT to be burned.
     * @param recipient Address to receive the burned NFT holder's TELCOIN allocation.
     */
    function burn(
        uint256 tokenId,
        address recipient
    ) external onlyRole(GOVERNANCE_COUNCIL_ROLE) {
        require(totalSupply() > 1, "CouncilMember: must maintain council");
        _retrieve();
        _withdrawAll(recipient, tokenId);

        uint256 balance = balances[balances.length - 1];
        balances[tokenId] = balance;
        balances.pop();
        _burn(tokenId);
    }

    /**
     * @notice Update the stream proxy address
     * @dev Restricted to the GOVERNANCE_COUNCIL_ROLE.
     * @param stream_ New stream proxy address.
     */
    function updateStream(
        IPRBProxy stream_
    ) external onlyRole(GOVERNANCE_COUNCIL_ROLE) {
        _stream = stream_;
        emit StreamUpdated(_stream);
    }

    /**
     * @notice Update the target address
     * @dev Restricted to the GOVERNANCE_COUNCIL_ROLE.
     * @param target_ New target address.
     */
    function updateTarget(
        address target_
    ) external onlyRole(GOVERNANCE_COUNCIL_ROLE) {
        _target = target_;
        emit TargetUpdated(_target);
    }

    /**
     * @notice Update the ID for a council member
     * @dev Restricted to the GOVERNANCE_COUNCIL_ROLE.
     * @param id_ New ID for the council member.
     */
    function updateID(uint256 id_) external onlyRole(GOVERNANCE_COUNCIL_ROLE) {
        _id = id_;
        emit IDUpdated(_id);
    }

    /************************************************
     *   internal functions
     ************************************************/

    /**
     * @notice Retrieve and distribute TELCOIN to council members based on the stream from _target
     * @dev This function fetches the maximum possible TELCOIN and distributes it equally among all council members.
     * @dev It also updates the running balance to ensure accurate distribution during subsequent calls.
     */
    function _retrieve() internal {
        // Get the initial TELCOIN balance of the contract
        uint256 initialBalance = TELCOIN.balanceOf(address(this));
        // Execute the withdrawal from the _target, which might be a Sablier stream or another protocol
        _stream.execute(
            _target,
            abi.encodeWithSelector(
                ISablierV2ProxyTarget.withdrawMax.selector,
                _target,
                _id,
                address(this)
            )
        );

        // Get the new balance after the withdrawal
        uint256 currentBalance = TELCOIN.balanceOf(address(this));
        // Calculate the amount of TELCOIN that was withdrawn during this operation
        uint256 finalBalance = (currentBalance - initialBalance) +
            runningBalance;
        // Distribute the TELCOIN equally among all council members
        uint256 individualBalance = finalBalance / totalSupply();
        // Update the running balance which keeps track of any TELCOIN that can't be evenly distributed
        runningBalance = finalBalance % totalSupply();

        // Add the individual balance to each council member's balance
        for (uint i = 0; i < balances.length; i++) {
            balances[i] += individualBalance;
        }
    }

    /**
     * @notice Determines if an address is approved or is the owner for a specific token ID
     * @dev This function checks if the spender has GOVERNANCE_COUNCIL_ROLE or is the approved address for the token.
     * @param spender Address to check approval or ownership for.
     * @param tokenId Token ID to check against.
     * @return True if the address is approved or is the owner, false otherwise.
     */
    function _isAuthorized(
        address,
        address spender,
        uint256 tokenId
    ) internal view override returns (bool) {
        return (hasRole(GOVERNANCE_COUNCIL_ROLE, spender) ||
            _tokenApproval[tokenId] == spender);
    }

    /**
     * @notice Handle operations to be performed before transferring a token
     * @dev This function retrieves and distributes TELCOIN before the token transfer.
     * @dev It is an override of the _beforeTokenTransfer from OpenZeppelin's ERC721.
     * @param to Address from which the token is being transferred.
     * @param tokenId Token ID that's being transferred.
     * @param auth Token ID that's being transferred.
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        if (totalSupply() != 0) {
            _retrieve();
        }

        return super._update(to, tokenId, auth);
    }

    /**
     * @notice Withdraws all allocated TELCOIN for a council member
     * @dev This function safely transfers the TELCOIN to the given address and resets their balance.
     * @param from Address to which the TELCOIN will be sent.
     * @param tokenId Token ID of the council member to withdraw the TELCOIN for.
     */
    function _withdrawAll(address from, uint256 tokenId) internal {
        TELCOIN.safeTransfer(from, balances[tokenId]);
        balances[tokenId] = 0;
    }

    /************************************************
     *   helper functions
     ************************************************/

    /**
     * @notice Rescues any ERC20 token sent accidentally to the contract
     * @dev Only addresses with the SUPPORT_ROLE can call this function.
     * @param token ERC20 token address which needs to be rescued.
     * @param destination Address where the tokens will be sent.
     * @param amount Amount of tokens to be transferred.
     */
    function erc20Rescue(
        IERC20 token,
        address destination,
        uint256 amount
    ) external onlyRole(SUPPORT_ROLE) {
        token.safeTransfer(destination, amount);
    }

    /************************************************
     *   modifiers
     ************************************************/

    /**
     * @notice Checks if the caller is authorized either by being a council member or having the GOVERNANCE_COUNCIL_ROLE
     * @dev This modifier is used to restrict certain operations to council members or governance personnel.
     */
    modifier OnlyAuthorized() {
        require(
            hasRole(GOVERNANCE_COUNCIL_ROLE, _msgSender()) ||
                ERC721Upgradeable.balanceOf(_msgSender()) >= 1,
            "CouncilMember: caller is not council member or owner"
        );
        _;
    }
}
