const Migrations = artifacts.require("Andromeda");

module.exports = function (deployer) {
  deployer.deploy(Migrations,1000000,10);
};
