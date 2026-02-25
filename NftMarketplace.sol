// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NftMarketplace
 * @dev A marketplace contract with automated royalty payments via EIP-2981.
 */
contract NftMarketplace is ReentrancyGuard {
    struct Listing {
        address seller;
        uint256 price;
    }

    // Mapping: NFT Contract -> Token ID -> Listing Data
    mapping(address => mapping(uint256 => Listing)) private listings;

    event NftListed(address indexed seller, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event NftSold(address indexed buyer, address indexed nftAddress, uint256 indexed tokenId, uint256 price);
    event ListingCanceled(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);

    function listNft(address nftAddress, uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Not approved");

        listings[nftAddress][tokenId] = Listing(msg.sender, price);
        emit NftListed(msg.sender, nftAddress, tokenId, price);
    }

    function buyNft(address nftAddress, uint256 tokenId) external payable nonReentrant {
        Listing memory listedItem = listings[nftAddress][tokenId];
        require(listedItem.price > 0, "Item not listed");
        require(msg.value >= listedItem.price, "Insufficient payment");

        delete listings[nftAddress][tokenId];

        // Handle Royalties (EIP-2981)
        uint256 royaltyAmount = 0;
        address royaltyReceiver;

        try IERC2981(nftAddress).royaltyInfo(tokenId, msg.value) returns (address receiver, uint256 amount) {
            royaltyReceiver = receiver;
            royaltyAmount = amount;
        } catch {}

        if (royaltyAmount > 0 && royaltyReceiver != address(0)) {
            (bool royaltySuccess, ) = payable(royaltyReceiver).call{value: royaltyAmount}("");
            require(royaltySuccess, "Royalty payment failed");
        }

        uint256 sellerProceeds = msg.value - royaltyAmount;
        (bool sellerSuccess, ) = payable(listedItem.seller).call{value: sellerProceeds}("");
        require(sellerSuccess, "Seller payment failed");

        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);

        emit NftSold(msg.sender, nftAddress, tokenId, msg.value);
    }

    function cancelListing(address nftAddress, uint256 tokenId) external {
        require(listings[nftAddress][tokenId].seller == msg.sender, "Not the seller");
        delete listings[nftAddress][tokenId];
        emit ListingCanceled(msg.sender, nftAddress, tokenId);
    }

    function getListing(address nftAddress, uint256 tokenId) external view returns (Listing memory) {
        return listings[nftAddress][tokenId];
    }
}
