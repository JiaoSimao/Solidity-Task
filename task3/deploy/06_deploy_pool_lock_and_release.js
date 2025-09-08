const { getNamedAccounts, network } = require("hardhat")
const { developmentChains,networkConfig } = require("../helper-hardhat-config")

module.exports = async({getNamedAccounts, deployments}) => {

    const { firstAccount } = await getNamedAccounts()
    const { deploy, log } = deployments
    
    log("HJNFTPoolLockAndRelease deploying...")
    let sourceChainRouter, linkTokenAddr
    if (developmentChains.includes(network.name)) {
        const ccipSimulatorDeploy = await deployments.get("CCIPLocalSimulator")
        const ccipSimulator = await ethers.getContractAt("CCIPLocalSimulator", ccipSimulatorDeploy.address)
        const ccipConfig = await ccipSimulator.configuration()

        sourceChainRouter = ccipConfig.sourceRouter_
        linkTokenAddr = ccipConfig.linkToken_
    } else {
        sourceChainRouter = networkConfig[network.config.chainId].router
        linkTokenAddr = networkConfig[network.config.chainId].linkToken
    }

    // address _router, address _link, address nftAddr
    const nftDeployment = await deployments.get("HJNFT")
    const nftAddr = nftDeployment.address

    await deploy("HJNFTPoolLockAndRelease", {
        contract: "HJNFTPoolLockAndRelease",
        from: firstAccount,
        log: true,
        args: [sourceChainRouter, linkTokenAddr, nftAddr]
    })

    log("NFTPoolLockAndRelease deployed succeddfully")
}

module.exports.tags = ["sourcechain", "all"]