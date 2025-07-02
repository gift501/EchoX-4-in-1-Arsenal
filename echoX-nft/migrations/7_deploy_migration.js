const MemeFactory = artifacts.require("MemeFactory");
const PriceTracking = artifacts.require("PriceTracking");
const CommunityReactions = artifacts.require("CommunityReactions");

module.exports = async function (deployer, network, accounts) {
   
    const echoXPointsAddress = "0x368edDf08983d5EfB920CFC2B8957a49fE7ac5DF";
    console.log("Using EchoXPoints at:", echoXPointsAddress);

   
    console.log("\nDeploying MemeFactory with initial placeholders...");
    await deployer.deploy(
        MemeFactory,
        echoXPointsAddress,
        '0x0000000000000000000000000000000000000000', // Placeholder for PriceTracking
        '0x0000000000000000000000000000000000000000'  // Placeholder for CommunityReactions
    );
    const memeFactoryInstance = await MemeFactory.deployed();
    const memeFactoryAddress = memeFactoryInstance.address;
    console.log("MemeFactory deployed at:", memeFactoryAddress);

    
    console.log("\nDeploying PriceTracking with MemeFactory address:", memeFactoryAddress);
    await deployer.deploy(PriceTracking, memeFactoryAddress);
    const priceTrackingInstance = await PriceTracking.deployed();
    const priceTrackingAddress = priceTrackingInstance.address;
    console.log("PriceTracking deployed at:", priceTrackingAddress);

    
    console.log("\nDeploying CommunityReactions with MemeFactory address:", memeFactoryAddress);
    await deployer.deploy(CommunityReactions, memeFactoryAddress); // <--- Pass MemeFactory address here!
    const communityReactionsInstance = await CommunityReactions.deployed();
    const communityReactionsAddress = communityReactionsInstance.address;
    console.log("CommunityReactions deployed at:", communityReactionsAddress);

    console.log("\nUpdating MemeFactory with actual PriceTracking and CommunityReactions addresses...");
    await memeFactoryInstance.updatePriceTrackerContract(priceTrackingAddress);
    console.log("MemeFactory.priceTracker updated to:", await memeFactoryInstance.priceTracker());

    await memeFactoryInstance.updateCommunityReactionsContract(communityReactionsAddress);
    console.log("MemeFactory.communityReactions updated to:", await memeFactoryInstance.communityReactions());

    console.log("\nAll contracts deployed and linked successfully!");
};