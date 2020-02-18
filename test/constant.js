global.colors = require('colors/safe')
//const web3 = global.web3
//needed to change the ip address:port that will be used
//web3.setProvider(new web3.providers.HttpProvider('http://18.237.245.215:8888'));
web3.setProvider(new web3.providers.HttpProvider('http://localhost:8888'));
global.BigNumber = require('bignumber.js')

global.DefiGameSol = artifacts.require('./DefiGame.sol')
global.DefiGameABI = artifacts.require('./DefiGame.sol').abi
global.DefiGame = web3.eth.contract(DefiGameABI)


var setTime = new Date("2020-02-17T00:00:00Z");//utc time
global.GameStartTime = parseInt(setTime/1000);


global.GAS = 200000

global.BTCTOCONG = 100000000
global.OWNER_ADDRESS = '0x2d0e7c0813a51d3bd1d08246af2a8a7a57d8922e'

//global.OWNER_ADDRESS = '0xbf12c73ccc1f7f670bf80d0bba93fe5765df9fec';
global.ACCOUNT1 = '0x9da26fc2e1d6ad9fdd46138906b0104ae68a65d8';
global.ACCOUNT2 = '0x344c2d4d8b42204b0ab3061a85e0c50eeb2fa8da';
global.ACCOUNT3 = '0xb4e61d10344203de4530d4a99d55f32ad25580e9';

global.sleep = function sleep(numberMillis) {
    var now = new Date();
    var exitTime = now.getTime() + numberMillis;
    while (true) {
        now = new Date();
        if (now.getTime() > exitTime)
            return;
    }
}

global. wait = function (conditionFunc) {
    var loopLimit = 30;
    var loopTimes = 0;
    while (!conditionFunc()) {
        sleep(1000);
        loopTimes++;
        if(loopTimes%loopLimit==0){
           console.log("loops=" + loopTimes)
        }
    }
}