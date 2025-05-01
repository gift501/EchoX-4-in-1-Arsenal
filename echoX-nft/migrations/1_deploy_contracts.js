const EchoXCore = artifacts.require("EchoXCore");
const EchoXPool = artifacts.require("EchoXPool");
const EchoXPoints = artifacts.require("EchoXPoints");

module.exports = async function (deployer, network, accounts) {
  const nft = "0x09Df5DCcA5562c72c606309262927771E5092720";
  const ex = "0x2Aa9E3a1917162eF4FBE63d83Ae963BFa4665109";
  const poolName = "EchoX Genesis Pool";
  const creator = accounts[0];

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
    points.address
  );
};
