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
        address[]               upStakers;
        address[]               downStakers;
        bool                    finished;
        mapping(address=>uint)  stakeOfStaker;
    }

    struct RandomGameItem{
        uint                        curRandomStakeIdx;
        uint                        startUpdownRound;
        uint                        stopUpdownRound;
        uint[]                      stakingTime;
        uint[]                      accStakeRange;
        uint[]                      extraPrize;
        bool                        finished;
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

    //random lottery time cycle
    uint public randomLotteryTimeCycle;

    uint public feeRatio;
    uint public winnerNum;

    mapping(uint=>uint) public extraPrizeMap;//start cycle nuber=>each round prize



    /*
     * EVENTS
     */
    event StakeIn(address indexed staker, uint indexed stakeAmount,uint indexed upDownRound, uint calRandomRound);

    event RandomBingGo(address indexed staker,uint indexed prizeAmount,uint indexed round);

    event UpDownBingGo(address indexed staker,uint indexed prizeAmount,uint indexed round);


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

       if (randomGameMap[calRandomRound].curRandomStakeIdx==0) {
            uint[]  memory         stakingTime = new uint[](1);
            uint[]  memory         accStakeRange = new uint[](1);
            uint[]  memory         extraPrize = new uint[](1);
           randomGameMap[calRandomRound] = RandomGameItem(0,0,0,stakingTime,accStakeRange,extraPrize,false);
       }

       if(_up) {
            updownGameMap[calUpDownRound].upAmount = msg.value.add(updownGameMap[calUpDownRound].upAmount);
            updownGameMap[calUpDownRound].upStakers.push(msg.sender);
       } else {
            updownGameMap[calUpDownRound].downAmount = msg.value.add(updownGameMap[calUpDownRound].downAmount);
            updownGameMap[calUpDownRound].downStakers.push(msg.sender);
       }

       updownGameMap[calUpDownRound].stakeOfStaker[msg.sender] = updownGameMap[calUpDownRound].stakeOfStaker[msg.sender].add(msg.value);

       //record orginal stake info
       randomGameMap[calRandomRound].stakerInfoMap[now] = StakerInfo(msg.sender,msg.value,now);

       //cal accumulate stake range array
       uint idx =  randomGameMap[calRandomRound].curRandomStakeIdx;
       uint stakeAmount = randomGameMap[calRandomRound].accStakeRange[idx].add(msg.value);
       //push the info to accumulate array
       randomGameMap[calRandomRound].accStakeRange.push(stakeAmount);
       randomGameMap[calRandomRound].stakingTime.push(now);

       //array index add 1
       randomGameMap[calRandomRound].curRandomStakeIdx = randomGameMap[calRandomRound].curRandomStakeIdx.add(1);

       emit StakeIn(msg.sender,msg.value,calUpDownRound,calRandomRound);
    }



    function upDownLotteryFanalize()
        onlyOwner
        notHalted
        public
    {
        require(updownGameMap[curUpDownRound].openPrice != 0);
        require(updownGameMap[curUpDownRound].closePrice != 0);
        require(feeRatio > 0);

       //end time for this round
       uint endTime = gameStartTime.add(upDownLotteryTimeCycle.mul(curUpDownRound + 1));
       require(now>endTime);


        uint prizePercent = DIVISOR.sub(feeRatio);

        uint total =  updownGameMap[curUpDownRound].upAmount.add(updownGameMap[curUpDownRound].downAmount);
        uint winnerPrize = total.mul(prizePercent).div(DIVISOR);


        uint i;
        address sAddr;
        uint stake;
        uint gotPrize;

        if (updownGameMap[curUpDownRound].closePrice > updownGameMap[curUpDownRound].openPrice) {
            for (i=0;i<updownGameMap[curUpDownRound].upStakers.length;i++) {
                sAddr = updownGameMap[curUpDownRound].upStakers[i];
                stake = updownGameMap[curUpDownRound].stakeOfStaker[sAddr];
                gotPrize = winnerPrize.mul(stake).div(updownGameMap[curUpDownRound].upAmount);
                sAddr.transfer(gotPrize);

                emit UpDownBingGo(sAddr,gotPrize,curUpDownRound);
            }

        } else if (updownGameMap[curUpDownRound].closePrice > updownGameMap[curUpDownRound].openPrice) {
            for (i=0;i<updownGameMap[curUpDownRound].downStakers.length;i++) {
                sAddr = updownGameMap[curUpDownRound].downStakers[i];
                stake = updownGameMap[curUpDownRound].stakeOfStaker[sAddr];
                gotPrize = winnerPrize.mul(stake).div(updownGameMap[curUpDownRound].upAmount);
                sAddr.transfer(gotPrize);

                emit UpDownBingGo(sAddr,gotPrize,curUpDownRound);
            }
        } else {
            //return back stake after cut fee
            for (i=0;i<updownGameMap[curUpDownRound].upStakers.length;i++) {
                sAddr = updownGameMap[curUpDownRound].upStakers[i];
                stake = updownGameMap[curUpDownRound].stakeOfStaker[sAddr].mul(prizePercent).div(DIVISOR);
                sAddr.transfer(stake);
                emit UpDownBingGo(sAddr,gotPrize,curUpDownRound);
            }

            for (i=0;i<updownGameMap[curUpDownRound].downStakers.length;i++) {
                sAddr = updownGameMap[curUpDownRound].downStakers[i];
                stake = updownGameMap[curUpDownRound].stakeOfStaker[sAddr].mul(prizePercent).div(DIVISOR);
                sAddr.transfer(stake);
                emit UpDownBingGo(sAddr,gotPrize,curUpDownRound);
            }
        }

       curUpDownRound = curUpDownRound.add(1);
    }


    function randomLotteryFanalize()
        onlyOwner
        notHalted
        public
    {

       //end time for this round
       uint endTime = gameStartTime.add(randomLotteryTimeCycle.mul(curRandomRound + 1));
       require(now>endTime);
       require (winnerNum > 0);

        uint rb =  getRandomByBlockTime(now);
        uint len =  randomGameMap[curRandomRound].accStakeRange.length;
        uint totalRange = randomGameMap[curRandomRound].accStakeRange[len-1];

        address[] winner;
        uint i;
        uint expected;
        uint inputTime;

        //get winners
        for(i==0;i<winnerNum;i++) {
             expected = rb.mod(totalRange);
             uint idx = randomStakerfind(randomGameMap[curRandomRound].accStakeRange,expected);
             inputTime = randomGameMap[curRandomRound].stakingTime[idx];
             winner.push(randomGameMap[curRandomRound].stakerInfoMap[inputTime].staker);
             //use previous winner select next winner
             bytes32 hash = keccak256(rb, randomGameMap[curRandomRound].stakerInfoMap[inputTime].staker,inputTime);
             rb = uint(hash);
        }

        uint totalPrize = 0;
        //accumulate all of updown round
        for(i= randomGameMap[curRandomRound].startUpdownRound;i<curRandomRound;i++) {
            totalPrize = totalPrize.add(updownGameMap[i].upAmount.add(updownGameMap[i].downAmount));
        }
        //use fee ratio to get all of prize
        totalPrize = totalPrize.mul(feeRatio).div(DIVISOR);
        //add extra prize
        totalPrize = totalPrize.add(extraPrizeMap[curRandomRound]);

        uint winnerPrize = totalPrize.div(winnerNum);
        for(i==0;i<winnerNum;i++) {
            winner[i].transfer(winnerPrize);

            emit UpDownBingGo(winner[i],winnerPrize,curRandomRound);
        }

       curRandomRound = curRandomRound.add(1);
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

        updownLotteryStartRN = _startTime.div(_updownLtryTimeCycle);

        //other can be changed any time
        gameStartTime = _startTime;
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
        //only can change current round price
        uint calUpDownRound = now.div(upDownLotteryTimeCycle).sub(updownLotteryStartRN);
        if (_flag) {
            //set current round open price
            if (updownGameMap[calUpDownRound].openPrice == 0) {
                  address[]    memory  upStakers = new address[](1);
                  address[]    memory  downStakers = new address[](1);
                  updownGameMap[calUpDownRound] = UpDownGameItem(0,0,0,0,upStakers,downStakers,false);
            }
            updownGameMap[calUpDownRound].openPrice = _currentPriceIndex;

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

    //--------------------------------private method-----------------------------------
    function  randomStakerfind(uint[]accStakeRange ,uint target)
           private
           returns (uint)
    {
            uint left = 0;
            uint right = accStakeRange.length - 1;

            while(left <= right) {

                uint mid = (right + left) / 2;

                if (mid == accStakeRange.length - 1) {
                    return accStakeRange.length - 1;
                }

                if(accStakeRange[mid] <= target && accStakeRange[mid + 1] > target ) {
                    return mid;
                }  else if (accStakeRange[mid] < target) {
                    left = mid + 1;
                } else if (accStakeRange[mid] > target) {
                    right = mid - 1;
                }

            }

            return 0;
    }
////////////////////////////////////////////////random//////////////////////////////////////////////////////////
    bytes32 constant RANDOM_BY_EPID_SELECTOR = 0x7f07b9ab00000000000000000000000000000000000000000000000000000000;
    bytes32 constant RANDOM_BY_BLKTIME_SELECTOR = 0xdf39683800000000000000000000000000000000000000000000000000000000;
    bytes32 constant GET_EPOCHID_SELECTOR = 0x5303548b00000000000000000000000000000000000000000000000000000000;
    address constant PRECOMPILE_CONTRACT_ADDR = 0x262;
    function getRandomByEpochId(uint256 epochId) private view returns(uint256) {

        (uint256 result, bool success) = callWith32BytesReturnsUint256(
                                            PRECOMPILE_CONTRACT_ADDR,
                                            RANDOM_BY_EPID_SELECTOR,
                                            bytes32(epochId)
                                          );

        if (!success) {
            revert("ASSEMBLY_CALL_GET_BORROW_INTEREST_RATE_FAILED");
        }

        return result;
    }

    function getRandomByBlockTime(uint256 blockTime) private view returns(uint256) {

        (uint256 result, bool success) = callWith32BytesReturnsUint256(
                                                PRECOMPILE_CONTRACT_ADDR,
                                                RANDOM_BY_EPID_SELECTOR,
                                                bytes32(blockTime)
                                          );

        if (!success) {
            revert("ASSEMBLY_CALL_GET_BORROW_INTEREST_RATE_FAILED");
        }

        return result;
    }

    function getEpochId(uint256 blockTime) private view returns(uint256) {
         (uint256 result, bool success) = callWith32BytesReturnsUint256(
                                                PRECOMPILE_CONTRACT_ADDR,
                                                GET_EPOCHID_SELECTOR,
                                                bytes32(blockTime)
                                            );

        if (!success) {
            revert("ASSEMBLY_CALL_GET_BORROW_INTEREST_RATE_FAILED");
        }

        return result;
    }


   function callWith32BytesReturnsUint256(
        address to,
        bytes32 functionSelector,
        bytes32 param1
    )
        private
        view
        returns (uint256 result, bool success)
    {
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


}