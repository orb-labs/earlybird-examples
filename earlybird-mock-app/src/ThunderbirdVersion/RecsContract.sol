// src/ThunderbirdVersion/RecsContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

contract RecsContract {
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
    ) external view returns (bytes32 revealedMsgSecret, address recommendedRelayer) {
        recommendedRelayer = receiveDefaultRelayer;
        revealedMsgSecret = keccak256(abi.encode(recommendedRelayer));
    }

    function getRecRelayer(uint256, bytes memory, uint256, bytes memory) external view returns (address recRelayer) {
        recRelayer = receiveDefaultRelayer;
    }
}
