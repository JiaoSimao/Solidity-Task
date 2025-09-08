require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");
require("hardhat-deploy");
require("hardhat-deploy-ethers");
require("@chainlink/env-enc").config();
require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-network-helpers")

const { SEPOLIA_RPC_URL, AMOY_RPC_URL, PRIVATE_KEY } = process.env;
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  namedAccounts: {
    firstAccount: {
      default: 0, // 默认情况下，使用第一个账户作为部署者
    },
    singer: {
      default: 1,
    },
    buyer: {
      default: 2,
    },
  },
  networks: {
    sepolia: {
      url: SEPOLIA_RPC_URL || "",
      accounts: [PRIVATE_KEY],
      chainId: 11155111,
      blocakConfirmations: 6
    },
    amoy: {
      url: AMOY_RPC_URL || "",
      accounts: [PRIVATE_KEY],
      chainId: 80002,
      blocakConfirmations: 6
    }
  },
  mocha: {
    timeout: 5000000, // 5000秒
  },
};
