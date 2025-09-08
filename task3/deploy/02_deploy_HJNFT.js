const { getNamedAccounts, deployments } = require("hardhat")
module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { firstAccount } = await getNamedAccounts();

    log("Deploying HJNFT contract...");
    const hjnftImplementation = await deploy("HJNFT", {
        contract: "HJNFT",
        from: firstAccount,
        log: true,
        args: ["HJNFT", "HJT"]
    });
    log("HJNFT contract deployed successfully");
    return hjnftImplementation
};
module.exports.tags = ["HJNFT", "all"];