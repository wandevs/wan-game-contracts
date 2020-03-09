require('truffle-test-utils').init()
require('./constant.js')

////////////////////////////////////////////////////////////////////////////////////

let DefiGameInstance
let DefiGameInstanceAddress

let starTime = 0;
let calRoundNUmber = 0;

let cycleTime = 160;
let randomCycleTime = cycleTime*2

//let startUpDownRoundNb;
//let startRandomRoundNb;

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

      //startRandomRoundNb = parseInt(nowTime/randomCycleTime);

      starTime = nowTime;//parseInt((startRandomRoundNb + 1)*randomCycleTime);

     // startUpDownRoundNb = parseInt(starTime/cycleTime);

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

        var ret = await DefiGameInstance.setOperator(owner,{from:owner});
        sleep(100)
        let operator =  await DefiGameInstance.operator();
        assert.equal(operator,owner);

    })


    it('[91000003] Set Extra Prize from random round 0 - 3,expect scucess', async () => {

        var ret = await DefiGameInstance.inputExtraPrize(0,3,{from:owner,value:web3.toWei(9),gas:4710000});
        console.log(ret);
        sleep(100);

        let round0Prize = await DefiGameInstance.extraPrizeMap(0);
        console.log(round0Prize)
        assert.equal(round0Prize,web3.toWei(3));

        let round1Prize = await DefiGameInstance.extraPrizeMap(1);
        console.log(round1Prize)
        assert.equal(round1Prize,web3.toWei(3))

        let round2Prize = await DefiGameInstance.extraPrizeMap(2);
        console.log(round2Prize)
        assert.equal(round2Prize,web3.toWei(3))


    })
    ///////////////////////////////////////first round//////////////////////////////////

    it('[90000004] Set first round open price,expect scucess', async () => {


        console.log(calRoundNUmber)
        let wanToBtcOpenPrice = 3026;//SATOSHI
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

        var ret = await DefiGameInstance.stakeIn(true,{from:global.ACCOUNT1,value:stake,gas:4710000});
        sleep(5);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
     //   assert.equal(res[2].toNumber(),stake);

    })


    it('[90000006] first round stakein two,expect scucess', async () => {

        var ret = await DefiGameInstance.stakeIn(false,{from:global.ACCOUNT2,value:stake,gas:4710000});
        sleep(10);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        assert.equal(res[3].toNumber(),stake);


        var ret = await DefiGameInstance.stakeIn(false,{from:global.ACCOUNT3,value:stake,gas:4710000});
        sleep(10);

        res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        assert.equal(res[3].toNumber(),stake*2);
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
        console.log("prebalance=" + web3.fromWei(preAccountBalance1))
        var ret = await DefiGameInstance.upDownLotteryFanalize({from:owner,gas:4710000});
        console.log(ret.logs[0].args)

        sleep(10);

        let afterAccountBalance1 = await web3.eth.getBalance(global.ACCOUNT1);
        console.log("afterbalance=" +  web3.fromWei(afterAccountBalance1))

        assert.equal(afterAccountBalance1-preAccountBalance1>0,true)

    })


    //////////////////////////////second round/////////////////////////////////////////
    it('[90000104] Set second round open price,expect scucess', async () => {
        console.log("\n\n--------------------------second round-----------------------------------------------------------------------")
        calRoundNUmber = 1;

        console.log(calRoundNUmber)

        let wanToBtcOpenPrice = 3026;//SATOSHI
        //for open price,do not need put cycleNumber,just put it as 0
        var ret = await DefiGameInstance.setPriceIndex(wanToBtcOpenPrice,0,true,{from:owner,gas:4710000});
        //console.log(ret)
        sleep(100);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);
        console.log(calRoundNUmber)

        assert.equal(res[0].toNumber(),wanToBtcOpenPrice);


    })


    it('[90000105] second round stakein one,expect scucess', async () => {

        let startTime = starTime + cycleTime*(calRoundNUmber);
        wait(function(){let nowTime = parseInt(Date.now()/1000); return nowTime > startTime;});

        var ret = await DefiGameInstance.stakeIn(true,{from:global.ACCOUNT1,value:stake,gas:4710000});
        sleep(10);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        //   assert.equal(res[2].toNumber(),stake);

    })


    it('[90000106] second round stakein two,expect scucess', async () => {


        var ret = await DefiGameInstance.stakeIn(false,{from:global.ACCOUNT2,value:stake,gas:4710000});
        sleep(10);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        assert.equal(res[3].toNumber(),stake);


        var ret = await DefiGameInstance.stakeIn(false,{from:global.ACCOUNT3,value:stake,gas:4710000});
        sleep(10);

        res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        assert.equal(res[3].toNumber(),stake*2);
    })


    it('[90000107] second round set close price,expect scucess', async () => {
        let wanToBtcCLosePrice = 3000;//SATOSHI
        //for open price,do not need put cycleNumber,just put it as 0
        var ret = await DefiGameInstance.setPriceIndex(wanToBtcCLosePrice,calRoundNUmber,false,{from:owner,gas:global.GAS*10});
        sleep(100);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);
        console.log(res)


        assert.equal(res[1].toNumber(),wanToBtcCLosePrice);

    })


    it('[90000108] second round updownFanalize,expect scucess', async () => {

        let endTime = starTime + cycleTime*(calRoundNUmber + 1);
        wait(function(){let nowTime = parseInt(Date.now()/1000); return nowTime > endTime;});


        let preAccountBalance1 = await web3.eth.getBalance(global.ACCOUNT2);
        console.log("prebalance=" + web3.fromWei(preAccountBalance1))
        var ret = await DefiGameInstance.upDownLotteryFanalize({from:owner,gas:4710000});
        console.log(ret.logs[0].args)

        sleep(1000);

        let afterAccountBalance1 = await web3.eth.getBalance(global.ACCOUNT2);
        console.log("afterbalance=" +  web3.fromWei(afterAccountBalance1))

        assert.equal(afterAccountBalance1-preAccountBalance1>0,true)

    })


    //////////////////////////////second round/////////////////////////////////////////
    it('[90000204] Set third round open price,expect scucess', async () => {
        console.log("\n\n--------------------------third round-----------------------------------------------------------------------")
        calRoundNUmber = 2;

        console.log(calRoundNUmber)

        let wanToBtcOpenPrice = 3026;//SATOSHI
        //for open price,do not need put cycleNumber,just put it as 0
        var ret = await DefiGameInstance.setPriceIndex(wanToBtcOpenPrice,0,true,{from:owner,gas:4710000});
        //console.log(ret)
        sleep(100);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);
        console.log(calRoundNUmber)

        assert.equal(res[0].toNumber(),wanToBtcOpenPrice);



        let currentRound = await DefiGameInstance.curUpDownRound();
        console.log("inside round number=" + currentRound);

    })


    it('[90000205] third round stakein one,expect scucess', async () => {

        let startTime = starTime + cycleTime*(calRoundNUmber);
        wait(function(){let nowTime = parseInt(Date.now()/1000); return nowTime > startTime;});

        var ret = await DefiGameInstance.stakeIn(true,{from:global.ACCOUNT1,value:stake,gas:4710000});
        sleep(10);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)

        var ret = await DefiGameInstance.stakeIn(true,{from:global.ACCOUNT2,value:stake,gas:4710000});
        sleep(10);

        res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)

    })


    it('[90000206] third round stakein two,expect scucess', async () => {


        var ret = await DefiGameInstance.stakeIn(false,{from:global.ACCOUNT2,value:stake,gas:4710000});
        sleep(10);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        assert.equal(res[3].toNumber(),stake);


        var ret = await DefiGameInstance.stakeIn(false,{from:global.ACCOUNT3,value:stake,gas:4710000});
        sleep(10);

        res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        assert.equal(res[3].toNumber(),stake*2);
    })


    it('[90000207] third round set close price,expect scucess', async () => {
        let wanToBtcCLosePrice = 3026;//SATOSHI
        //for open price,do not need put cycleNumber,just put it as 0
        var ret = await DefiGameInstance.setPriceIndex(wanToBtcCLosePrice,calRoundNUmber,false,{from:owner,gas:global.GAS*10});
        sleep(100);

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);
        console.log(res)


        assert.equal(res[1].toNumber(),wanToBtcCLosePrice);

    })


    it('[90000208] third round updownFanalize,expect scucess', async () => {

        let endTime = await DefiGameInstance.chainEndTime();
        wait(function(){let nowTime = parseInt(Date.now()/1000); return nowTime > endTime;});


        let preAccountBalance1 = await web3.eth.getBalance(global.ACCOUNT1);
        console.log("prebalance=" + web3.fromWei(preAccountBalance1))

        let contractBalance1 = await web3.eth.getBalance(DefiGameInstanceAddress);
        console.log("contract balance=" + contractBalance1);

        var ret = await DefiGameInstance.upDownLotteryFanalize({from:owner,gas:4710000});
        console.log(ret.logs[0].args)
        console.log(ret.logs[1].args)
        console.log(ret.logs[2].args)
        console.log(ret.logs[3].args)
        sleep(10);

        let afterAccountBalance1 = await web3.eth.getBalance(global.ACCOUNT1);
        console.log("afterbalance=" +  web3.fromWei(afterAccountBalance1))

        assert.equal(preAccountBalance1 - afterAccountBalance1< web3.fromWei(0.5),true)

    })




})



