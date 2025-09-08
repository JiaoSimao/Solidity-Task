// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import { HJNFT } from "./HJNFT.sol";

contract WrappedHJNFT is HJNFT{
    // 这里可以添加包装合约的逻辑，例如存储原始NFT的地址和ID
    constructor(string memory tokenName, string memory tokenSymbol) HJNFT(tokenName, tokenSymbol) {}

    function mintTokenWithSpecificTokenId(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

}