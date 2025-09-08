const { getNamedAccounts, deployments, upgrades, ethers } = require("hardhat")
const fs = require("fs")
const path = require("path")
const { clear } = require("console")

module.exports =  async({getNamedAccounts, deployments}) => {
    const { firstAccount } = await getNamedAccounts()
    const { deploy, log } = deployments

    log("deploying HJ Auction V2 contract...")
    // 读取proxyHJTAuction.json文件，获取之前部署的代理合约地址和实现合约地址
    const storePath = path.resolve(__dirname, "../.cache/proxyHJTAuction.json")
    const proxyData = fs.readFileSync(storePath, "utf-8")
    const { proxyAddress, implAddress, abi } = JSON.parse(proxyData)


    //升级版的业务合约
    const HJAuctionV2 = await ethers.getContractFactory("HJAuctionV2")
    //通过代理合约升级
    const hjAuctionProxyV2 = await upgrades.upgradeProxy(proxyAddress, HJAuctionV2)
    await hjAuctionProxyV2.waitForDeployment()
    const proxyAddressV2 = await hjAuctionProxyV2.getAddress()
    log("HJ Auction V2 proxy address: " + proxyAddressV2)


    //验证升级是否成功
    const implAddressV2 = await upgrades.erc1967.getImplementationAddress(proxyAddressV2)
    log("HJ Auction V2 implementation address: " + implAddressV2)

    //将升级后的合约信息重新写入文件
    fs.writeFileSync(
        storePath,
        JSON.stringify({
            proxyAddress: proxyAddressV2,
            implAddress: implAddressV2,
            abi: HJAuctionV2.interface.format("json")
        })
    )

    //部署升级后的合约信息到链上
    const hjAuctionImplementation = await deploy("HJAuctionV2", {
        from: firstAccount,
        contract: "HJAuctionV2",
        abi: HJAuctionV2.interface.format("json"),
        address: proxyAddressV2,
        args: [],
        log: true
    })

    return hjAuctionImplementation
    // return hjAuctionImplementation --- IGNORE ---

}

module.exports.tags = ["HJAuctionV2", "all"]