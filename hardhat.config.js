require("@nomiclabs/hardhat-waffle");
require("hardhat-deploy");
// require("@nomiclabs/hardhat-etherscan");
// require("solidity-coverage");
// require("hardhat-gas-reported");
// require("dotenv").config();

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.7",
  namedAccounts: {
    deployer: {
      default: 0, //ethers built in accounts at index 0
    }
  }
};