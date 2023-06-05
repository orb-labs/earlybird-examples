// src/Libraries/Rukh/RukhReceiveModule/IRecsContractForRukhReceiveModule.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @author - Orb Labs
 * @title  - IRecsContractForRukhReceiveModule.sol
 * @notice - Interface for Rukh library's receive module's recommendation contracts.
 *           Recommendation contracts are called by the protocol to retrieve the app's
 *           recommended dispute time for a certain message, recommended relayer to
 *           deliver that msg, and the recommended revealed secret for passing that msg.
 */
interface IRecsContractForRukhReceiveModule {
    /**
     * @dev - function returns the amount an oracle is willing to charge for passing a message
     * @param _senderChainId - uint256 indicating the receiver chain Id
     * @param _sender - bytes array indicating the address of the receiver
     * @param _nonce - uint256 indicating the nonce
     * @param _payload - bytes array containing message payload
     * @return recommendedDisputeTime - uint256 indicating the app's recommended dispute period for this message.
     * @return recommendedDisputeResolutionExtension - uint256 indicating the app's recommended dispute resolution extension,
     * @return revealedMsgSecret - bytes32 indicating the app's revealed secret for this message.
     * @return recommendedRelayer - address indicating the app's recommended relayer for submitting the message.
     */
    function getAllRecs(uint256 _senderChainId, bytes memory _sender, uint256 _nonce, bytes memory _payload)
        external
        view
        returns (
            uint256 recommendedDisputeTime,
            uint256 recommendedDisputeResolutionExtension,
            bytes32 revealedMsgSecret,
            address recommendedRelayer
        );

    /**
     * @dev - function returns the amount an oracle is willing to charge for passing a message
     * @param _senderChainId - uint256 indicating the receiver chain Id
     * @param _sender - bytes array indicating the address of the receiver
     * @param _nonce - uint256 indicating the nonce
     * @param _payload - bytes array containing message payload
     * @return recRelayer - address indicating the app's recommended relayer for submitting the message.
     */
    function getRecRelayer(uint256 _senderChainId, bytes memory _sender, uint256 _nonce, bytes memory _payload)
        external
        view
        returns (address recRelayer);
}
