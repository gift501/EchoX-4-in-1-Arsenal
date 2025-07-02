const EchoXCore = artifacts.require("EchoXCore");
const EchoXPool = artifacts.require("EchoXPool");
const EchoXPoints = artifacts.require("EchoXPoints");

module.exports = async function (deployer, network, accounts) {
  const nft = "0x2Cf53018BE3cd487172ce83ADEEa34eC7199a42d";
  const ex = "0xBe21b5C467e7F6C35049a1E7b226b8E7189a9aae";
  const poolName = "EchoX Genesis Pool";
  const creator = accounts[0];
  const nftPriceInEx = web3.utils.toWei("10", "ether"); // Example price (adjust as needed)

  await deployer.deploy(EchoXPoints);
  const points = await EchoXPoints.deployed();

  await deployer.deploy(EchoXCore, nft, ex, points.address);
  const core = await EchoXCore.deployed();

  await deployer.deploy(
    EchoXPool,
    creator,
    nft,
    ex,
    poolName,
    points.address,
    nftPriceInEx // Pass the price as the sixth argument
  );
};
