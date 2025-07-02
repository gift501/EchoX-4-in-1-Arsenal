const ReferralSystem = artifacts.require("ReferralSystem");

module.exports = function (deployer) {
  deployer.deploy(ReferralSystem);
};
