const EchoXPoints = artifacts.require("EchoXPoints");
const MemeFactory = artifacts.require("MemeFactory");
const EchoXAggregator = artifacts.require("EchoXAggregator");

module.exports = async function(deployer, network, accounts) {
  const echoXNFTAddress = '0x2Cf53018BE3cd487172ce83ADEEa34eC7199a42d';
  const echoXTokenAddress = '0x8B057E7457A3c167a9a9D0c2D1787ffc5c9d04f8';
  
  console.log(`Using existing EchoXNFT at: ${echoXNFTAddress}`);
  console.log(`Using existing EchoXToken at: ${echoXTokenAddress}`);
  
  console.log("Deploying EchoXPoints contract...");
  await deployer.deploy(EchoXPoints);
  const echoXPointsInstance = await EchoXPoints.deployed();
  console.log(`EchoXPoints deployed to: ${echoXPointsInstance.address}`);
  
  console.log("Deploying MemeFactory contract...");
  await deployer.deploy(MemeFactory, echoXPointsInstance.address);
  const memeFactoryInstance = await MemeFactory.deployed();
  console.log(`MemeFactory deployed to: ${memeFactoryInstance.address}`);
  
  console.log("Deploying EchoXAggregator contract...");
  await deployer.deploy(EchoXAggregator, echoXPointsInstance.address);
  const echoXAggregatorInstance = await EchoXAggregator.deployed();
  console.log(`EchoXAggregator deployed to: ${echoXAggregatorInstance.address}`);
  
  console.log("Setting up permissions...");
  
  
  if (typeof echoXPointsInstance.authorizeContract === 'function') {
    try {
      await echoXPointsInstance.authorizeContract(memeFactoryInstance.address);
      console.log(`Authorized MemeFactory (${memeFactoryInstance.address}) to call EchoXPoints functions`);
      
      await echoXPointsInstance.authorizeContract(echoXAggregatorInstance.address);
      console.log(`Authorized EchoXAggregator (${echoXAggregatorInstance.address}) to call EchoXPoints functions`);
    } catch (error) {
      console.error("Error authorizing contracts:", error.message);
    }
  } else {
    console.log("Warning: authorizeContract function not found on EchoXPoints contract");
    console.log("Warning:");
  }
  
  console.log("Deployment complete!");
  console.log("Contract Addresses:");
  console.log(`- EchoXNFT: ${echoXNFTAddress}`);
  console.log(`- EchoXToken: ${echoXTokenAddress}`);
  console.log(`- EchoXPoints: ${echoXPointsInstance.address}`);
  console.log(`- MemeFactory: ${memeFactoryInstance.address}`);
  console.log(`- EchoXAggregator: ${echoXAggregatorInstance.address}`);
};
