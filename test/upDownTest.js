require('truffle-test-utils').init()
require('./constant.js')

////////////////////////////////////////////////////////////////////////////////////

let DefiGameInstance


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



   // function setUpDownLotteryTime(uint _startTime,uint _updownLtryTimeCycle, uint _stopTimeSpanInAdvance)
  it('[90000001] Set Sart time', async () => {

      let starTime = Date.now()/1000;
      let cycleTime = 10*60;
      let stopTimeInAdvance = 2*60;

      var ret = await DefiGameInstance.setUpDownLotteryTime(starTime,cycleTime,stopTimeInAdvance,{from:owner});


      assert.equal(DefiGameInstance.gameStartTime(),starTime);
      assert.equal(DefiGameInstance.upDownLotteryTimeCycle(),cycleTime);
      assert.equal(DefiGameInstance.upDownLtrstopTimeSpanInAdvance(),stopTimeInAdvance);


    })






})



