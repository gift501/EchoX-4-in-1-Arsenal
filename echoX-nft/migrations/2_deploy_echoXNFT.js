const EchoXNFT = artifacts.require("EchoXNFT");
const EchoXToken = artifacts.require("EchoXToken");

module.exports = async function (deployer) {
  await deployer.deploy(EchoXNFT);
  await deployer.deploy(EchoXToken);
};
