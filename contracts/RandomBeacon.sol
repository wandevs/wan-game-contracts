
contract RandomBeacon {

    bytes32 constant RANDOM_BY_EPID_SELECTOR = 0x7f07b9ab00000000000000000000000000000000000000000000000000000000;
    bytes32 constant RANDOM_BY_BLKTIME_SELECTOR = 0xdf39683800000000000000000000000000000000000000000000000000000000;
    bytes32 constant GET_EPOCHID_SELECTOR = 0x5303548b00000000000000000000000000000000000000000000000000000000;
    address constant PRECOMPILE_CONTRACT_ADDR = 0x262;


    function getRandomByBlockTime(uint256 blockTime) public view returns(uint256) {

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