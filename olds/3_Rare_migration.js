const Rare = artifacts.require("Rare");

module.exports = async function (deployer) {
  await deployer.deploy(Rare);

  const deployedRare = await Rare.deployed() ;

  console.log("Rare Address:", deployedRare.address);
};