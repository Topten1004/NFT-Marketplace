const NFTMarketplace = artifacts.require("NFTMarketplace");

module.exports = function (deployer) {
  deployer.deploy(NFTMarketplace);
};