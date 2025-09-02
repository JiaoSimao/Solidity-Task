// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNftToken is ERC721, ERC721URIStorage, Ownable{
    uint256 public _tokenId;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender){
        _tokenId = 0;
    }

    function mintNFT(address recipient, string memory tokenUri) public onlyOwner{
        uint256 newTokenId = _tokenId;
        _tokenId++;
        _safeMint(recipient, newTokenId);
        _setTokenURI(newTokenId, tokenUri);
    }

    // 必须重写这两个函数，因为ERC721和ERC721URIStorage都实现了它们
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public  view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
}