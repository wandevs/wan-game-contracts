global.colors = require('colors/safe')
//const web3 = global.web3
//needed to change the ip address:port that will be used
web3.setProvider(new web3.providers.HttpProvider('http://192.168.1.58:18545'));
global.BigNumber = require('bignumber.js')

global.FinNexusSol = artifacts.require('./FinNexusContribution.sol')
global.FinNexusABI = artifacts.require('./FinNexusContribution.sol').abi
global.FinNexus = web3.eth.contract(FinNexusABI)

global.CfncTokenSol = artifacts.require('./CfncToken.sol')
global.CfncTokenABI = artifacts.require('./CfncToken.sol').abi
global.CfncToken = web3.eth.contract(CfncTokenABI)

global.UM1SABI = artifacts.require('./UM1SToken.sol').abi
global.UM1SToken = web3.eth.contract(UM1SABI)


global.OWNER_ADDRESS = '0xf7a2681f8cf9661b6877de86034166422cd8c308'
// ERC20 compliant token addresses
global.WALLET_ADDRESS = '0xf851b2edae9d24876ed7645062331622e4f18a05'


global.DEV_TEAM_HOLDER = '0x8ce3708fdbe05a75135e5923e8acc36d22d18033'
global.FOUNDATION_HOLDER = '0x414810cd259e89a63c6fb10326cfa00952fb4785'
global.DYNAMIC_HOLDER = '0xb957c97b508a10851724d7b68698f88803338ced'

global.USER1_ADDRESS = '0xf48ca621440226f0e98d73f9538404e573930864';
global.USER2_ADDRESS = '0xf09ad5c6fe391a420d45397b50fefe5d7fe81ea9';
global.EXCHANGE1_ADDRESS = '0x3449fc52745be7235cb89ad23df4c73a811f5811';
global.EXCHANGE2_ADDRESS = '0xabbba0a37c3164285c615becf233936c7248440e';

global.emptyAddress = '0x0000000000000000000000000000000000000000';

global.FIRST_OPEN_SALE_AMOUNT = 80000000 ;
global.SECOND_OPEN_SALE_AMOUNT = 70000000 ;



//supposed 1 usdt = 5 wan
//         1 usdt = 10 cfunc
//         1 wan = 2 cfunc

global.PHASE1 = 1
global.PHASE1_WanRatioOfSold = 100 //10%,  it is mul 1000
global.PHASE1_Wan2CfncRate = 2100 //2.1,  it is mul 1000
global.PHASE1_Cfnc2UM1SRatio = 800 //80%,  it is mul 1000

global.PHASE2 = 2
global.PHASE2_WanRatioOfSold = 100 //10%,  it is mul 1000
global.PHASE2_Wan2CfncRate = 2100 //2.1,  it is mul 1000
global.PHASE2_Cfnc2UM1SRatio = 800 //80%,  it is mul 1000

global.DIVIDER = 1000

global.TIME_INTERVAL = 300 //300 seconds,5 minutes

global.WAN_CONTRIBUTE_AMOUNT = 10.1 //10.1 WAN

global.ether = new BigNumber(Math.pow(10, 18));

global.GasPrice = 180000000000


let MAX_OPEN_SOLD_1 =  new BigNumber(FIRST_OPEN_SALE_AMOUNT).mul(new BigNumber(PHASE1_WanRatioOfSold));
global.MAX_OPEN_SOLD = MAX_OPEN_SOLD_1.mul(ether).div(new BigNumber(DIVIDER));
global.MAX_EXCHANGE_MINT =  new BigNumber(FIRST_OPEN_SALE_AMOUNT).mul(ether).sub(new BigNumber(MAX_OPEN_SOLD));


let MAX_OPEN_SOLD_2 =  new BigNumber(SECOND_OPEN_SALE_AMOUNT).mul(new BigNumber(PHASE2_WanRatioOfSold));
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