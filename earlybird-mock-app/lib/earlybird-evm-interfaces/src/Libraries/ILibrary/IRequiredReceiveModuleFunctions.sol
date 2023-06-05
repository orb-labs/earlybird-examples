// src/ILibrary/IRequiredReceiveModuleFunctions.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IRequiredModuleFunctions.sol";

/**
 * @author - Orb Labs
 * @title  - IRequiredReceiveModuleFunctions
 * @notice - Interface for required receive module functions.
 *           These functions are mandatory because they are called by the Endpoint.
 */
interface IRequiredReceiveModuleFunctions is IRequiredModuleFunctions {
    /**
     * @dev - Function that allows the endpoint to get an applications receiveing nonce from the receive module.
     *        Each app has a different nonce for each sender on each chain from which it receives messages.
     * @param _app - address of the application that has been receiving the messages
     * @param _senderChainId - uint256 indicating the id of the sender's chain
     * @param _sender - bytes array indicating the sender's address
     */
    function getReceivingNonce(address _app, uint256 _senderChainId, bytes memory _sender)
        external
        view
        returns (uint256);

    /**
     * @dev - Function returns array of hashes of failed messages sent from sender on a senderChainId
     * @param _app - address of the app the message is being delivered to.
     * @param _senderChainId - uint256 indicating the id of the senderChain
     * @param _sender - bytes indicating the address of the sender
     *                  (bytes is used since the sender can be on an EVM or non-EVM chain)
     * @return hashesOfFailedMsgs - array of bytes32 containing the hashes of failed msgs payloads
     */
    function getFailedMessages(address _app, uint256 _senderChainId, bytes memory _sender)
        external
        view
        returns (bytes32[] memory hashesOfFailedMsgs);

    /**
     * @dev - Function returns fee caller must pay to receive module before they are able to retry
     *        delivering the failed message
     * @param _app - address of the app the message is being delivered to.
     * @param _senderChainId - uint256 indicating the id of the sender's chain
     * @param _sender - bytes indicating the address of the sender
     *                  (bytes is used since the sender can be on an EVM or non-EVM chain)
     * @param _nonce - uint256 indicating the index of the failed message in the array of failed messages
     * @return feeForFailedMessage - uint256 indicating the fee caller must pay to receive library before
     *                               they are able to retry delivering the failed message
     */
    function getFeeForFailedMessage(address _app, uint256 _senderChainId, bytes memory _sender, uint256 _nonce)
        external
        view
        returns (uint256 feeForFailedMessage);

    /**
     * @dev - Function allows anyone to retry delivering a failed message
     * @param _app - address of the app the message is being delivered to.
     * @param _senderChainId - uint256 indicating the sender's chain id
     * @param _sender - bytes indicating the address of the sender
     *                  (bytes is used since the sender can be an EVM or non-EVM chain)
     * @param _nonce - uint256 indicating the nonce or id of the failed message.
     * @param _payload - bytes array containing the message payload to be delivered to the app
     * @param _additionalInfo - bytes array containing additional information the library would
     *                          have delivered to the app.
     */
    function retryDeliveryForFailedMessage(
        address _app,
        uint256 _senderChainId,
        bytes memory _sender,
        uint256 _nonce,
        bytes memory _payload,
        bytes memory _additionalInfo
    ) external payable;
}
