// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Auction.sol";

contract AuctionManager is Ownable {
    address public nftContract;

    mapping(uint256 => address) public auctions;

    event AuctionCreated(address indexed auction, uint256 indexed tokenId);

    constructor(address _nftContract) {
        nftContract = _nftContract;
    }

    function createAuction(
        uint256 tokenId,
        uint256 commitStart,
        uint256 commitEnd,
        uint256 revealEnd
    ) external {
        require(commitStart < commitEnd && commitEnd < revealEnd, "Invalid time range");
        require(IERC721(nftContract).ownerOf(tokenId) == msg.sender, "Not the owner");

        Auction auction = new Auction(
            msg.sender,
            nftContract,
            tokenId,
            commitStart,
            commitEnd,
            revealEnd
        );

        auctions[tokenId] = address(auction);

        IERC721(nftContract).transferFrom(msg.sender, address(auction), tokenId);
        emit AuctionCreated(address(auction), tokenId);
    }
}