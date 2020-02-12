global.colors = require('colors/safe')
//const web3 = global.web3
//needed to change the ip address:port that will be used
web3.setProvider(new web3.providers.HttpProvider('http://18.237.245.215:8888'));
global.BigNumber = require('bignumber.js')

global.DefiGameSol = artifacts.require('./DefiGame.sol')
global.DefiGameABI = artifacts.require('./DefiGame.sol').abi
global.DefiGame = web3.eth.contract(DefiGameABI)




//global.OWNER_ADDRESS = '0xf7a2681f8cf9661b6877de86034166422cd8c308'

global.OWNER_ADDRESS = '0xbf12c73ccc1f7f670bf80d0bba93fe5765df9fec'



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
    var loopLimit = 100;
    var loopTimes = 0;
    while (!conditionFunc()) {
        sleep(1000);
        loopTimes++;
        if(loopTimes>=loopLimit){
            throw Error("wait timeout! conditionFunc:" + conditionFunc)
        }
    }
}