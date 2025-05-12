// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ArtBidexMarketplace is ERC721URIStorage, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    struct Auction {
        address seller;
        uint256 startingBid;
        uint256 instantBuyPrice;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool isActive;
    }

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) public userBids; // for refunds

    event NFTMinted(uint256 indexed tokenId, address indexed owner, string tokenURI);
    event AuctionStarted(uint256 indexed tokenId, address indexed seller, uint256 startingBid, uint256 endTime, uint256 instantBuyPrice);
    event NewBid(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed tokenId, address winner, uint256 finalBid);
    event NFTInstantBought(uint256 indexed tokenId, address buyer, uint256 price);

    constructor() ERC721("ArtBidexNFT", "ABX") {}

    function mintNFT(string memory tokenURI) external returns (uint256) {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();

        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);

        emit NFTMinted(tokenId, msg.sender, tokenURI);
        return tokenId;
    }

    function startAuction(uint256 tokenId, uint256 startingBid, uint256 durationSeconds, uint256 instantBuyPrice) external {
        require(ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(auctions[tokenId].isActive == false, "Auction already exists");

        transferFrom(msg.sender, address(this), tokenId); // lock NFT

        auctions[tokenId] = Auction({
            seller: msg.sender,
            startingBid: startingBid,
            instantBuyPrice: instantBuyPrice,
            highestBid: 0,
            highestBidder: address(0),
            endTime: block.timestamp + durationSeconds,
            isActive: true
        });

        emit AuctionStarted(tokenId, msg.sender, startingBid, auctions[tokenId].endTime, instantBuyPrice);
    }

    function placeBid(uint256 tokenId) external payable nonReentrant {
        Auction storage a = auctions[tokenId];
        require(a.isActive, "Auction not active");
        require(block.timestamp < a.endTime, "Auction ended");
        require(msg.value > a.highestBid && msg.value >= a.startingBid, "Bid too low");

        if (a.highestBidder != address(0)) {
            payable(a.highestBidder).transfer(a.highestBid); // refund previous
        }

        a.highestBid = msg.value;
        a.highestBidder = msg.sender;

        emit NewBid(tokenId, msg.sender, msg.value);
    }

    function endAuction(uint256 tokenId) external nonReentrant {
        Auction storage a = auctions[tokenId];
        require(a.isActive, "Auction not active");
        require(block.timestamp >= a.endTime, "Auction not yet ended");

        a.isActive = false;

        if (a.highestBidder != address(0)) {
            _transfer(address(this), a.highestBidder, tokenId);
            payable(a.seller).transfer(a.highestBid);
        } else {
            _transfer(address(this), a.seller, tokenId); // no bids
        }

        emit AuctionEnded(tokenId, a.highestBidder, a.highestBid);
    }

    function instantBuy(uint256 tokenId) external payable nonReentrant {
        Auction storage a = auctions[tokenId];
        require(a.isActive, "Auction not active");
        require(msg.value >= a.instantBuyPrice && a.instantBuyPrice > 0, "Invalid instant buy");

        a.isActive = false;

        if (a.highestBidder != address(0)) {
            payable(a.highestBidder).transfer(a.highestBid); // refund previous bidder
        }

        _transfer(address(this), msg.sender, tokenId);
        payable(a.seller).transfer(msg.value);

        emit NFTInstantBought(tokenId, msg.sender, msg.value);
    }

    function getAuctionDetails(uint256 tokenId) external view returns (Auction memory) {
        return auctions[tokenId];
    }
}
