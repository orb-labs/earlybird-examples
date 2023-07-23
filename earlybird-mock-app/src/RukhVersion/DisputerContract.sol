// src/RukhVersion/DisputerContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DisputerContract {
    event DisputeVerdict(bytes32 indexed _disputedMsgProofHash, uint256 indexed _disputeVerdict);

    function disputeResolved(bytes32 _disputedMsgProofHash, uint256 _disputeVerdict) external {
        emit DisputeVerdict(_disputedMsgProofHash, _disputeVerdict);
    }
}
