// src/Endpoint/IEndpoint/IEndpointFunctionsForApps.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @author - Orb Labs
 * @title  - IEndpointFunctionsForApps
 * @notice - Interface for Endpoint functions only the application can call.
 */
interface IEndpointFunctionsForApps {
    /**
     * @dev - Function that allows application to select its send and receive module
     *        and set their initial configs
     * @param _libraryName - name of the library the application is selecting.
     * @param _sendModuleConfigs - bytes array containing encoded configs to be
     *                             passed to the send module on the applications behalf
     * @param _receiveModuleConfigs - bytes array containing encoded configs to be passed
     *                                to the receive module on the applications behalf
     * @return sendModule - address of the sendModule
     * @return receiveModule - address of the receiveModule
     */
    function setLibraryAndConfigs(
        string calldata _libraryName,
        bytes calldata _sendModuleConfigs,
        bytes calldata _receiveModuleConfigs
    ) external returns (address sendModule, address receiveModule);

    /**
     * @dev - Function that allows application to update its library's send module configs
     * @param _sendModuleConfigs - bytes array containing encoded configs to be passed to
     *                             the send module on the applications behalf
     */
    function updateSendModuleConfigs(bytes calldata _sendModuleConfigs) external;

    /**
     * @dev - Function that allows application to update its library's receive module configs
     * @param _receiveModuleConfigs - bytes array containing encoded configs to be passed
     *                                to the receive module on the applications behalf
     */
    function updateReceiveModuleConfigs(bytes calldata _receiveModuleConfigs) external;

    /**
     * @dev - Function that allows the application to send message to its designated library to be broadcasted
     *        if it is not self-broadcasting
     * @param _receiverChainId - uint256 indicating the id of the chain that is receiving the message
     * @param _receiver - bytes array indicating the address of the receiver.
     *                    (bytes is used since the receiver can be on an EVM or non-EVM chain)
     * @param _payload - bytes array containing the message payload to be delivered to the receiver
     * @param _additionalParams - bytes array containing additional params application would like to passed to the library.
     *                            May be used in the library to enable special functionality.
     */
    function sendMessage(
        uint256 _receiverChainId,
        bytes calldata _receiver,
        bytes calldata _payload,
        bytes calldata _additionalParams
    ) external payable;

    /**
     * @dev - Function allows anyone to retry delivering a failed message
     * @param _app - address of the app the message is being delivered to.
     * @param _senderChainId - uint256 indicating the id of the chain from which the sender is sending the message.
     * @param _sender - bytes indicating the address of the sender app
     *                  (bytes is used since the sender can be on an EVM or non-EVM chain)
     * @param _nonce - uint256 indicating the nonce or id of the failed message
     * @param _payload - bytes array containing the message payload to be delivered to the app
     */
    function retryDeliveryForFailedMessage(
        address _app,
        uint256 _senderChainId,
        bytes calldata _sender,
        uint256 _nonce,
        bytes calldata _payload,
        bytes calldata _additionalInfo
    ) external payable;
}
