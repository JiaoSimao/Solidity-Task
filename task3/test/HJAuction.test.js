const { ethers, getNamedAccounts, deployments } = require("hardhat")
const { expect } = require("chai")
const { time } = require("@nomicfoundation/hardhat-network-helpers")
const { DECIMAL, INITIAL_PRICE } = require("../helper-hardhat-config")

let singer, buyer, hjnft, hjAuction, hjnftAddress, hjAuctionAddress, mintTx, mockFeedAddress
    beforeEach(async function () {
        await deployments.fixture("all");
        [singer, buyer] = await ethers.getSigners();
        //部署NFT合约
        const hjnftFactroy = await ethers.getContractFactory("HJNFT");
        hjnft = await hjnftFactroy.deploy("HJNFT", "HJN");
        await hjnft.waitForDeployment();
        hjnftAddress = await hjnft.getAddress();
        console.log("HJNFT deployed to:", hjnftAddress);
        //先铸造NFT
        mintTx = await hjnft.connect(singer).safeMint(singer.address, "https://flexible-beige-felidae.myfilebase.com/ipfs/QmWz5kkiz9rPwVNHDMVubn35PwRzHYvEWjGMsA1ExBtGkm")
        await mintTx.wait()
        console.log("tx to is :", mintTx.to);
        //部署拍卖合约
        const hjAuctionFactory = await ethers.getContractFactory("HJAuction");
        hjAuction = await hjAuctionFactory.deploy();
        await hjAuction.waitForDeployment();
        hjAuctionAddress = await hjAuction.getAddress();
        console.log("HJAuction deployed to:", hjAuctionAddress);
        // 关键步骤：授权拍卖合约操作NFT
        await hjnft.connect(singer).approve(hjAuctionAddress, 0);
        console.log("已授权拍卖合约操作NFT");
        // 部署模拟价格预言机合约，获取价格预言机地址,并为合约设置价格预言
        const mockPriceFeed = await deployments.get("MockV3Aggregator")
        mockFeedAddress = mockPriceFeed.address;
        console.log("模拟价格预言机合约地址:", mockFeedAddress);
        await hjAuction.setPriceETHFeed(mockFeedAddress, ethers.ZeroAddress)
    })


describe("test create auction", function () {
    
    it("测试创建合约-持续时间必须大于0", async function () {
        //创建拍卖
        await expect(hjAuction.createAuction(0, 200, hjnftAddress, 0, ethers.ZeroAddress))
        .to.be.revertedWith("Duration must be greater than 0")
    })

    it("测试创建合约-起始价格必须大于0", async function () {
        //创建拍卖
        await expect( hjAuction.createAuction(10*60, 0, hjnftAddress, 0, ethers.ZeroAddress))
        .to.be.revertedWith("Start price must be greater than 0")
    })

    it("测试创建合约-正常创建", async function () {
        //创建拍卖
        const tx = await hjAuction.createAuction(2*60*60, 200, hjnftAddress, 0, ethers.ZeroAddress)
        await tx.wait()
        console.log("create auction tx to is :", tx.to);

        //获取拍卖合约
        const auction = await hjAuction.auctions(0)
        expect(auction.seller).to.equal(singer.address)
        expect(auction.nftContract).to.equal(hjnftAddress)
        expect(auction.tokenId).to.equal(0)
        expect(auction.startPrice).to.equal(200)
        expect(auction.highestBid).to.equal(0)
        expect(auction.highestBidder).to.equal(ethers.ZeroAddress)
        expect(auction.ended).to.equal(false)
    })

    
})

describe("test place bid", function () {
    it("测试出价-合约id不存在", async function () {
        //创建拍卖
        const tx = await hjAuction.createAuction(2*60*60, 200, hjnftAddress, 0, ethers.ZeroAddress)
        await tx.wait()
        console.log("create auction tx to is :", tx.to);
        //出价
        await expect(hjAuction.connect(buyer).placeBid(1, ethers.parseEther("0.01"), ethers.ZeroAddress))
        .to.be.revertedWith("Auction does not exist")
    })

    it("测试出价-拍卖已结束", async function () {
        //创建拍卖
        const tx = await hjAuction.createAuction(60, 200, hjnftAddress, 0, ethers.ZeroAddress)
        await tx.wait()
        console.log("create auction tx to is :", tx.to);
        //等待拍卖结束
        await time.increase(61)
        await time.latestBlock();
        
        //出价
        await expect(hjAuction.connect(buyer).placeBid(0, ethers.parseEther("0.01"), ethers.ZeroAddress))
        .to.be.revertedWith("Auction has ended")
    })

    it("测试出价-tokenaddress", async function() {
        //创建拍卖
        const tx = await hjAuction.createAuction(60, 200, hjnftAddress, 0, ethers.ZeroAddress)
        await tx.wait()
        console.log("create auction tx to is :", tx.to);
        //出价,tokenaddress不匹配
        await expect(hjAuction.connect(buyer).placeBid(0, ethers.parseEther("0.01"), buyer.address))
        .to.be.revertedWith("token type dont match")
    })

    it("测试出价-正常出价", async function () {
        //创建拍卖
        const tx = await hjAuction.createAuction(60, ethers.parseEther("0.01"), hjnftAddress, 0, ethers.ZeroAddress)
        await tx.wait()
        console.log("create auction tx to is :", tx.to);
        //设置价格预言机
        await hjAuction.setPriceETHFeed(mockFeedAddress, ethers.ZeroAddress)
        //出价
        await expect(
            hjAuction.connect(buyer).placeBid(0, ethers.parseEther("0.2"), ethers.ZeroAddress, {
            value: ethers.parseEther("0.2")
            })
        ).to.not.be.reverted;
        // 验证拍卖状态
        const auctionInfo = await hjAuction.auctions(0);
        expect(auctionInfo.highestBidder).to.equal(buyer.address);
        expect(auctionInfo.highestBid).to.equal(ethers.parseEther("0.2"));
    })

    it("测试出价-正常出价小于起始价格", async function () {
        //创建拍卖
        const tx = await hjAuction.createAuction(60, ethers.parseEther("0.01"), hjnftAddress, 0, ethers.ZeroAddress)
        await tx.wait()
        console.log("create auction tx to is :", tx.to);
        //出价
        await expect(
            hjAuction.connect(buyer).placeBid(0, ethers.parseEther("0.001"), ethers.ZeroAddress, {
            value: ethers.parseEther("0.001")
            })
        ).to.be.revertedWith("Bid amount must greather than start price");
    })
})

describe("test end auction", function () {
    it("测试结束拍卖-合约id不存在", async function () {
        //创建拍卖
        const tx = await hjAuction.createAuction(60, ethers.parseEther("0.01"), hjnftAddress, 0, ethers.ZeroAddress)
        await tx.wait()
        console.log("create auction tx to is :", tx.to);
        //结束拍卖
        await expect(hjAuction.endAuction(1)).to.be.revertedWith("Auction does not exist")
    })
    it("测试结束拍卖-拍卖未结束", async function () {
        //创建拍卖
        const tx = await hjAuction.createAuction(60, ethers.parseEther("0.01"), hjnftAddress, 0, ethers.ZeroAddress)
        await tx.wait()
        console.log("create auction tx to is :", tx.to);
        //结束拍卖
        await expect(hjAuction.endAuction(0)).to.be.revertedWith("Auction has not ended or does not exist")
    })
})