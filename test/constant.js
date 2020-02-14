global.colors = require('colors/safe')
//const web3 = global.web3
//needed to change the ip address:port that will be used
web3.setProvider(new web3.providers.HttpProvider('http://18.237.245.215:8888'));
global.BigNumber = require('bignumber.js')

global.DefiGameSol = artifacts.require('./DefiGame.sol')
global.DefiGameABI = artifacts.require('./DefiGame.sol').abi
global.DefiGame = web3.eth.contract(DefiGameABI)


var setTime = new Date("2020-02-17T00:00:00Z");//utc time
global.GameStartTime = parseInt(setTime/1000);


global.GAS = 200000

global.BTCTOCONG = 100000000
//global.OWNER_ADDRESS = '0xf7a2681f8cf9661b6877de86034166422cd8c308'

global.OWNER_ADDRESS = '0xbf12c73ccc1f7f670bf80d0bba93fe5765df9fec';

global.ACCOUNT1 = '0x255422e9e0451b09260bf6e00bc01cc852257504';
global.ACCOUNT2 = '0xd05d6d8910c8367e3e882fdb3662bb4419f15454';
global.ACCOUNT3 = '0xb0572b405f5c84a21d49f57ab26989adab1c5273';

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
        if(loopTimes%loopLimit==0){
           console.log("loops=" + loopTimes)
        }
    }
}