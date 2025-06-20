// trying to create a marketplace where user just approve but doesnt need to send it to contract

pragma solidity 0.8;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SimpleMarketplace {
    struct NFT {
        address tokenAddress;
        uint256 tokenId;
    }

    struct List {
        address seller;
        uint256 price;
        uint256 duration;
        NFT nft;
        bool available;
    }

    mapping(uint256 => List) public listings;
    uint256 public nextId;

    function Sell(address nftAddress, uint256 tokenId, uint256 _price, uint256 _duration)
        external
        returns (uint256 nftId)
    {
        nextId++;
        listings[nextId] = List({
            seller: msg.sender,
            price: _price,
            duration: block.timestamp + _duration,
            nft: NFT({tokenAddress: nftAddress, tokenId: tokenId}),
            available: true
        });
        IERC721(nftAddress).approve(address(this), tokenId);

        return nextId;
    }

    function Buy(uint256 nftId) external {
        List storage list = listings[nftId];
        require(list.duration > block.timestamp, "NFT listing expired!");
        require(list.available, "NFT already sold");
        (bool sent,) = list.seller.call{value: list.price}("");
        require(sent, "Failed to transfer money");

        IERC721(list.nft.tokenAddress).transferFrom(list.seller, msg.sender, list.nft.tokenId);
    }
}
