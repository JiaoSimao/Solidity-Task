// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract HJAuction is Initializable, UUPSUpgradeable{
    //拍卖结构体
    struct Auction {
        // 拍卖持续时间
        uint256 duration;
        // 起始价格     
        uint256 startPrice;
        // 开始时间
        uint256 startTime;
        // 最高出价      
        uint256 highestBid;
        // NFT合约id     
        uint256 tokenId;
        // 卖家        
        address seller;
        // 最高出价者        
        address highestBidder;
        // NFT合约地址  
        address nftContract;
        // 参与竞价的资产类型 0:ETH 1:ERC20    
        address tokenAddress;
        // 是否结束   
        bool ended;             
    }

    mapping(uint256 => Auction) public auctions; // 拍卖映射
    uint256 public nextAuctionId;               // 下一个拍卖ID
    address public admin;                       // 管理员地址

    //预言机地址映射
    mapping(address => AggregatorV3Interface) public priceFeeds;
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    //事件
    event AuctionEnded(uint256 auctionId, address winner, uint256 amount);
    event PlaceBid(uint256 auctionId, address bidder, uint256 amount);

    function initialize() initializer public  {
        admin = msg.sender;
    }

    //设置价格预言机
    function setPriceETHFeed(address _priceETHFeed, address tokenAddress) public {
        priceFeeds[tokenAddress] = AggregatorV3Interface(_priceETHFeed);
    }

    //获取最新价格
    function getChainlinkDataFeedLatestAnswer(uint256 amount, address tokenAddress) public view returns (uint256) {
        AggregatorV3Interface priceFeed = priceFeeds[tokenAddress];
        // prettier-ignore
        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        
        uint256 decimals = priceFeed.decimals();

        return (amount * uint256(answer)) / (10 ** decimals);
    }

    
    //创建拍卖
    function createAuction(
        uint256 duration,
        uint256 startPrice,
        address nftContract,
        uint256 tokenId,
        address tokenAddress
    ) external {
        //检查参数
        require(duration > 0, "Duration must be greater than 0");
        require(startPrice > 0, "Start price must be greater than 0");

        IERC721(nftContract).safeTransferFrom(msg.sender, address(this), tokenId);

        auctions[nextAuctionId] = Auction({
            seller: msg.sender,
            duration: duration,
            startPrice: startPrice,
            startTime: block.timestamp,
            ended: false,
            highestBidder: address(0),
            highestBid: 0,
            nftContract: nftContract,
            tokenId: tokenId,
            tokenAddress: tokenAddress
        });
        nextAuctionId++;
    }

    //竞拍
    function placeBid(uint256 auctionId, uint256 bidAmount, address tokenAddress) external payable {
        //检查拍卖是否存在
        Auction storage auction = auctions[auctionId];
        require(auctionId < nextAuctionId, "Auction does not exist");
        require(!auction.ended && auction.duration + auction.startTime > block.timestamp, "Auction has ended"); 
        require(tokenAddress == auction.tokenAddress, "token type dont match");

        //检查出价是否高于最高价
        uint256 payAmount = bidAmount;
        if (tokenAddress != address(0)) {
            //ERC20竞拍
            //计算价格
            require(msg.value == 0, "ETH not accepted for ERC20 auction");
        } else {
            //ETH竞拍
            payAmount = msg.value;
        }
        uint256 bidValueUSD = getChainlinkDataFeedLatestAnswer(payAmount, tokenAddress);
        uint256 startPriceValue = getChainlinkDataFeedLatestAnswer(auction.startPrice, auction.tokenAddress);
        uint256 highestBidValue = getChainlinkDataFeedLatestAnswer(auction.highestBid, auction.tokenAddress);
        require(bidValueUSD >= startPriceValue, "Bid amount must greather than start price");  
        require (bidValueUSD > highestBidValue, "Bid amount must greather than high price");

        //如果是ERC20竞拍，转移代币
        if (tokenAddress != address(0)) {
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), bidAmount);
        }
        if (auction.tokenAddress != address(0)) {
            //退还之前最高出价者的ERC20代币
            IERC20(auction.tokenAddress).transfer(auction.highestBidder, auction.highestBid);
        } else {
            //退还之前最高出价者的ETH
            payable(auction.highestBidder).transfer(auction.highestBid);
        }
        //更新最高出价者和最高出价
        auction.highestBidder = msg.sender;
        auction.highestBid = bidAmount;
        auction.tokenAddress = tokenAddress;
        //记录事件
        emit PlaceBid(auctionId, msg.sender, bidAmount);

    }

    //结束拍卖
    function endAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        //检查拍卖是否存在
        require(auctionId < nextAuctionId, "Auction does not exist");
        require(!auction.ended && auction.duration + auction.startTime <= block.timestamp, "Auction has not ended or does not exist");
        auction.ended = true;

        //如果有出价，转移NFT给最高出价者，转移资金给卖家
        if (auction.highestBidder != address(0)) {
            //转移NFT给最高出价者
            IERC721(auction.nftContract).safeTransferFrom(address(this), auction.highestBidder, auction.tokenId);
            //转移资金给卖家
            if (auction.tokenAddress != address(0)) {
                //ERC20竞拍
                IERC20(auction.tokenAddress).transfer(auction.seller, auction.highestBid);
            } else {
                //ETH竞拍
                payable(auction.seller).transfer(auction.highestBid);
            }
        } else {
            //无人出价，退还NFT给卖家
            IERC721(auction.nftContract).safeTransferFrom(address(this), auction.seller, auction.tokenId);
        }
        emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
    }

    //根据 ERC721 协议规范，当一个合约要接收 NFT 时，接收方合约必须实现 onERC721Received 函数，避免NFT被误转入不支持接收的合约而永久锁定。
    event NftERC721Received(address operator ,address from,uint256 tokenId,bytes data);
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        emit NftERC721Received(operator,from,tokenId,data);
        return this.onERC721Received.selector;
    }

    //升级合约权限
    function _authorizeUpgrade(address) internal override view {
        //只有管理员可以升级合约
        require(msg.sender == admin, "Only admin can upgrade contract");
    }
}
