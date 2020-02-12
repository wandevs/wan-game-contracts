global.colors = require('colors/safe')
//const web3 = global.web3
//needed to change the ip address:port that will be used
web3.setProvider(new web3.providers.HttpProvider('http://18.237.245.215:8888'));
global.BigNumber = require('bignumber.js')

global.FinNexusSol = artifacts.require('./DefiGame.sol')
global.FinNexusABI = artifacts.require('./DefiGame.sol').abi
global.FinNexus = web3.eth.contract(FinNexusABI)




global.OWNER_ADDRESS = '0xf7a2681f8cf9661b6877de86034166422cd8c308'




global.MAX_OPEN_SOLD_PHASE2 = MAX_OPEN_SOLD_2.mul(ether).div(new BigNumber(DIVIDER));
global.MAX_EXCHANGE_MINT_PHASE2 =  new BigNumber(SECOND_OPEN_SALE_AMOUNT).mul(ether).sub(new BigNumber(MAX_OPEN_SOLD_PHASE2));

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