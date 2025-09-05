// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import { MyToken } from "./MyToken.sol";

contract WrappedMyToken is MyToken {
    constructor(string memory tokenName, string memory tokenSymbol) 
    MyToken(tokenName, tokenSymbol) {}

    function mintTokenWithSpecificTokenId(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }

}