const EchoXToken = artifacts.require("EchoXToken");

module.exports = function (deployer) {
  deployer.deploy(EchoXToken);
};
