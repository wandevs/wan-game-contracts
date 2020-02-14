require('truffle-test-utils').init()
require('./constant.js')

////////////////////////////////////////////////////////////////////////////////////

let DefiGameInstance

let starTime = 0;
let calRoundNUmber = 0;

let cycleTime = 180;
let randomCycleTime = cycleTime*2
let startUpDownRoundNb;

let stake = web3.toWei(2);
let stopTimeInAdvance = 1;

let winnerNUmber = 2;

let feeRatio = 100;//already mul 1000,10%



////////////////////////////////////////////////////////////////////////////////////////
contract('', async ([owner]) => {


  it('[90000000] Deploy contracts', async () => {

    owner = OWNER_ADDRESS;
    // unlock accounts
    await web3.personal.unlockAccount(owner, 'wanglu', 99999);

    await web3.personal.unlockAccount(global.ACCOUNT1, 'wanglu', 99999);
    await web3.personal.unlockAccount(global.ACCOUNT2, 'wanglu', 99999);

    console.log(colors.green('[INFO] owner: ', owner));

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

      let nowTime = parseInt(Date.now()/1000);
      starTime = nowTime;
      startUpDownRoundNb = parseInt(nowTime/cycleTime);

      calRoundNUmber = parseInt(nowTime/cycleTime) - startUpDownRoundNb

      var ret = await DefiGameInstance.setUpDownLotteryTime(starTime,cycleTime,stopTimeInAdvance,{from:owner});


      let gotStarTime = await DefiGameInstance.gameStartTime();
      let gotCycleTime = await DefiGameInstance.upDownLotteryTimeCycle();
      let gotStopSpan = await DefiGameInstance.upDownLtrstopTimeSpanInAdvance();

      assert.equal(gotStarTime,starTime);
      assert.equal(gotCycleTime,cycleTime);
      assert.equal(gotStopSpan,stopTimeInAdvance);


    })


    it('[90000002] Set random game time,expect scucess', async () => {

        var ret = await DefiGameInstance.setRandomLotteryTime(randomCycleTime,{from:owner});
        let gotCycleTime = await DefiGameInstance.randomLotteryTimeCycle();
        assert.equal(gotCycleTime,randomCycleTime);

    })


    it('[90000003] Set winner number,expect scucess', async () => {

        var ret = await DefiGameInstance.setRandomWinnerNumber(winnerNUmber,{from:owner});
        let gotWinnerNUmber = await DefiGameInstance.winnerNum();
        assert.equal(gotWinnerNUmber,winnerNUmber);

        var ret = await DefiGameInstance.setFeeRatio(feeRatio,{from:owner});

        let gotFeeRatio = await DefiGameInstance.feeRatio();
        assert.equal(gotFeeRatio,feeRatio);
    })

    it('[90000004] Set first round open price,expect scucess', async () => {

        let nowTime = parseInt(Date.now()/1000);
        calRoundNUmber = parseInt(nowTime/cycleTime) - startUpDownRoundNb

        let wanToBtcOpenPrice = 3026;//SATOSHI
        //for open price,do not need put cycleNumber,just put it as 0
        var ret = await DefiGameInstance.setPriceIndex(wanToBtcOpenPrice,0,true,{from:owner,gas:4710000});
        //console.log(ret)
        sleep(10);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);
        console.log(calRoundNUmber)


        assert.equal(res[0].toNumber(),wanToBtcOpenPrice);

    })


    it('[90000005] first round stakein one,expect scucess', async () => {

        var ret = await DefiGameInstance.stakeIn(true,{from:global.ACCOUNT1,value:stake,gas:4710000});
        sleep(5);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        assert.equal(res[2].toNumber(),stake);

    })

    it('[90000006] first round stakein two,expect scucess', async () => {


        var ret = await DefiGameInstance.stakeIn(false,{from:global.ACCOUNT2,value:stake,gas:4710000});
        sleep(5);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        assert.equal(res[3].toNumber(),stake);
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


        let preAccountBalance1 = await web3.eth.getBalance(global.ACCOUNT1);
        console.log("prebalance=" + preAccountBalance1)
        var ret = await DefiGameInstance.upDownLotteryFanalize({from:owner,gas:4710000});
        //console.log(ret)

        sleep(5);

        let afterAccountBalance1 = await web3.eth.getBalance(global.ACCOUNT1);
        console.log("afterbalance=" + afterAccountBalance1)

        assert.equal(afterAccountBalance1-preAccountBalance1>0,true)

    })




    /////round 2//////////////////////////
    it('[90000104] Set second round open price,expect scucess', async () => {

        let nowTime = parseInt(Date.now()/1000);
        calRoundNUmber = parseInt(nowTime/cycleTime) - startUpDownRoundNb;
        console.log("second round number=" + calRoundNUmber);

        let wanToBtcOpenPrice = 3000;//SATOSHI
        //for open price,do not need put cycleNumber,just put it as 0
        var ret = await DefiGameInstance.setPriceIndex(wanToBtcOpenPrice,0,true,{from:owner,gas:4710000});
        //console.log(ret)
        sleep(10);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);
        console.log(calRoundNUmber)


        assert.equal(res[0].toNumber(),wanToBtcOpenPrice);

    })


    it('[90000105] second round stakein one,expect scucess', async () => {

        var ret = await DefiGameInstance.stakeIn(true,{from:global.ACCOUNT1,value:stake,gas:4710000});
        sleep(5);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        assert.equal(res[2].toNumber(),stake);

    })

    it('[90000106] second round stakein two,expect scucess', async () => {


        var ret = await DefiGameInstance.stakeIn(false,{from:global.ACCOUNT2,value:stake,gas:4710000});
        sleep(5);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        assert.equal(res[3].toNumber(),stake);
    })

    it('[90000107] second round set close price,expect scucess', async () => {
        let wanToBtcCLosePrice = 2050;//SATOSHI
        //for open price,do not need put cycleNumber,just put it as 0
        var ret = await DefiGameInstance.setPriceIndex(wanToBtcCLosePrice,calRoundNUmber,false,{from:owner,gas:global.GAS*10});
        sleep(5);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);
        console.log(res)


        assert.equal(res[1].toNumber(),wanToBtcCLosePrice);

    })

    it('[90000108] second round updownFanalize,expect scucess', async () => {

        let endTime = starTime + cycleTime*(calRoundNUmber + 1)

        wait(function(){let nowTime = parseInt(Date.now()/1000); return nowTime > endTime;});


        let preAccountBalance1 = await web3.eth.getBalance(global.ACCOUNT1);
        console.log("prebalance=" + preAccountBalance1)
        var ret = await DefiGameInstance.upDownLotteryFanalize({from:owner,gas:4710000});
        //console.log(ret)

        sleep(5);

        let afterAccountBalance1 = await web3.eth.getBalance(global.ACCOUNT1);
        console.log("afterbalance=" + afterAccountBalance1)

        assert.equal(afterAccountBalance1-preAccountBalance1>0,true)
    })

})



