const getNamedAccounts = require("hardhat")
module.exports = async({getNamedAccounts, deployments}) => {
    const { firstAccount } = await getNamedAccounts()
    const { deploy, log } = deployments

    log("deploying wnft contract")
    await deploy("WrappedMyToken", {
        contract: "WrappedMyToken",
        from: firstAccount,
        log: true,
        args: ["WrappedMyToken", "WMT"]
    })
    log("wnft contract deployed successfully")
}

module.exports.tags = ["destchain", "all"]