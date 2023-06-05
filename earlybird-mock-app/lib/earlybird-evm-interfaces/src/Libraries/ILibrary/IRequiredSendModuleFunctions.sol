// src/ILibrary/IRequiredSendModuleFunctions.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IRequiredModuleFunctions.sol";

/**
 * @author - Orb Labs
 * @title  - IRequiredSendModuleFunctions
 * @notice - Interface for required send module functions.
 *           These functions are required because they are called by the endpoint.
 */
interface IRequiredSendModuleFunctions is IRequiredModuleFunctions {
    /**
     * @dev - Function returns the estimate for sending a message.
     * @param _app - address of the application
     * @param _receiverChainId - uint256 indicating the receiver's chain Id
     * @param _receiver - bytes array indicating the address of the receiver
     *                    (bytes is used since the receiver can be on an EVM or non-EVM chain)
     * @param _payload - bytes array containing message payload
     * @param _additionalParams - bytes array containing additional params application would like
     *                            sent to the module. For this function, its the encoded address of the
     *                            token being used to pay the fee.
     * @return isTokenAccepted - bool indicating whether the token address passed in additionalParams is accepted or not.
     * @return estimatedFee - uint256 indicating the amount of the token that needed for the fee.
     */
    function getEstimatedFee(
        address _app,
        uint256 _receiverChainId,
        bytes memory _receiver,
        bytes memory _payload,
        bytes memory _additionalParams
    ) external view returns (bool isTokenAccepted, uint256 estimatedFee);

    /**
     * @dev - Function that allows endpoint to get an app's sending nonce if its not self-broadcasting.
     *        Each app has a different nonce for each receiver on each chain to which it sends messages.
     * @param _app - address of the application that has been sending the messages
     * @param _receiverChainId - uint256 indicating the id of the receiver's chain
     * @param _receiver - bytes array indicating the receiver's address
     */
    function getSendingNonce(address _app, uint256 _receiverChainId, bytes memory _receiver)
        external
        view
        returns (uint256);

    /**
     * @dev - Application-only function that allows the application to send message to its designated
     *        outbound msg module to be broadcasted if it is not self-broadcasting
     * @param _app - address of the application sending the message
     * @param _receiverChainId - uint256 indicating the id of the receiver's chain
     * @param _receiver - bytes array indicating the address of the receiver
     *                    (bytes is used since the receiver can be on an EVM or non-EVM chain)
     * @param _payload - bytes array containing the message payload to be delivered to the receiver
     * @param _additionalParams - bytes array containing additional params application would like passed to the module
     */
    function sendMessage(
        address _app,
        uint256 _receiverChainId,
        bytes memory _receiver,
        bytes memory _payload,
        bytes memory _additionalParams
    ) external payable;

    /**
     * @dev - Function returns an array of all the tokens accepted by the sending module as payment for fees
     * @param _app - address of the application sending the message
     * @param _receiverChainId - uint256 indicating the id of the receiver's chain
     * @param _receiver - bytes array indicating the address of the receiver
     * @param _payload - bytes array containing the message payload to be delivered to the receiver
     * @return acceptedTokens - array of addresses of the tokens that are accepted by the protocol
     *                          as fees for sending messages.
     */
    function getAcceptedTokensForSendingFees(
        address _app,
        uint256 _receiverChainId,
        bytes memory _receiver,
        bytes memory _payload
    ) external view returns (address[] memory acceptedTokens);
}
