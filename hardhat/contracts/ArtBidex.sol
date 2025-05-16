// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArtBidexNFT is ERC721URIStorage, Ownable {
    uint256 private _tokenIds;

    constructor() ERC721("ArtBidex", "ABDX") Ownable(msg.sender) {}

    function mint(address recipient, string memory tokenURI) external returns (uint256) {
        _tokenIds += 1;
        uint256 newItemId = _tokenIds;

        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }
}
