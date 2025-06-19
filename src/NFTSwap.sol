// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTSwap {
    struct NFT {
        address tokenAddress;
        uint256 tokenId;
    }

    struct Swap {
        address userA;
        address userB;
        NFT nftA;
        NFT nftB;
        bool depositA;
        bool depositB;
        bool complete;
    }

    mapping(uint256 => Swap) public swaps;
    uint256 public nextId;

    function createSwap(address userB, address nftAddressA, uint256 nftAId, address nftAddressB, uint256 nftBId)
        external
        returns (uint256 swapId)
    {
        nextId++;
        swaps[nextId] = Swap({
            userA: msg.sender,
            userB: userB,
            nftA: NFT(nftAddressA, nftAId),
            nftB: NFT(nftAddressB, nftBId),
            depositA: false,
            depositB: false,
            complete: false
        });
        return swapId;
    }

    function deposit(uint256 swapId) external {
        Swap storage swap = swaps[swapId];
        require(!swap.complete, "Swap is completed");
        if (msg.sender == swap.userA) {
            require(!swap.depositA, "already deposited");
            IERC721(swap.nftA.tokenAddress).safeTransferFrom(msg.sender, address(this), swap.nftA.tokenId);
            swap.depositA = true;
        } else if (msg.sender == swap.userB) {
            require(!swap.depositB, "already deposited");
            IERC721(swap.nftB.tokenAddress).safeTransferFrom(msg.sender, address(this), swap.nftB.tokenId);
            swap.depositB = true;
        } else {
            revert("Not a part of Swap !!");
        }
    }

    function swapNft(uint256 swapId) public {
        // using storage to point actual swap instead of copy
        Swap storage swap = swaps[swapId];
        require(!swap.complete, "swap is already done");
        require(swap.depositA && swap.depositB, "user A or B has not deposited NFT");

        swap.complete = true;
        IERC721(swap.nftA.tokenAddress).safeTransferFrom(address(this), swap.userB, swap.nftA.tokenId);
        IERC721(swap.nftB.tokenAddress).safeTransferFrom(address(this), swap.userA, swap.nftB.tokenId);
    }

    // Add cancel Swap function to handle corner case
    //with condition if anyone has deposited and other has not than they can withdraw
}
