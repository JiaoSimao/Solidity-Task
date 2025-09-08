const { getNamedAccounts,deployments } = require("hardhat")
module.exports = async({getNamedAccounts, deployments}) => {
    const { firstAccount } = await getNamedAccounts()
    const { deploy, log } = deployments

    log("deploying wnft contract")
    await deploy("WrappedHJNFT", {
        contract: "WrappedHJNFT",
        from: firstAccount,
        log: true,
        args: ["WrappedHJNFT", "WHJT"]
    })
    log("wnft contract deployed successfully")
}

module.exports.tags = ["destchain", "all"]