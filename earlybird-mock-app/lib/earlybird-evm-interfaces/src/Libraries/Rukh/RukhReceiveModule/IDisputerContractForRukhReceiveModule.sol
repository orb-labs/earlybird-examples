// src/Libraries/Rukh/RukhReceiveModule/IDisputerContractForRukhReceiveModule.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @author - Orb Labs
 * @title  - IDisputerContractForRukhReceiverModule.sol
 * @notice - Interface for Rukh library's receive module's disputer contracts.
 *
 */
interface IDisputerContractForRukhReceiveModule {
    /**
     * @dev - function returns the amount an oracle is willing to charge for passing a message
     * @param _disputedMsgProofHash - bytes32 indicating the hash of the disputed msg proof.
     * @param _disputeVerdict - uint256 indicating the dispute verdict.
     */
    function disputeResolved(bytes32 _disputedMsgProofHash, uint256 _disputeVerdict) external;
}
