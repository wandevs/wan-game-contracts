require('truffle-test-utils').init()
require('./constant.js')

////////////////////////////////////////////////////////////////////////////////////

let FinNexusContributionInstance,
    FinNexusContributionInstanceAddress,
    CfncTokenInstance,
    CfncTokenInstanceAddress,
    UM1SInstance,
    UM1SInstanceAddress,
    PHASE1_StartTime,
    PHASE1_EndTime,
    PHASE1_ConTokenStartTime,
    PHASE1_ConTokenEndTime,
    PHASE2_StartTime,
    PHASE2_EndTime,
    PHASE2_ConTokenStartTime,
    PHASE2_ConTokenEndTime

////////////////////////////////////////////////////////////////////////////////////////
contract('', async ([owner]) => {


  it('[90000000] Deploy contracts', async () => {

    owner = OWNER_ADDRESS;
    // unlock accounts
    await web3.personal.unlockAccount(owner, 'wl', 99999);
    await web3.personal.unlockAccount(USER1_ADDRESS, 'wl', 99999);
    await web3.personal.unlockAccount(USER2_ADDRESS, 'wl', 99999);

    console.log(colors.green('[INFO] owner: ', owner));

    // deploy token manager
    FinNexusContributionInstance = await FinNexusSol.new({from: owner});

    FinNexusContributionInstanceAddress = FinNexusContributionInstance.address;

    console.log(colors.green('[INFO] FinNexusContributionInstance address:', FinNexusContributionInstanceAddress));


    CfncTokenInstance = await CfncTokenSol.new(FinNexusContributionInstanceAddress,owner,{from:owner});
    CfncTokenInstanceAddress = CfncTokenInstance.address
    console.log(colors.green('[INFO] CfncTokenInstance address:', CfncTokenInstanceAddress));


    UM1SInstanceAddress = await CfncTokenInstance.um1sToken();
    console.log(colors.green('[INFO] UM1SInstance address:', UM1SInstanceAddress));
    UM1SInstance = UM1SToken.at(UM1SInstanceAddress);

    console.log(colors.green('[INFO] Contracts deployed success!', ''));


  })


  it('[90000010] initialize contract should success', async () => {

    PHASE1_StartTime = Date.now()/1000;
    PHASE1_EndTime = PHASE1_StartTime + 2*TIME_INTERVAL;

    PHASE1_ConTokenStartTime = PHASE1_StartTime;
    PHASE1_ConTokenEndTime = PHASE1_StartTime + 2*TIME_INTERVAL;


    console.log(colors.green('Phase1 start time: ',PHASE1_StartTime));


      let ret = await FinNexusContributionInstance.initAddress(WALLET_ADDRESS,CfncTokenInstanceAddress,{from:owner});

      let gotWalletAddress = await FinNexusContributionInstance.walletAddress();
      let tokenAddress =  await FinNexusContributionInstance.cfncTokenAddress();

      console.log(colors.green('gotWalletAddress: ',gotWalletAddress));
      console.log(colors.green('tokenAddress: ',tokenAddress));

      assert.equal(gotWalletAddress,WALLET_ADDRESS)
      assert.equal(tokenAddress,CfncTokenInstanceAddress);

      ret = await FinNexusContributionInstance.init(PHASE1,
                                              PHASE1_WanRatioOfSold,
                                              PHASE1_StartTime,
                                              PHASE1_EndTime,
                                              PHASE1_Wan2CfncRate,{from:owner});
      //console.log(ret)

      let gotPhase1 =  await FinNexusContributionInstance.CURRENT_PHASE();
      let gotStartTime =  await FinNexusContributionInstance.startTime();
      let gotEndTime =  await FinNexusContributionInstance.endTime();
      let gotWAN_CFNC_RATE =  await FinNexusContributionInstance.WAN_CFNC_RATE();
      let initialized = await FinNexusContributionInstance.isInitialized();

      assert.equal(gotPhase1,PHASE1);
      assert.equal(gotStartTime,parseInt(PHASE1_StartTime));
      assert.equal(gotEndTime,parseInt(PHASE1_EndTime));
      assert.equal(gotWAN_CFNC_RATE,PHASE1_Wan2CfncRate);
      assert.equal(initialized,true);

      let gotMAX_OPEN_SOLD =  await FinNexusContributionInstance.MAX_OPEN_SOLD();
      let gotMAX_EXCHANGE_MINT =  await FinNexusContributionInstance.MAX_EXCHANGE_MINT();

      console.log(colors.green('gotMAX_OPEN_SOLD: ',gotMAX_OPEN_SOLD,MAX_OPEN_SOLD));

      console.log(colors.green('gotMAX_EXCHANGE_MINT: ',gotMAX_EXCHANGE_MINT,MAX_EXCHANGE_MINT));

      ret = await CfncTokenInstance.init(PHASE1,PHASE1_ConTokenStartTime,PHASE1_ConTokenEndTime,PHASE1_Cfnc2UM1SRatio);
      //console.log(ret)

      let gotConStartTime =  await CfncTokenInstance.conStartTime();
      let gotConEndTime =  await CfncTokenInstance.conEndTime();
      let gotConRatio =  await CfncTokenInstance.conRatio();

      assert.equal(gotConStartTime,parseInt(PHASE1_ConTokenStartTime));
      assert.equal(gotConEndTime,parseInt(PHASE1_ConTokenEndTime));
      assert.equal(gotConRatio,PHASE1_Cfnc2UM1SRatio);

      assert.equal(gotMAX_EXCHANGE_MINT.toNumber(),MAX_EXCHANGE_MINT.toNumber());
      assert.equal(gotMAX_OPEN_SOLD.toNumber(),MAX_OPEN_SOLD.toNumber());


      assert.web3Event(ret, {
            event: 'FirstPhaseParameters',
            args: {
                startTime: parseInt(PHASE1_ConTokenStartTime),
                endTime: parseInt(PHASE1_ConTokenEndTime),
                conRatio: PHASE1_Cfnc2UM1SRatio
            }
      })  ;

  })






})



