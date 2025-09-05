const getNamedAccounts = require("hardhat")
module.exports =  async({getNamedAccounts, deployments}) => {
    const { firstAccount } = await getNamedAccounts()
    const { deploy, log } = deployments

    log("deploying nft contract")
    await deploy("MyToken", {
        contract: "MyToken",
        from: firstAccount,
        log: true,
        args: ["MyToken", "MT"]
    })
    log("nft contract deployed successfully")
}

module.exports.tags = ["sourcechain", "all"]