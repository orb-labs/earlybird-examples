// utils/TestNFT.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract TestNFT is ERC721 {
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
}
