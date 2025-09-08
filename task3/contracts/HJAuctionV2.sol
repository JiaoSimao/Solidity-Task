// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;
import "./HJAuction.sol";


contract HJAuctionV2 is HJAuction {
    //新增功能：获取某个卖家的所有拍卖ID
    function getAuctionsBySeller(address seller) public view returns (uint256[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < nextAuctionId; i++) {
            if (auctions[i].seller == seller) {
                count++;
            }
        }

        uint256[] memory sellerAuctionIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < nextAuctionId; i++) {
            if (auctions[i].seller == seller) {
                sellerAuctionIds[index] = i;
                index++;
            }
        }
        return sellerAuctionIds;
    }
}
