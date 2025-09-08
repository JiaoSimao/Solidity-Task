// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./HJAuction.sol";

contract HJAuctionFactory is Initializable, UUPSUpgradeable, Ownable {
// contract HJAuctionFactory {
    address public auctionImplementation; // 拍卖合约实现地址

    address[] public allAuctions; // 所有拍卖合约地址

    //拍卖合约地址映射到创建者
    mapping(address => address) public auctionToCreator;
    // 用户创建的拍卖合约列表
    mapping(address => address[]) public userAuctions;
    
    //合约创建事件
    event AuctionCreated(address auctionAddress, address creator, address implementation);
    //更新代理地址事件
    event UpdateImplementation(address oldImplementation, address newImplementation);


    constructor() Ownable(msg.sender) {
        _disableInitializers();
    }

    function initialize(address _auctionImplementation, address _owner) initializer public {
        require(_auctionImplementation != address(0), "Invalid auction implementation address");
        require(_owner != address(0), "Invalid owner address");

        __UUPSUpgradeable_init();
        _transferOwnership(_owner);
        auctionImplementation = _auctionImplementation;
        
    }

    function createAuction(
        address auction
    ) external returns (address) {
        require(auction != address(0), "Invalid auction address");
        //克隆拍卖合约
        address clone = Clones.clone(auctionImplementation);
        //初始化拍卖合约
        HJAuction(clone).initialize();
        
        allAuctions.push(auction);
        auctionToCreator[auction] = msg.sender;
        userAuctions[msg.sender].push(auction);
        
        emit AuctionCreated(clone, msg.sender, auction);
        
        return clone;
    }


    // function createAuction2(
    //     uint256 duration, 
    //     uint256 startPrice, 
    //     address nftContractAddress, 
    //     uint256 tokenId) external returns (address){
    //     HJAuction auction = new HJAuction(
    //             msg.sender,
    //             duration,
    //             startPrice,
    //             nftContractAddress,
    //             tokenId
    //         );
    //     auctions.push(auction);
    //     // auctionMap[tokenId] = auction;

    //     auctionToCreator[nftContractAddress] = msg.sender;
    //     emit AuctionCreated(address(auction), tokenId);
    //     return address(auction);
    // }

    function updateImplementation(address _newImplementation) external onlyOwner {
        require(_newImplementation != address(0), "Invalid implementation address");
        address oldImplementation = auctionImplementation;
        auctionImplementation = _newImplementation;

        emit UpdateImplementation(oldImplementation, _newImplementation);
    }

    //获取所有拍卖合约
    function getAllAuctions() external view returns (address[] memory) {
        return allAuctions;
    }

    //升级合约权限
    function _authorizeUpgrade(address) internal override view {
        require(owner() == msg.sender, "Only owner can authorize upgrade");
    }
}