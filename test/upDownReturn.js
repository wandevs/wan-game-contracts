require('truffle-test-utils').init()
require('./constant.js')

////////////////////////////////////////////////////////////////////////////////////

let DefiGameInstance
let DefiGameInstanceAddress

let starTime = 0;
let calRoundNUmber = 0;

let cycleTime = 160;
let randomCycleTime = cycleTime*2
let startUpDownRoundNb;
let startRandomRoundNb;

let stake = web3.toWei(1);
let stopTimeInAdvance = 1;

let winnerNUmber = 2;

let feeRatio = 100;//already mul 1000,10%



////////////////////////////////////////////////////////////////////////////////////////
contract('', async ([owner]) => {


    it('[90000000] Deploy contracts', async () => {

        owner = global.OWNER_ADDRESS;

        console.log(colors.green('[INFO] owner: ', owner));
        // unlock accounts
        //await web3.personal.unlockAccount(owner, 'wanglu', 99999);

        //await web3.personal.unlockAccount(global.ACCOUNT1, 'wanglu', 99999);
        //await web3.personal.unlockAccount(global.ACCOUNT2, 'wanglu', 99999);
        //await web3.personal.unlockAccount(global.ACCOUNT3, 'wanglu', 99999);



        // deploy token manager
        DefiGameInstance = await DefiGameSol.new({from: owner});

        DefiGameInstanceAddress = DefiGameInstance.address;

        console.log(colors.green('[INFO] DefiGameInstanceAddress address:', DefiGameInstanceAddress));

        // let res = await DefiGameInstance.testRandomStakerfind();
        // console.log("half find test res=" + res);
        //
        // res = await DefiGameInstance.testGetRandomByBlockTime();
        // console.log("random numer res=" + res);


    })



    it('[90000001] Set updown game Sart time,expect scucess', async () => {


        nowTime = parseInt(Date.now()/ 1000);

        startRandomRoundNb = parseInt(nowTime/randomCycleTime);

        starTime = parseInt((startRandomRoundNb + 1)*randomCycleTime);

        startUpDownRoundNb = parseInt(starTime/cycleTime);

        calRoundNUmber = 0;

        var ret = await DefiGameInstance.setLotteryTime(starTime,cycleTime,stopTimeInAdvance,randomCycleTime,{from:owner});

        //console.log(ret);
        sleep(100);

        let gotStarTime = await DefiGameInstance.gameStartTime();
        console.log("got start time=" + gotStarTime)

        let gotCycleTime = await DefiGameInstance.upDownLotteryTimeCycle();
        console.log("gotCycleTime=" + gotCycleTime)

        let gotStopSpan = await DefiGameInstance.upDownLtrstopTimeSpanInAdvance();
        console.log("gotStopSpan=" + gotStopSpan)

        console.log("start time=" + nowTime)


        assert.equal(gotStarTime.toNumber(),starTime);
        assert.equal(gotCycleTime.toNumber(),cycleTime);
        assert.equal(gotStopSpan.toNumber(),stopTimeInAdvance);

        let gotRandomCycleTime = await DefiGameInstance.randomLotteryTimeCycle();
        assert.equal(gotRandomCycleTime.toNumber(),randomCycleTime);

        wait(function(){let nowTime = parseInt(Date.now()/1000); return nowTime > starTime + 10;});


    })



    it('[90000003] Set winner number,expect scucess', async () => {

        var ret = await DefiGameInstance.setRandomWinnerNumber(winnerNUmber,{from:owner});
        let gotWinnerNUmber = await DefiGameInstance.winnerNum();
        assert.equal(gotWinnerNUmber,winnerNUmber);

        var ret = await DefiGameInstance.setFeeRatio(feeRatio,{from:owner});

        let gotFeeRatio = await DefiGameInstance.feeRatio();
        assert.equal(gotFeeRatio,feeRatio);
    })


    ///////////////////////////////////////first round//////////////////////////////////

    it('[90000004] Set first round open price,expect scucess', async () => {


        console.log(calRoundNUmber)
        let wanToBtcOpenPrice = 2020;//SATOSHI
        //for open price,do not need put cycleNumber,just put it as 0
        var ret = await DefiGameInstance.setPriceIndex(wanToBtcOpenPrice,0,true,{from:owner,gas:4710000});
        console.log(ret)
        sleep(100);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(calRoundNUmber);
        assert.equal(res[0].toNumber(),wanToBtcOpenPrice);

    })


    it('[90000005] first round stakein one,expect scucess', async () => {

        let startTime = starTime + cycleTime*(calRoundNUmber);
        wait(function(){let nowTime = parseInt(Date.now()/1000); return nowTime > startTime;});

        var ret = await DefiGameInstance.stakeIn(true,{from:global.ACCOUNT3,value:stake,gas:4710000});
        sleep(5);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        //   assert.equal(res[2].toNumber(),stake);

    })



    it('[90000007] first round set close price,expect scucess', async () => {
        let wanToBtcCLosePrice = 3050;//SATOSHI
        //for open price,do not need put cycleNumber,just put it as 0
        var ret = await DefiGameInstance.setPriceIndex(wanToBtcCLosePrice,calRoundNUmber,false,{from:owner,gas:global.GAS*10});
        sleep(5);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);
        console.log(res)


        assert.equal(res[1].toNumber(),wanToBtcCLosePrice);

    })


    it('[90000008] first round updownFanalize,expect scucess', async () => {

        let endTime = starTime + cycleTime*(calRoundNUmber + 1)

        wait(function(){let nowTime = parseInt(Date.now()/1000); return nowTime > endTime;});


        let preAccountBalance3 = await web3.fromWei(web3.eth.getBalance(global.ACCOUNT3));
        console.log("prebalance=" + preAccountBalance3)

        var ret = await DefiGameInstance.upDownLotteryFanalize({from:owner,gas:4710000});
        console.log(ret)

        console.log(ret.logs[0].args)

        sleep(10);

        let afterAccountBalance3 = await web3.fromWei(web3.eth.getBalance(global.ACCOUNT3));
        console.log("afterbalance=" +  afterAccountBalance3)

        diff = afterAccountBalance3-preAccountBalance3
        console.log("diff="+diff);

        assert.equal(diff>0&&diff>0.8,true)

    })



    ///////////////////////////////////////second round//////////////////////////////////

    it('[90000104] Set first round open price,expect scucess', async () => {

        calRoundNUmber = 1;
        console.log(calRoundNUmber)
        let t = starTime + cycleTime*(calRoundNUmber);
        wait(function(){let nowTime = parseInt(Date.now()/1000); return nowTime > t;});



        let wanToBtcOpenPrice = 2020;//SATOSHI
        //for open price,do not need put cycleNumber,just put it as 0
        var ret = await DefiGameInstance.setPriceIndex(wanToBtcOpenPrice,0,true,{from:owner,gas:4710000});
        console.log(ret)
        sleep(100);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(calRoundNUmber);
        assert.equal(res[0].toNumber(),wanToBtcOpenPrice);

    })


    it('[90000105] first round stakein one,expect scucess', async () => {

        let startTime = starTime + cycleTime*(calRoundNUmber);
        wait(function(){let nowTime = parseInt(Date.now()/1000); return nowTime > startTime;});

        var ret = await DefiGameInstance.stakeIn(false,{from:global.ACCOUNT3,value:stake,gas:4710000});
        sleep(5);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        //   assert.equal(res[2].toNumber(),stake);

    })



    it('[90000107] first round set close price,expect scucess', async () => {
        let wanToBtcCLosePrice = 3050;//SATOSHI
        //for open price,do not need put cycleNumber,just put it as 0
        var ret = await DefiGameInstance.setPriceIndex(wanToBtcCLosePrice,calRoundNUmber,false,{from:owner,gas:global.GAS*10});
        sleep(5);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);
        console.log(res)


        assert.equal(res[1].toNumber(),wanToBtcCLosePrice);

    })


    it('[90000108] first round updownFanalize,expect scucess', async () => {

        let endTime = starTime + cycleTime*(calRoundNUmber + 1)

        wait(function(){let nowTime = parseInt(Date.now()/1000); return nowTime > endTime;});


        let preAccountBalance3 = await web3.fromWei(web3.eth.getBalance(global.ACCOUNT3));
        console.log("prebalance=" + preAccountBalance3)

        var ret = await DefiGameInstance.upDownLotteryFanalize({from:owner,gas:4710000});
        console.log(ret)

        for(i=0;i<ret.logs.length;i++) {
            console.log(ret.logs[i].args)
        }

        sleep(10);

        let afterAccountBalance3 = await web3.fromWei(web3.eth.getBalance(global.ACCOUNT3));
        console.log("afterbalance=" +  afterAccountBalance3)

        diff = afterAccountBalance3-preAccountBalance3
        console.log("diff="+diff);

        assert.equal(diff>0&&diff>0.8,true)

    })


})



