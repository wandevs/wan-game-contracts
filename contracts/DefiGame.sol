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
        uint                    openPrice;  //the open price
        uint                    closePrice; //the close price
        uint                    upAmount;   //the stake amount for up
        uint                    downAmount; //the down stake amount for down
        bool                    finished;     //indicator for the status in current round
        uint                    upStakersIdx;  //the index for up stakers
        uint                    downStakersIdx; //the index for down stakers
        mapping(uint=>address)  upStakers;      //the stakers staking up
        mapping(uint=>address)  downStakers;    //the down stakers staking down
        mapping(address=>uint)  upStakeOfStaker; //the up staker's stake
        mapping(address=>uint)  downStakeOfStaker; //the down staker's stake
    }

    struct RandomGameItem{
        uint                        stakeAmount;       //the total stake amount
        uint                        startUpdownRound;  //the start round for updown in current random round
        uint                        stopUpdownRound;   //the stop round for updown in current random round
        bool                        finished;          //the status
        uint                        stakingTimeIdx;    //the time stake index
        uint                        accStakeRangeIdx;  //the accumulate range index
        mapping(uint=>uint)         stakingTime;       //the map for storing staking time
        mapping(uint=>uint)         accStakeRange;     //the accumulate range array for looking up
        mapping(uint=>StakerInfo)   stakerInfoMap;     //the staker's info
    }

    mapping(uint=>UpDownGameItem)  public updownGameMap; //the records for all updown game
    mapping(uint=>RandomGameItem)  public randomGameMap; //the records for all random game


    uint public curUpDownRound;   //current updown round number wait to be fanalized
    uint public curRandomRound;   //current radom  round number wait to be fanalized

    /// Due to an emergency, set this to true to halt the contribution
    bool public halted;           //the indicator for stop game

    uint public updownLotteryStartRN;  //the updown game start round number

    uint public randomLotteryStartRN;  //the random game start round number

    uint public gameStartTime;                      //updown game start time

    uint public upDownLotteryTimeCycle;             //updown game time cycle

    uint public upDownLtrstopTimeSpanInAdvance;     //updown game stop time span in advance

    uint public randomLotteryTimeCycle;         //random lottery time cycle

    //for debug
    uint public calUpDownRoundNumber;
    uint public calRandomRoundNumber;



    uint public feeRatio;  //fee ratio for each stake in updown game
    uint public winnerNum; //the winner number in random game

    mapping(uint=>uint) public extraPrizeMap;  //the extra prize provided by wanchain foundation
    mapping(uint=>address) public winnerMap;   //the winner info
    mapping(uint=>uint) public randomMap;      //the random record for each random round
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

     /**
     * public function stakeIn
     *
     * @dev the interface for user stake in
     * @param _up indicator stake for up or down, true up,false down
     *
     */
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


    /**
     * public upDownLotteryFanalize
     *
     * @dev clear updown game and return winning prize after cut fee for random game
     *
     */

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

    /**
     * public randomLotteryFanalize
     *
     * @dev select staker from stakers in updown round by random
     * and give  winner prize from stakers fee and extra prize from foundation
     *
     */
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
           for(i=0;i<winnerNum;i++) {

                 uint expected = rb.mod(randomGameMap[curRandomRound].stakeAmount);
                 uint idx = randomStakerfind(expected);

                 uint inputTime = randomGameMap[curRandomRound].stakingTime[idx];
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

     /**
     * public function setLotteryTime
     *
     * @dev set game related time
     *      need _randomLotteryTimeCycle mod _updownLtryTimeCycle to be 0
     *      startTime would be multiple of _randomLotteryTimeCycle
     *      if not, the game start time will be the (N+1)*_randomLotteryTimeCycle
     * @param _startTime  the wanted game start time,but game maybe not be this one,need to be caculate
     * @param _updownLottryTimeCycle  the cycle time for updown game
     * @param _stopTimeSpanInAdvance  the stop time avanced before the real end time for this round
     * @param _randomLotteryTimeCycle the random cycle time for random game
     *
     */
    function setLotteryTime(uint _startTime,uint _updownLottryTimeCycle, uint _stopTimeSpanInAdvance,uint _randomLotteryTimeCycle)
        onlyOwner
        notHalted
        public
    {
        //only set one time
        require (updownLotteryStartRN == 0 );

        require(_startTime > 0);
        require(_updownLottryTimeCycle > 0);
        require(_stopTimeSpanInAdvance > 0);

        require(_randomLotteryTimeCycle>_updownLottryTimeCycle);
        require(_randomLotteryTimeCycle.mod(_updownLottryTimeCycle) == 0);

        if ( _startTime.mod(_randomLotteryTimeCycle) == 0 ) {
           randomLotteryStartRN = _startTime.div(_randomLotteryTimeCycle);
           gameStartTime =  _startTime;
        } else {
           randomLotteryStartRN = _startTime.div(_randomLotteryTimeCycle).add(1);
           gameStartTime = _randomLotteryTimeCycle.mul(randomLotteryStartRN);
        }

        randomLotteryTimeCycle = _randomLotteryTimeCycle;

        updownLotteryStartRN = gameStartTime.div(_updownLottryTimeCycle);
        upDownLotteryTimeCycle = _updownLottryTimeCycle;
        upDownLtrstopTimeSpanInAdvance = _stopTimeSpanInAdvance;
    }

    /**
     * public function
     *
     * @dev change wallet address for recieving wan
     * @param _currentPriceIndex the expected price index for open or close
     * @param _cycleumber the cycle number,it will be discard for open price but will be used for close price
     * @param _flag  the indicator for open or close,true open price,false close price
     *
     */
    function setPriceIndex(uint _currentPriceIndex, uint _cycleumber,bool _flag)
        onlyOwner
        notHalted
        public
    {
        require(gameStartTime != 0);
        require(_currentPriceIndex > 0);
        require(now > gameStartTime);

        calUpDownRoundNumber = now.div(upDownLotteryTimeCycle).sub(updownLotteryStartRN);
        calRandomRoundNumber = now.div(randomLotteryTimeCycle).sub(randomLotteryStartRN);

        //only can change current round price
        uint calUpDownRound = now.div(upDownLotteryTimeCycle).sub(updownLotteryStartRN);
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

    /**
     * public function inputExtraPrize
     *
     * @dev input ExtraPrize for random game
     * @param _startCycleNumber the start random game cycle number for extra prize
     * @param _cycleNumber the total random game number for extra prize
     *
     */
    function inputExtraPrize(uint _startCycleNumber, uint _cycleNumber)
        payable
        onlyOwner
        notHalted
        public
    {
        require(gameStartTime > 0 );
        require(_startCycleNumber >= curRandomRound);
        require(_cycleNumber > 0);
        uint i;
        for(i=_startCycleNumber;i<_startCycleNumber + _cycleNumber;i++) {
            extraPrizeMap[i] = msg.value.div(_cycleNumber);
        }
    }

    /**
     * public function setRandomWinnerNumber
     *
     * @dev set winner number for random game
     * @param _winnerNum winner number
     *
     */
    function setRandomWinnerNumber(uint _winnerNum)
        onlyOwner
        notHalted
        public
    {
        require (_winnerNum > 0);
        winnerNum = _winnerNum;
    }

    /**
     * public function setFeeRatio
     *
     * @dev set fee ratio for each stake
     * @param _feeRatio fee ratio
     *
     */
     function setFeeRatio(uint _feeRatio)
        onlyOwner
        notHalted
        public
     {
         require(_feeRatio > 0);
         feeRatio = _feeRatio;
     }

    /**
     * public function setFanalizeRoundNumber
     *
     * @dev set finalize round number for updown game or random game
     * @param _curUpDownRound round number for updown game
     * @param _curRandomRound round number for random game
     *
     */
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

    /**
     * public function genRandom
     *
     * @dev get random for current round random game because function gas problem,so take it as isolate function
     * @param _randomRound random game round
     *
     */
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


    /**
     * public function upDownLotteryGiveBack
     *
     * @dev give back stake to staker in the specificed updown roun in case of big mistake
     * @param _updownRound round number for updown game
     *
     */
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


    /**
     * public function chainEndTime
     *
     * @dev get the chain time
     *
     */

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