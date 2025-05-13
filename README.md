# ArtBidex – NFT Marketplace with Commit-Reveal Auctions

## **1. Project Overview**

ArtBidex is a decentralized NFT marketplace designed for artists and collectors to mint, auction, and trade digital art using a commit-reveal auction model. This method ensures bid privacy, fairness, and trustlessness throughout the auction lifecycle. The platform is built on modern Web3 technology, using Next.js for the frontend, Hardhat and Solidity for smart contracts, and Socket.IO for real-time updates.

---

## **2. Technology Stack**

| Layer | Tools/Frameworks |
| --- | --- |
| **Frontend** | Next.js 14+, TailwindCSS, Ethers.js |
| **Backend** | Next.js API Routes, Node.js, Socket.IO |
| **Blockchain** | Ethereum-compatible chains (Polygon, Arbitrum) |
| **Smart Contracts** | Solidity (ERC-721), Hardhat, OpenZeppelin |
| **Storage** | IPFS via NFT.Storage or Pinata |

---

## **3. Core Features**

### **3.1 NFT Minting**

**Purpose:**

Allow users to create NFTs by uploading their digital artwork and metadata.

**Workflow:**

1. Users upload images and enter metadata (title, description, etc.).
2. Files are uploaded to IPFS using NFT.Storage or Pinata.
3. Metadata URI is used to mint an ERC-721 token on-chain.
4. The minted NFT is immediately transferred to the user's wallet.

**Enhancements:**

- Live image preview before minting.
- File type/size validations.
- Metadata editing before mint confirmation.

---

### **3.2 Starting an Auction (Commit-Reveal Auction Model)**

**Purpose:**

Let NFT owners start private and fair auctions using a time-segmented process.

**Workflow:**

1. NFT owner selects an NFT they own.
2. Sets 3 key timestamps:
    - **`commitStart`** – When the commit phase begins.
    - **`commitEnd`** – Deadline for accepting commitments.
    - **`revealEnd`** – Deadline for bidders to reveal their bids.
3. The NFT is transferred to the auction smart contract and locked until the auction ends.

**Enhancements:**

- Option to schedule auctions in advance.
- Visual auction timeline showing all phases.
- Option to extend or shorten `commitEnd` or `revealEnd` (within bounds).

---

### **3.3 Commit Phase (Private Bidding)**

**Purpose:**

Allow users to place secret bids, avoiding sniping or bid manipulation.

**Workflow:**

1. Users calculate a hash of their bid amount and a random `salt`:
    
    `commitHash = keccak256(bidAmount, salt)`
    
2. This hash is sent to the smart contract with a small commitment deposit.
3. No one, not even the contract owner, can see the actual bid values during this phase.

---

### **3.4 Reveal Phase (Transparent Bidding)**

**Purpose:**

Ensure fairness by allowing users to reveal their actual bids with proof.

**Workflow:**

1. Users reveal their `bidAmount` and `salt`.
2. Smart contract verifies that the hash matches the original commitment.
3. Only valid revealed bids are considered.
4. Invalid or missing reveals are discarded.

---

### **3.5 Auction End & Finalization**

**Purpose:**

Conclude the auction, determine the winner, and settle funds and NFTs.

**Workflow:**

1. After `revealEnd`, the auction can be finalized.
2. The contract selects the highest valid revealed bid.
3. The NFT is transferred to the winner.
4. The seller receives the bid amount (minus platform/service fees).

---

### **3.6 Real-Time Updates (Socket.IO)**

**Purpose:**

Enhance user engagement with live auction updates.

**Features:**

- Broadcasts events in real time:
    - New commit submitted
    - Bid revealed
    - Auction ended and winner announced
- All connected clients see UI updates without refreshing.
- Notification banners or toasts for key events.

**Enhancements:**

- Push notifications (opt-in).
- Real-time auction tracker (with phase transitions).
- Visual progress bar per auction.

---

## **4. Additional Sections**

### **4.1 User Roles**

| Role | Capabilities |
| --- | --- |
| **Guest** | View auctions, explore NFTs |
| **Registered User (Wallet Connected)** | Mint NFTs, create auctions, place/reveal bids |
| **Admin** | Monitor auctions, moderate content, finalize stuck auctions |

---

### **4.2 Security & Validation**

- All inputs (bid amounts, salts) validated client-side and on-chain.
- Contract uses `reentrancyGuard` and follows best practices via OpenZeppelin.
- Bid values and hashes are never exposed prematurely.
- Bidders’ identities are tied to wallet addresses for transparency.

---

### **4.3 Smart Contract Design Highlights**

- **ERC-721 NFT Contract**: Minting and transferring NFTs.
- **Auction Contract**:
    - Stores `commitHash` mappings per user.
    - Stores revealed bids with validity checks.
    - Handles NFT transfer, bid validation, and finalization logic.
