const { getNamedAccounts, deployments, upgrades, ethers } = require("hardhat")
const fs = require("fs")
const path = require("path")

module.exports =  async({getNamedAccounts, deployments}) => {
    const { firstAccount } = await getNamedAccounts()
    const { deploy, log } = deployments

    log("deploying HJ Auction contract...")
    const HJAuction = await ethers.getContractFactory("HJAuction")
    //通过代理合约部署
    const hjAuctionProxy = await upgrades.deployProxy(HJAuction, [], {initializer: 'initialize'})
    await hjAuctionProxy.waitForDeployment()
    
    //获取实现合约地址
    const proxyAddress = await hjAuctionProxy.getAddress()
    log("HJ Auction proxy address: " + proxyAddress)
    const implAddress = await upgrades.erc1967.getImplementationAddress(await hjAuctionProxy.getAddress())
    log("HJ Auction implementation address: " + implAddress)

    const storePath = path.resolve(__dirname, "../.cache/proxyHJTAuction.json")
    
    fs.writeFileSync(
        storePath,
        JSON.stringify({
            proxyAddress: proxyAddress,
            implAddress: implAddress,
            abi: HJAuction.interface.format("json")
        })
    )


    const hjAuctionImplementation = await deploy("HJAuction", {
        from: firstAccount,
        contract: "HJAuction",
        abi: HJAuction.interface.format("json"),
        address: proxyAddress,
        args: [],
        log: true
    })

    // const hjAuctionImplementation = await deploy("HJAuction", {
    //     from: firstAccount,
    //     contract: "HJAuction",
    //     args: [],
    //     log: true
    // })

    // log("HJ Auction deployed successfully")
    return hjAuctionImplementation
}

module.exports.tags = ["HJAuction", "all"]