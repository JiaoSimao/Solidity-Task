const { getNamedAccounts, network } = require("hardhat")
const { developmentChains,networkConfig } = require("../helper-hardhat-config")


module.exports = async({getNamedAccounts, deployments}) => {
    const { firstAccount } = await getNamedAccounts()
    const { deploy, log } = deployments
    
    log("NFTPoolBurnAndMint deploying...")
    // address _router, address _link, address nftAddr
    let destChainRouter, linkTokenAddr
    if (developmentChains.includes(network.name)) {
        const ccipSimulatorDeploy = await deployments.get("CCIPLocalSimulator")
        const ccipSimulator = await ethers.getContractAt("CCIPLocalSimulator", ccipSimulatorDeploy.address)
        const ccipConfig = await ccipSimulator.configuration()

        destChainRouter = ccipConfig.destinationRouter_
        linkTokenAddr = ccipConfig.linkToken_
    } else {
        destChainRouter = networkConfig[network.config.chainId].router
        linkTokenAddr = networkConfig[network.config.chainId].linkToken
    }
    
    const wnftDeployment = await deployments.get("WrappedMyToken")
    const wnftAddr = wnftDeployment.address

    await deploy("NFTPoolBurnAndMint", {
        contract: "NFTPoolBurnAndMint",
        from: firstAccount,
        log: true,
        args: [destChainRouter, linkTokenAddr, wnftAddr]
    })

    log("NFTPoolBurnAndMint deployed succeddfully")
}

module.exports.tags = ["destchain", "all"]