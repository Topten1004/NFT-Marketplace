const SOLSTOKEN = artifacts.require("SOLSTOKEN");

module.exports = async function (deployer) {
  await deployer.deploy(SOLSTOKEN);

  const deployedSOLSTOKEN = await SOLSTOKEN.deployed() ;

  console.log("SOLS Token Address:", deployedSOLSTOKEN.address);
};