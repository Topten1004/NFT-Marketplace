const SOLSNFT = artifacts.require("SOLSNFT");

module.exports = async function (deployer) {
  await deployer.deploy(SOLSNFT);

  const deployedSOLSNFT = await SOLSNFT.deployed() ;

  console.log("SOLS NFT Address:", deployedSOLSNFT.address);
};