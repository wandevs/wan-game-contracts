pragma solidity ^0.4.24;

import "./SafeMath.sol";
import "./Owned.sol";

contract DefiGame is Owned {

    using SafeMath for uint;
    uint public constant DIVISOR = 1000;

    struct StakerInfo {
        address     staker;
        uint        stakeAmount;			//the storeman group deposit
        uint        stakingTime;            //stake input time
    }

    struct UpDownGameItem {
        uint                    openPrice;
        uint                    closePrice;
        uint                    upAmount;
        uint                    downAmount;
        bool                    finished;
        uint                    upStakersIdx;
        uint                    downStakersIdx;
        mapping(uint=>address)  upStakers;
        mapping(uint=>address)  downStakers;
        mapping(address=>uint)  upStakeOfStaker;
        mapping(address=>uint)  downStakeOfStaker;
    }

    struct RandomGameItem{
        uint                        stakeAmount;
        uint                        startUpdownRound;
        uint                        stopUpdownRound;
        bool                        finished;
        uint                        stakingTimeIdx;
        uint                        accStakeRangeIdx;
        mapping(uint=>uint)         stakingTime;
        mapping(uint=>uint)         accStakeRange;
        mapping(uint=>StakerInfo)   stakerInfoMap;
    }

    mapping(uint=>UpDownGameItem)  public updownGameMap;
    mapping(uint=>RandomGameItem)  public randomGameMap;


    uint public curUpDownRound;
    uint public curRandomRound;

    /// Due to an emergency, set this to true to halt the contribution
    bool public halted;

    uint public updownLotteryStartRN;
    //updown game start time of day
    uint public gameStartTime;
    //updown game time cycle
    uint public upDownLotteryTimeCycle;
    //updown game stop time span in advance
    uint public upDownLtrstopTimeSpanInAdvance;


    uint public randomLotteryStartRN;

    uint public calRoundNumber;

    //random lottery time cycle
    uint public randomLotteryTimeCycle;

    uint public feeRatio;
    uint public winnerNum;

    mapping(uint=>uint) public extraPrizeMap;//start cycle nuber=>each round prize
    mapping(uint=>address) public winnerMap;
    mapping(uint=>uint) public randomMap;
    /*
     * EVENTS
     */
    event StakeIn(address indexed staker, uint indexed stakeAmount,uint indexed upDownRound, uint calRandomRound);

    event RandomBingGo(address indexed staker,uint indexed prizeAmount,uint indexed round);

    event UpDownBingGo(address indexed staker,uint indexed prizeAmount,uint indexed round);

    event UpDownReturn(address indexed staker,uint indexed prizeAmount,uint indexed round);

    /*
     * MODIFIERS
     */

    modifier notHalted() {
        require(!halted);
        _;
    }

    function () public payable {
    	revert();
    }

    //allow others to stake for others
    function stakeIn(bool _up)
        public
        notHalted
        payable
    {
       require(msg.value >=  1 ether);
       require(upDownLotteryTimeCycle > 0);
       require(randomLotteryTimeCycle > 0);
       require (winnerNum > 0);
       require(feeRatio > 0);


       uint calUpDownRound = now.div(upDownLotteryTimeCycle).sub(updownLotteryStartRN);
       uint calRandomRound = now.div(randomLotteryTimeCycle).sub(randomLotteryStartRN);

       //each round start time
       uint startTime = gameStartTime.add(upDownLotteryTimeCycle.mul(calUpDownRound));
       //each round end time
       uint endTime = startTime.add(upDownLotteryTimeCycle).sub(upDownLtrstopTimeSpanInAdvance);

       require(now>=startTime && now<endTime);
       //need set open price before stake in
       require(updownGameMap[calUpDownRound].openPrice > 0) ;

        if(_up) {
            updownGameMap[calUpDownRound].upAmount = msg.value.add(updownGameMap[calUpDownRound].upAmount);
            //record new staker
            if (updownGameMap[calUpDownRound].upStakeOfStaker[msg.sender] == 0) {
              updownGameMap[calUpDownRound].upStakers[updownGameMap[calUpDownRound].upStakersIdx++] = msg.sender;
            }

            updownGameMap[calUpDownRound].upStakeOfStaker[msg.sender] = updownGameMap[calUpDownRound].upStakeOfStaker[msg.sender].add(msg.value);
       } else {
            updownGameMap[calUpDownRound].downAmount = msg.value.add(updownGameMap[calUpDownRound].downAmount);
            //record new staker
            if (updownGameMap[calUpDownRound].downStakeOfStaker[msg.sender] == 0) {
               updownGameMap[calUpDownRound].downStakers[updownGameMap[calUpDownRound].downStakersIdx++] = msg.sender;
            }

            updownGameMap[calUpDownRound].downStakeOfStaker[msg.sender] = updownGameMap[calUpDownRound].downStakeOfStaker[msg.sender].add(msg.value);
       }

       //record orginal stake info
       randomGameMap[calRandomRound].stakerInfoMap[now] = StakerInfo(msg.sender,msg.value,now);
       randomGameMap[calRandomRound].stakeAmount = randomGameMap[calRandomRound].stakeAmount.add(msg.value);

       //push the info to accumulate array
       randomGameMap[calRandomRound].accStakeRange[randomGameMap[calRandomRound].accStakeRangeIdx++] = (randomGameMap[calRandomRound].stakeAmount);
       randomGameMap[calRandomRound].stakingTime[randomGameMap[calRandomRound].stakingTimeIdx++] = (now);

       emit StakeIn(msg.sender,msg.value,calUpDownRound,calRandomRound);
    }



    function upDownLotteryFanalize()
        onlyOwner
        notHalted
        public
    {
       require(!updownGameMap[curUpDownRound].finished);

       require(updownGameMap[curUpDownRound].openPrice != 0);
       require(updownGameMap[curUpDownRound].closePrice != 0);

       require(feeRatio > 0);

       //adjust variable,then transfer
       updownGameMap[curUpDownRound].finished = true;

       uint prizePercent = DIVISOR.sub(feeRatio);
       uint total =  updownGameMap[curUpDownRound].upAmount.add(updownGameMap[curUpDownRound].downAmount);
       uint winnerPrize = total.mul(prizePercent).div(DIVISOR);
       uint i;
       address sAddr;
       uint stake;
       uint gotPrize = 0;

       if (updownGameMap[curUpDownRound].closePrice > updownGameMap[curUpDownRound].openPrice
           && updownGameMap[curUpDownRound].downAmount > 0 //divid down stake if price up
           ) {

            for (i=0;i<updownGameMap[curUpDownRound].upStakersIdx;i++) {
                sAddr = updownGameMap[curUpDownRound].upStakers[i];
                stake = updownGameMap[curUpDownRound].upStakeOfStaker[sAddr];

                gotPrize = winnerPrize.mul(stake).div(updownGameMap[curUpDownRound].upAmount);
                sAddr.transfer(gotPrize);

                emit UpDownBingGo(sAddr,gotPrize,curUpDownRound);
            }

        } else if (updownGameMap[curUpDownRound].closePrice < updownGameMap[curUpDownRound].openPrice
                && updownGameMap[curUpDownRound].upAmount > 0 //divid up stake if price down
             ) {

            for (i=0;i<updownGameMap[curUpDownRound].downStakersIdx;i++) {
                sAddr = updownGameMap[curUpDownRound].downStakers[i];
                stake = updownGameMap[curUpDownRound].downStakeOfStaker[sAddr];

                gotPrize = winnerPrize.mul(stake).div(updownGameMap[curUpDownRound].downAmount);
                sAddr.transfer(gotPrize);

                emit UpDownBingGo(sAddr,gotPrize,curUpDownRound);
            }

        } else {
            //return back stake after cut fee
            for (i=0;i<updownGameMap[curUpDownRound].upStakersIdx;i++) {
                sAddr = updownGameMap[curUpDownRound].upStakers[i];
                stake = updownGameMap[curUpDownRound].upStakeOfStaker[sAddr].mul(prizePercent).div(DIVISOR);
                sAddr.transfer(stake);
                emit UpDownBingGo(sAddr,stake,curUpDownRound);
            }

            for (i=0;i<updownGameMap[curUpDownRound].downStakersIdx;i++) {
                sAddr = updownGameMap[curUpDownRound].downStakers[i];
                stake = updownGameMap[curUpDownRound].downStakeOfStaker[sAddr].mul(prizePercent).div(DIVISOR);
                sAddr.transfer(stake);
                emit UpDownBingGo(sAddr,stake,curUpDownRound);
            }
        }

        curUpDownRound++;
    }

    function randomLotteryFanalize()
        onlyOwner
        notHalted
        public
    {
       require(!randomGameMap[curRandomRound].finished);
       require(randomGameMap[curRandomRound].stopUpdownRound != 0);
       require (winnerNum > 0);

       //adjust variable,then transfer
       randomGameMap[curRandomRound].finished = true;

       //if there is no stake,send a event no prize
       if (randomGameMap[curRandomRound].stakeAmount == 0) {
           emit RandomBingGo(0x0,0,curRandomRound);
       } else {
           uint rb = randomMap[curRandomRound];
            //get winners
           uint i;
           for(i==0;i<winnerNum;i++) {

                 uint expected = rb.mod(randomGameMap[curRandomRound].stakeAmount);
                 uint idx = randomStakerfind(expected);

                 uint inputTime = randomGameMap[curRandomRound].stakingTimeIdx;
                 winnerMap[i] = randomGameMap[curRandomRound].stakerInfoMap[inputTime].staker;

                 //use previous winner select next winner
                 uint256 hash = uint256(sha256(rb, 0x04, now, idx));
                 rb = uint(hash);
            }

            //use fee ratio to get all of prize
            uint totalPrize = randomGameMap[curRandomRound].stakeAmount.mul(feeRatio).div(DIVISOR);
            //add extra prize
            totalPrize = totalPrize.add(extraPrizeMap[curRandomRound]);

            uint winnerPrize = totalPrize.div(winnerNum);
            for(i=0;i<winnerNum;i++) {
                winnerMap[i].transfer(winnerPrize);
                emit RandomBingGo(winnerMap[i],winnerPrize,curRandomRound);
            }
       }

       curRandomRound++;

    }

    function setUpDownLotteryTime(uint _startTime,uint _updownLtryTimeCycle, uint _stopTimeSpanInAdvance)
        onlyOwner
        notHalted
        public
    {
        //only set one time
        require (updownLotteryStartRN == 0 );
        require(_startTime > 0);
        require(_updownLtryTimeCycle > 0);
        require(_stopTimeSpanInAdvance > 0);

        updownLotteryStartRN ;
        if ( _startTime.mod(_updownLtryTimeCycle) == 0 ) {
            updownLotteryStartRN = _startTime.div(_updownLtryTimeCycle);
        } else {
            updownLotteryStartRN = _startTime.div(_updownLtryTimeCycle).add(1);
        }

        //other can be changed any time
        gameStartTime = _updownLtryTimeCycle*updownLotteryStartRN;

        upDownLotteryTimeCycle = _updownLtryTimeCycle;
        upDownLtrstopTimeSpanInAdvance = _stopTimeSpanInAdvance;
    }

    function setRandomLotteryTime(uint _randomLotteryTimeCycle)
        onlyOwner
        notHalted
        public
    {
       //only set one time
       require(gameStartTime > 0 );
       require(_randomLotteryTimeCycle>upDownLotteryTimeCycle);
       require(_randomLotteryTimeCycle.mod(upDownLotteryTimeCycle) == 0);

       randomLotteryStartRN = gameStartTime.div(_randomLotteryTimeCycle);
       randomLotteryTimeCycle = _randomLotteryTimeCycle;
    }

    function setPriceIndex(uint _currentPriceIndex, uint _cycleumber,bool _flag)
        onlyOwner
        notHalted
        public
    {
        require(gameStartTime != 0);
        require(_currentPriceIndex > 0);
        require(now > gameStartTime);

        //only can change current round price
        uint calUpDownRound = now.div(upDownLotteryTimeCycle).sub(updownLotteryStartRN);
        calRoundNumber = calUpDownRound;//for debug

        if (_flag) {
            //set current round open price
            if (updownGameMap[calUpDownRound].openPrice == 0) {
                  updownGameMap[calUpDownRound] = UpDownGameItem(0,0,0,0,false,0,0);
            }
           updownGameMap[calUpDownRound].openPrice = _currentPriceIndex;

           uint calRandomRound = now.div(randomLotteryTimeCycle).sub(randomLotteryStartRN);
           if (randomGameMap[calRandomRound].stakeAmount==0) {
               randomGameMap[calRandomRound] = RandomGameItem(0,calUpDownRound,0,false,0,0);
               if (calRandomRound > 0 && randomGameMap[calRandomRound.sub(1)].stopUpdownRound == 0) {
                 randomGameMap[calRandomRound.sub(1)].stopUpdownRound = calUpDownRound;
               }
           }

        } else {
            require(_cycleumber <= calUpDownRound);
            require((updownGameMap[_cycleumber].openPrice > 0));
            require(!updownGameMap[_cycleumber].finished);
            updownGameMap[_cycleumber].closePrice = _currentPriceIndex;
        }
    }

    function inputUpdownExtraPrize(uint _startCycleNumber, uint _cycleNumber)
        payable
        onlyOwner
        notHalted
        public
    {
        require(gameStartTime > 0 );
        require(_startCycleNumber >= curRandomRound);
        require(_cycleNumber > 0);
        uint i;
        for(i=_startCycleNumber;i<_cycleNumber;i++) {
            extraPrizeMap[_startCycleNumber] = msg.value.div(_cycleNumber);
        }
    }

    function setRandomWinnerNumber(uint _winnerNum)
        onlyOwner
        notHalted
        public
    {
        require (_winnerNum > 0);
        winnerNum = _winnerNum;
    }

     //feeRatio is mul 1000
     function setFeeRatio(uint _feeRatio)
        onlyOwner
        notHalted
        public
     {
         require(_feeRatio > 0);
         feeRatio = _feeRatio;
     }

    function setFanalizeRoundNumber(uint _curUpDownRound, uint _curRandomRound)
        onlyOwner
        notHalted
        public
    {
        if (_curUpDownRound != 0) {
           curUpDownRound = _curUpDownRound;
        }

        if (_curRandomRound != 0) {
           curRandomRound = _curRandomRound;
        }

    }

   //because function gas problem,so take it as isolate function
  function genRandom(uint _randomRound)
        onlyOwner
        notHalted
        public
    {

        uint timeNow = now;
        if (_randomRound > 0) {
             timeNow = gameStartTime.add(upDownLotteryTimeCycle.mul(_randomRound));
        }

        (uint256 result, bool success) = callWith32BytesReturnsUint256(
                                                PRECOMPILE_CONTRACT_ADDR,
                                                RANDOM_BY_EPID_SELECTOR,
                                                bytes32(timeNow)
                                          );

        randomMap[curRandomRound] = uint(result);
    }

   //in case of big mistake,return back staker' stake
    function upDownLotteryGiveBack(uint _updownRound)
        onlyOwner
        public
    {
        require(!updownGameMap[_updownRound].finished);

        updownGameMap[_updownRound].finished = true;

        address sAddr;
        uint stake;
        uint i;
        for (i=0;i<updownGameMap[_updownRound].upStakersIdx;i++) {
            sAddr = updownGameMap[_updownRound].upStakers[i];
            stake = updownGameMap[_updownRound].upStakeOfStaker[sAddr];
            sAddr.transfer(stake);
            emit UpDownReturn(sAddr,stake,_updownRound);
        }


        for (i=0;i<updownGameMap[_updownRound].downStakersIdx;i++) {
            sAddr = updownGameMap[_updownRound].downStakers[i];
            stake = updownGameMap[_updownRound].downStakeOfStaker[sAddr];
            sAddr.transfer(stake);
            emit UpDownReturn(sAddr,stake,_updownRound);
        }

       updownGameMap[_updownRound].upAmount = 0;
       updownGameMap[_updownRound].downAmount = 0;

    }



    function chainEndTime() public view returns(uint) {
       return now;
    }

    //--------------------------------private method-----------------------------------
    function  randomStakerfind(uint target)
           private
           view
           returns (uint)
    {

            uint left = 0;
            uint right = randomGameMap[curRandomRound].accStakeRangeIdx - 1;

            if (target < randomGameMap[curRandomRound].accStakeRange[0]) {
               return 0;
            }

            //should not happen,just for safe
            if (target >= randomGameMap[curRandomRound].accStakeRange[right]) {
                return right;
            }

            while(left <= right) {
                uint mid = (left + right) / 2;
                if( target >= randomGameMap[curRandomRound].accStakeRange[mid] && target<randomGameMap[curRandomRound].accStakeRange[mid+1]) {
                    return mid + 1;
                }  else if (randomGameMap[curRandomRound].accStakeRange[mid] < target) {
                    left = mid;
                } else if (randomGameMap[curRandomRound].accStakeRange[mid] > target) {
                    right = mid;
                }

            }

    }


////////////////////////////////////////////////////////////////////////////
    bytes32 constant RANDOM_BY_EPID_SELECTOR = 0x7f07b9ab00000000000000000000000000000000000000000000000000000000;
    bytes32 constant RANDOM_BY_BLKTIME_SELECTOR = 0xdf39683800000000000000000000000000000000000000000000000000000000;
    bytes32 constant GET_EPOCHID_SELECTOR = 0x5303548b00000000000000000000000000000000000000000000000000000000;
    address constant PRECOMPILE_CONTRACT_ADDR = 0x262;

   function callWith32BytesReturnsUint256(
        address to,
        bytes32 functionSelector,
        bytes32 param1
        )

        private

        returns (uint256 result, bool success) {

        assembly {
            let freePtr := mload(0x40)
            let tmp1 := mload(freePtr)
            let tmp2 := mload(add(freePtr, 4))

            mstore(freePtr, functionSelector)
            mstore(add(freePtr, 4), param1)

            // call ERC20 Token contract transfer function
            success := staticcall(
                gas,           // Forward all gas
                to,            // Interest Model Address
                freePtr,       // Pointer to start of calldata
                36,            // Length of calldata
                freePtr,       // Overwrite calldata with output
                32             // Expecting uint256 output
            )

            result := mload(freePtr)

            mstore(freePtr, tmp1)
            mstore(add(freePtr, 4), tmp2)
        }
    }

/////////////////////////////////////mock up for test ///////////////////////

/*
    function testRandomStakerfind() public view returns(uint)
    {
       storageIntArray ta = new storageIntArray();
       ta.push(10);
       ta.push(200);
       ta.push(3000);
       ta.push(4000);
       ta.push(10000);

       uint res = randomStakerfind(ta,5);
       if (res != 0) {
           return 1;
       }

       res = randomStakerfind(ta,520);
       if (res != 2) {
           return 2;
       }

       res = randomStakerfind(ta,9999);
       if (res != 4) {
           return 3;
       }

       res = randomStakerfind(ta,10001);
       if (res != 4) {
            return 4;
       }

       return 999999999;

    }
*/



}