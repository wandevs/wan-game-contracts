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








})



