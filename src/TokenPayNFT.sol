pragma solidity 0.8;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TokenPayNFT is ERC721URIStorage, Ownable {
    IERC20 public paymentToken;
    uint256 public mintPrice;
    uint256 public nextTokenId;

    constructor(address _paymentToken, uint256 _mintPrice, string memory name, string memory symbol)
        Ownable(msg.sender)
        ERC721(name, symbol)
    {
        paymentToken = IERC20(_paymentToken);
        mintPrice = _mintPrice;
    }

    function mint(string memory tokenURI) public {
        require(paymentToken.transferFrom(msg.sender, address(this), mintPrice), "Failed To Mint");
        uint256 tokenId = nextTokenId;
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI);
        nextTokenId++;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        paymentToken.transfer(owner(), balance);
    }
}
