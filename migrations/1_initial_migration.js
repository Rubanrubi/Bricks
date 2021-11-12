const Bricks = artifacts.require("Bricks");

module.exports = function (deployer) {
  deployer.deploy(Bricks);
};
