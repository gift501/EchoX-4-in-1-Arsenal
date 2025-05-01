const EchoXCore = artifacts.require("EchoXCore");
const EchoXPool = artifacts.require("EchoXPool");
const EchoXPoints = artifacts.require("EchoXPoints");
const EchoXInterfaces = artifacts.require("EchoXInterfaces")

module.exports = async function (deployer, network, accounts) {
  const nft = "0x236e3d84Cc94ED7167C8c14E41Dd9e2D7304718d";
  const ex = "0xe5a963eAd5Be9C3b05f0F21FE2214Bc492CeA24A";

  await deployer.deploy(EchoXPoints);
  const points = await EchoXPoints.deployed();

  await deployer.deploy(EchoXCore, nft, ex, points.address);
};
