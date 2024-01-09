// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//TESTING ONLY
contract TestNFT is ERC721 {
    constructor() ERC721("TestNFT", "NFT") {
        _safeMint(msg.sender, 1);
    }

    function mint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
}
