// test/TestHelperContracts/RukhTestHelperContract/MockRecsContract.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

contract MockRecsContract {
    // Address of default receive relayer 1
    address public receiveDefaultRelayer;

    // Constructor hardcodes the relayer address.
    constructor(address _receiveDefaultRelayer) {
        receiveDefaultRelayer = _receiveDefaultRelayer;
    }

    function getAllRecs(
        uint256,
        bytes memory,
        uint256,
        bytes memory
    )
        external
        view
        returns (
            uint256 recommendedDisputeTime,
            uint256 recommendedDisputeResolutionExtension,
            bytes32 revealedMsgSecret,
            address recommendedRelayer
        )
    {
        recommendedDisputeTime = 10;
        recommendedDisputeResolutionExtension = 11;
        recommendedRelayer = receiveDefaultRelayer;
        revealedMsgSecret = keccak256(abi.encode(recommendedRelayer));
    }

    function getRecRelayer(uint256, bytes memory, uint256, bytes memory) external view returns (address recRelayer) {
        recRelayer = receiveDefaultRelayer;
    }
}
