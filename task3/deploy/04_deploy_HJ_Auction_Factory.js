const { getNamedAccounts, deployments, upgrades, ethers } = require("hardhat")

module.exports =  async({getNamedAccounts, deployments}) => {
    const { deploy, log } = deployments;
    const { firstAccount } = await getNamedAccounts();


    //获取部署的拍卖合约地址
    const auctionImplementation = (await deployments.get("HJAuction")).address;
    log("HJ Auction implementation address: " + auctionImplementation);
    //获取部署的拍卖工厂合约地址
    // const auctionFactory = (await deployments.get("HJAuctionFactory")).address;
    // log("HJ Auction Factory implementation address: " + auctionFactory);



    log("Deploying HJAuctionFactory contract...");
    await deploy("HJAuctionFactoryProxy", {
        contract: "HJAuctionFactory",
        from: firstAccount,
        log: true,
        args: [],
        proxy: {
            proxyContract: "OpenZeppelinTransparentProxy",
            execute: {
                init: {
                    methodName: "initialize",
                    args: [auctionImplementation, firstAccount],
                },
            },
        },
    });
    log("HJNFT contract deployed successfully");
}

module.exports.tags = ["HJAuctionFactoryProxy", "all"]