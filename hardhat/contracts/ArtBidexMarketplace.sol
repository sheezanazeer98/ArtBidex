// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ArtBidexMarketplace is ReentrancyGuard {
    struct Auction {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 commitStart;
        uint256 commitEnd;
        uint256 revealEnd;
        bool finalized;
        address highestBidder;
        uint256 highestBid;
        uint256 bidDeposit;
        bool active;
    }

    uint256 public auctionCount;

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => bytes32)) public commitments;
    mapping(uint256 => mapping(address => uint256)) public revealedBids;
    mapping(uint256 => address[]) public bidders; 
    mapping(uint256 => address[]) public committedBidders; 

    event AuctionCreated(uint256 indexed auctionId, address indexed seller, uint256 tokenId);
    event BidCommitted(uint256 indexed auctionId, address indexed bidder);
    event BidRevealed(uint256 indexed auctionId, address indexed bidder, uint256 bid);
    event AuctionFinalized(uint256 indexed auctionId, address winner, uint256 bid);
    event UnrevealedBidWithdrawn(uint256 indexed auctionId, address indexed bidder, uint256 deposit);

    // ========== MODIFIERS ==========

    modifier onlyInPhase(uint256 auctionId, uint8 phase) {
        Auction storage auction = auctions[auctionId];
        require(auction.active, "Auction inactive");
        if (phase == 0) {
            require(block.timestamp >= auction.commitStart && block.timestamp <= auction.commitEnd, "Not in commit");
        } else if (phase == 1) {
            require(block.timestamp > auction.commitEnd && block.timestamp <= auction.revealEnd, "Not in reveal");
        } else if (phase == 2) {
            require(block.timestamp > auction.revealEnd, "Too early");
        }
        _;
    }

    // ========== CORE FUNCTIONS ==========

    function createAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 commitStart,
        uint256 commitEnd,
        uint256 revealEnd,
        uint256 bidDeposit
    ) external returns (uint256 auctionId) {
        require(nftAddress != address(0), "Zero address");
        require(commitStart < commitEnd && commitEnd < revealEnd, "Invalid timeline");
        require(bidDeposit > 0, "Zero deposit");

        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");

        // Transfer NFT to marketplace
        nft.transferFrom(msg.sender, address(this), tokenId);

        auctionId = ++auctionCount;
        auctions[auctionId] = Auction({
            seller: msg.sender,
            nftAddress: nftAddress,
            tokenId: tokenId,
            commitStart: commitStart,
            commitEnd: commitEnd,
            revealEnd: revealEnd,
            finalized: false,
            highestBidder: address(0),
            highestBid: 0,
            bidDeposit: bidDeposit,
            active: true
        });

        emit AuctionCreated(auctionId, msg.sender, tokenId);
    }

    function commitBid(uint256 auctionId, bytes32 commitHash)
        external
        payable
        onlyInPhase(auctionId, 0)
    {
        Auction storage auction = auctions[auctionId];
        require(commitHash != bytes32(0), "Invalid commit");
        require(commitments[auctionId][msg.sender] == bytes32(0), "Already committed");
        require(msg.value == auction.bidDeposit, "Wrong deposit");

        commitments[auctionId][msg.sender] = commitHash;
        committedBidders[auctionId].push(msg.sender); // Track all committed bidders
        emit BidCommitted(auctionId, msg.sender);
    }

    function revealBid(uint256 auctionId, uint256 bidAmount, string calldata salt)
        external
        payable
        onlyInPhase(auctionId, 1)
    {
        bytes32 storedHash = commitments[auctionId][msg.sender];
        require(storedHash != bytes32(0), "No commit");
        require(revealedBids[auctionId][msg.sender] == 0, "Already revealed");

        require(keccak256(abi.encodePacked(bidAmount, salt)) == storedHash, "Bad reveal");
        require(msg.value == bidAmount, "Bid mismatch");

        Auction storage auction = auctions[auctionId];
        revealedBids[auctionId][msg.sender] = bidAmount;
        bidders[auctionId].push(msg.sender); // Track only revealed bidders

        // Update highest bidder logic
        if (bidAmount > auction.highestBid) {
            auction.highestBid = bidAmount;
            auction.highestBidder = msg.sender;
        }

        emit BidRevealed(auctionId, msg.sender, bidAmount);
    }

    function finalizeAuction(uint256 auctionId)
        external
        nonReentrant
        onlyInPhase(auctionId, 2)
    {
        Auction storage auction = auctions[auctionId];
        require(!auction.finalized, "Already finalized");

        auction.finalized = true;
        auction.active = false;

        IERC721 nft = IERC721(auction.nftAddress);
        address highest = auction.highestBidder;

        // Refund all non-winning bidders
        address[] memory _bidders = bidders[auctionId];
        for (uint256 i = 0; i < _bidders.length; ) {
            address bidder = _bidders[i];
            if (bidder != highest) {
                uint256 refund = revealedBids[auctionId][bidder];
                if (refund > 0) {
                    revealedBids[auctionId][bidder] = 0;
                    (bool success, ) = payable(bidder).call{value: refund}("");
                    require(success, "Refund failed");
                }
            }
            unchecked { ++i; }
        }

        // Transfer NFT and winning bid
        if (highest != address(0)) {
            nft.transferFrom(address(this), highest, auction.tokenId);
            (bool sent, ) = payable(auction.seller).call{value: auction.highestBid}("");
            require(sent, "Seller payment failed");
        } else {
            // No revealed bids, return NFT to seller
            nft.transferFrom(address(this), auction.seller, auction.tokenId);
        }

        emit AuctionFinalized(auctionId, highest, auction.highestBid);
    }

    // For bidders who committed but never revealed, allows withdrawal of deposit
    function withdrawUnrevealedBid(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp > auction.revealEnd, "Auction not ended");
        require(commitments[auctionId][msg.sender] != bytes32(0), "No commit");
        require(revealedBids[auctionId][msg.sender] == 0, "Revealed");

        commitments[auctionId][msg.sender] = bytes32(0);
        uint256 deposit = auction.bidDeposit;
        require(deposit > 0, "No deposit set");
        (bool sent, ) = payable(msg.sender).call{value: deposit}("");
        require(sent, "Deposit refund failed");

        emit UnrevealedBidWithdrawn(auctionId, msg.sender, deposit);
    }

    // ========== VIEWS ==========

    function getAuction(uint256 auctionId) external view returns (Auction memory) {
        return auctions[auctionId];
    }

    function getBidderCommitment(uint256 auctionId, address bidder) external view returns (bytes32) {
        return commitments[auctionId][bidder];
    }

    function getRevealedBid(uint256 auctionId, address bidder) external view returns (uint256) {
        return revealedBids[auctionId][bidder];
    }

    function getAllBidders(uint256 auctionId) external view returns (address[] memory) {
        return bidders[auctionId];
    }

    function isAuctionActive(uint256 auctionId) external view returns (bool) {
        return auctions[auctionId].active;
    }

    function getCommitHash(uint256 bidAmount, string memory salt) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(bidAmount, salt));
    }

    /// @notice Returns all addresses that have committed for a given auction and their respective commit hashes.
    function getAllCommitments(uint256 auctionId)
        external
        view
        returns (address[] memory, bytes32[] memory)
    {
        address[] memory addrs = committedBidders[auctionId];
        uint256 len = addrs.length;
        bytes32[] memory hashes = new bytes32[](len);
        for (uint256 i = 0; i < len; i++) {
            hashes[i] = commitments[auctionId][addrs[i]];
        }
        return (addrs, hashes);
    }
}
