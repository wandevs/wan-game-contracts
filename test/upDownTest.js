require('truffle-test-utils').init()
require('./constant.js')

////////////////////////////////////////////////////////////////////////////////////

let DefiGameInstance

let cycleTime = 10*60;
let startUpDownRoundNb;

////////////////////////////////////////////////////////////////////////////////////////
contract('', async ([owner]) => {


  it('[90000000] Deploy contracts', async () => {

    owner = OWNER_ADDRESS;
    // unlock accounts
    await web3.personal.unlockAccount(owner, 'wanglu', 99999);


    console.log(colors.green('[INFO] owner: ', owner));

    // deploy token manager
    DefiGameInstance = await DefiGameSol.new({from: owner});

    DefiGameInstanceAddress = DefiGameInstance.address;

    console.log(colors.green('[INFO] DefiGameInstanceAddress address:', DefiGameInstanceAddress));


  })



  it('[90000001] Set updown game Sart time,expect scucess', async () => {

      let starTime = parseInt(Date.now()/1000);
      let stopTimeInAdvance = 60;
      startUpDownRoundNb = parseInt(starTime/cycleTime);

      var ret = await DefiGameInstance.setUpDownLotteryTime(starTime,cycleTime,stopTimeInAdvance,{from:owner});


      let gotStarTime = await DefiGameInstance.gameStartTime();
      let gotCycleTime = await DefiGameInstance.upDownLotteryTimeCycle();
      let gotStopSpan = await DefiGameInstance.upDownLtrstopTimeSpanInAdvance();

      assert.equal(gotStarTime,starTime);
      assert.equal(gotCycleTime,cycleTime);
      assert.equal(gotStopSpan,stopTimeInAdvance);


    })


    it('[90000002] Set random game time,expect scucess', async () => {

        var ret = await DefiGameInstance.setRandomLotteryTime(cycleTime,{from:owner});
        let gotCycleTime = await DefiGameInstance.randomLotteryTimeCycle();
        assert.equal(gotCycleTime,cycleTime);

    })


    it('[90000003] Set winner number,expect scucess', async () => {

        let winnerNUmber = 10;
        var ret = await DefiGameInstance.setRandomWinerNumber(winnerNUmber,{from:owner});
        let gotWinnerNUmber = await DefiGameInstance.winnerNum();
        assert.equal(gotWinnerNUmber,winnerNUmber);

    })

    it('[90000004] Set open price,expect scucess', async () => {
        let wanToBtcOpenPrice = 3026;//SATOSHI
        //for open price,do not need put cycleNumber,just put it as 0
        var ret = await DefiGameInstance.setPriceIndex(wanToBtcOpenPrice,0,true,{from:owner,gas:global.GAS*10});
        let starTime = parseInt(Date.now()/1000);
        let calRoundNUmber = parseInt(starTime/cycleTime) - startUpDownRoundNb

        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);
        console.log(res)


        assert.equal(res[0].toNumber(),wanToBtcOpenPrice);

    })


    it('[90000005] stakein,expect scucess', async () => {

        sleep(30);

        let stake = web3.toWei(10);
        var ret = await DefiGameInstance.stakeIn(true,{from:owner,value:stake,gas:4710000});

        let starTime = parseInt(Date.now()/1000);

        let calRoundNUmber = parseInt(starTime/cycleTime) - startUpDownRoundNb;
        let res = await DefiGameInstance.updownGameMap(calRoundNUmber);

        console.log(res)
        assert.equal(res[2].toNumber(),stake);

    })



})



