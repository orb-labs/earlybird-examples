// src/ThunderbirdVersion/RecsContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

contract RecsContract {
    // Address of default receive relayer 1
    address public defaultRelayer;

    // Constructor hardcodes the relayer address.
    constructor(address _defaultRelayer) {
        defaultRelayer = _defaultRelayer;
    }

    function getAllRecs(
        bytes32,
        bytes memory,
        uint256,
        bytes memory
    )
        external
        view
        returns (bytes32 revealedMsgSecret, address recommendedRelayer)
    {
        recommendedRelayer = defaultRelayer;
        revealedMsgSecret = keccak256(abi.encode(recommendedRelayer));
    }

    function getRecRelayer(
        bytes32,
        bytes memory,
        uint256,
        bytes memory
    ) external view returns (address recRelayer) {
        recRelayer = defaultRelayer;
    }
}
