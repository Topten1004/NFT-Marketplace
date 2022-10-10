const SOLSMarketplace = artifacts.require("SOLSMarketplace");
// const SOLSTOKEN = artifacts.require("SOLSTOKEN") ;
const SOLSNFT = artifacts.require("SOLSNFT") ;
// const Legendary = artifacts.require("Legendary") ;
// const Rare = artifacts.require("Rare") ;
// const Bid = artifacts.require("Bid") ;

module.exports = async function (deployer) {
  // await deployer.deploy(SOLSTOKEN);
  // await deployer.deploy(Legendary) ;
  // await deployer.deploy(Rare) ;
  // await deployer.deploy(Bid) ;
  await deployer.deploy(SOLSNFT) ;

  // const deployedSOLSTOKEN= await SOLSTOKEN.deployed() ;
  // const deployedLegendary = await Legendary.deployed() ;
  // const deployedRare= await Rare.deployed() ;
  // const deployedBid = await Bid.deployed() ;
  const deployedSOLSNFT = await SOLSNFT.deployed() ;

  await deployer.deploy(
    SOLSMarketplace, 
    // deployedSOLSTOKEN.address,
    // deployedLegendary.address, 
    // deployedRare.address, 
    // deployedBid.address,
    deployedSOLSNFT.address

  );

  const deployedSOLSMarketplace =  await SOLSMarketplace.deployed() ;

  const solsMarketplace_address = deployedSOLSMarketplace.address ;

  console.log("SOLS Marketplace Address:", solsMarketplace_address);
};