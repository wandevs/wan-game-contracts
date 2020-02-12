var ConvertLib = artifacts.require("./ConvertLib.sol");
var Math = artifacts.require("./SafeMath.sol");
var RandomBeacon = artifacts.require("./RandomBeacon.sol");
var DefiGame =  artifacts.require("./DefiGame.sol");

module.exports = function(deployer,network, accounts) {
//    deployer.deploy(Math);
    deployer.deploy(RandomBeacon);
    deployer.link(RandomBeacon,DefiGame)
};
