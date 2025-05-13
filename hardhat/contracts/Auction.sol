// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Auction is ReentrancyGuard {
    address public seller;
    address public nftContract;
    uint256 public tokenId;

    uint256 public commitStart;
    uint256 public commitEnd;
    uint256 public revealEnd;

    mapping(address => bytes32) public commitments;
    mapping(address => uint256) public revealedBids;
    address public highestBidder;
    uint256 public highestBid;
    bool public finalized;

    event Committed(address indexed bidder);
    event Revealed(address indexed bidder, uint256 amount);
    event Finalized(address winner, uint256 amount);

    constructor(
        address _seller,
        address _nftContract,
        uint256 _tokenId,
        uint256 _commitStart,
        uint256 _commitEnd,
        uint256 _revealEnd
    ) {
        seller = _seller;
        nftContract = _nftContract;
        tokenId = _tokenId;
        commitStart = _commitStart;
        commitEnd = _commitEnd;
        revealEnd = _revealEnd;
    }

    function commitBid(bytes32 commitHash) external payable {
        require(block.timestamp >= commitStart && block.timestamp < commitEnd, "Commit phase inactive");
        require(commitments[msg.sender] == bytes32(0), "Already committed");
        require(msg.value > 0, "Must send deposit");

        commitments[msg.sender] = commitHash;
        emit Committed(msg.sender);
    }

    function revealBid(uint256 bidAmount, string memory salt) external {
        require(block.timestamp >= commitEnd && block.timestamp < revealEnd, "Reveal phase inactive");
        require(commitments[msg.sender] != bytes32(0), "No commitment found");

        bytes32 hash = keccak256(abi.encodePacked(bidAmount, salt));
        require(commitments[msg.sender] == hash, "Invalid reveal");

        revealedBids[msg.sender] = bidAmount;

        if (bidAmount > highestBid) {
            highestBid = bidAmount;
            highestBidder = msg.sender;
        }

        emit Revealed(msg.sender, bidAmount);
    }

    function finalizeAuction() external nonReentrant {
        require(block.timestamp >= revealEnd, "Reveal phase not ended");
        require(!finalized, "Auction already finalized");

        finalized = true;
        if (highestBidder != address(0)) {
            payable(seller).transfer(highestBid);
            IERC721(nftContract).transferFrom(address(this), highestBidder, tokenId);
        } else {
            IERC721(nftContract).transferFrom(address(this), seller, tokenId);
        }

        emit Finalized(highestBidder, highestBid);
    }
}