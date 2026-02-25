# NFT Royalty Marketplace

A specialized smart contract for secondary market trading of NFTs with native support for creator royalties. This repository provides a robust solution for developers looking to build a marketplace that respects artist rights via the EIP-2981 standard.

## Overview
The marketplace acts as a decentralized intermediary. When an NFT is sold, the contract automatically calculates the royalty percentage defined by the creator, sends that portion to the artist, and the remainder to the seller.

### Key Features
* **EIP-2981 Integration:** Automatically fetches and pays royalties to creators.
* **Non-Custodial:** NFTs are only moved when a successful sale occurs.
* **Security First:** Utilizes ReentrancyGuard and Pull-over-Push payment patterns.
* **Flexible Listing:** Sellers can list, update prices, or cancel listings at any time.

## Technical Stack
* **Language:** Solidity ^0.8.20
* **Standards:** ERC-721, ERC-2981
* **License:** MIT

## Getting Started
1. Deploy the `NftMarketplace.sol` contract.
2. Sellers must `approve` the marketplace contract to handle their specific NFT.
3. Call `listNft` with the token address, token ID, and price.
4. Buyers call `buyNft` providing the required ETH (or native chain token).
