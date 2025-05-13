// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArtBidexNFT is ERC721URIStorage, Ownable {
    uint256 public tokenIdCounter;

    constructor() ERC721("ArtBidex", "ABX") {}

    function mint(string memory tokenURI) external returns (uint256) {
        uint256 newTokenId = tokenIdCounter++;
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        return newTokenId;
    }
}
