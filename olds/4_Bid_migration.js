const Bid = artifacts.require("Bid");

module.exports = async function (deployer) {
  await deployer.deploy(Bid);

  const deployedBid = await Bid.deployed() ;

  console.log("Bid Address:", deployedBid.address);
};