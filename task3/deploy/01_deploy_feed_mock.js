const getNamedAccounts = require("hardhat")
const { developmentChains, DECIMAL, INITIAL_PRICE } = require("../helper-hardhat-config")

module.exports = async ({ getNamedAccounts, deployments }) => {
    if (developmentChains.includes(network.name)) {
        const { firstAccount } = await getNamedAccounts()
        const { deploy } = deployments
        await deploy("MockV3Aggregator", {
            from: firstAccount,
            log: true,
            args: [DECIMAL, INITIAL_PRICE]  
        })
    }else {
        console.log("skipping feed mock deployment")
    }
}

module.exports.tags = ["all", "mock"]