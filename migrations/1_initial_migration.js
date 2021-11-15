const Bricks = artifacts.require("Bricks");

module.exports = function (deployer, network, accounts) {
  deployer.deploy(Bricks, "0xFD47B53abCc4e1819219F9694E44CfB62bBe6972", "0x8780963707dD6039A0d75cE938385D9E6B37eFa8");
};
