pragma solidity 0.8;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract EnglishAuction {
    struct NFT {
        address tokenAddress;
        uint256 tokenId;
    }

    struct Auction {
        address seller;
        uint256 reservePrice;
        uint256 duration;
        NFT sellerNFT;
        uint256 highestBid;
        address highestBidderAddress;
    }
    // bool active;

    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => mapping(address => uint256)) AmountUserContribute;
    uint256 public nextId;

    // creating and depositing NFT in Auction by seller
    function deposit(uint256 _reservePrice, uint256 _duration, address nftAddress, uint256 tokenId)
        external
        returns (uint256 auctionId)
    {
        nextId++;
        auctions[nextId] = Auction({
            seller: msg.sender,
            reservePrice: _reservePrice,
            duration: block.timestamp + _duration,
            sellerNFT: NFT(nftAddress, tokenId),
            highestBid: 0,
            highestBidderAddress: address(0)
        });
        // active: true

        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);

        return nextId;
    }

    function bid(uint256 auctionId) external payable {
        Auction storage auction = auctions[auctionId];
        require(msg.value > 0, "Value cant be 0 ");
        // require(auction.active, "Auction is closed");
        require(auction.duration > block.timestamp, "Auction ended");

        AmountUserContribute[auctionId][msg.sender] += msg.value;

        if (msg.value > auction.highestBid) {
            auction.highestBidderAddress = msg.sender;
            auction.highestBid = msg.value;
        }
    }

    function sellerEndAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        require(msg.sender == auction.seller, "Seller is not same");
        require(auction.duration < block.timestamp, "Deadline is not ended");
        IERC721(auction.sellerNFT.tokenAddress).safeTransferFrom(
            address(this), auction.highestBidderAddress, auction.sellerNFT.tokenId
        );

        (bool sent,) = auction.seller.call{value: auction.highestBid}("");
        require(sent, "Failed to transfer money");
    }

    // withdraw will implemented later
    // function withdraw(uint256 auctionId) {}
}
