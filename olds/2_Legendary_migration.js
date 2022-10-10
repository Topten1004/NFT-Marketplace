const Legendary = artifacts.require("Legendary");

module.exports = async function (deployer) {
  await deployer.deploy(Legendary);

  const deployedLegendary = await Legendary.deployed() ;

  console.log("Legendary Address:", deployedLegendary.address);
};