const EchoXPoints = artifacts.require("EchoXPoints");
const MemeFactory = artifacts.require("MemeFactory");
const EchoXPool = artifacts.require("EchoXPool");
const EchoXAggregator = artifacts.require("EchoXAggregator");

module.exports = async function (deployer, network, accounts) {
   await deployer.deploy(EchoXPoints);
  const points = await EchoXPoints.deployed();
  console.log("✅ EchoXPoints deployed at:", points.address);

    await deployer.deploy(MemeFactory, points.address);
  const factory = await MemeFactory.deployed();
  console.log("✅ MemeFactory deployed at:", factory.address);

    const usdtAmount = web3.utils.toWei("100", "ether"); // 100 USDT
    console.log("ℹ️  Liquidity pool logic placeholder: 100 USDT + 500M meme");

    const ex = "0xBe21b5C467e7F6C35049a1E7b226b8E7189a9aae";
  const nft = "0x2Cf53018BE3cd487172ce83ADEEa34eC7199a42d";
  await deployer.deploy(EchoXPool, ex, points.address);

  const pool = await EchoXPool.deployed();
  console.log("✅ EchoXPool deployed at:", pool.address);

  console.log("\n🚀 Deployment Summary:");
  console.log("Points:", points.address);
  console.log("MemeFactory:", factory.address);
  console.log("EchoXPool:", pool.address);
  console.log("EchoXAggregator:", aggregator.address);
};
