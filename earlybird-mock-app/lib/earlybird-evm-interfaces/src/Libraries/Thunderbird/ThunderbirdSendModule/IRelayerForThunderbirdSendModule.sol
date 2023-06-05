// src/Interfaces/IRelayer/IRelayerForThunderbirdSendModule.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @author - Orb Labs
 * @title  - IRelayerForThunderbirdSendModule.sol
 * @notice - Interface for Thunderbird library's send module's relayer
 */
interface IRelayerForThunderbirdSendModule {
    /**
     * @dev - function returns the amount an oracle is willing to charge for passing a message
     * @param _app - Address of the application
     * @param _receiverChainId - uint256 indicating the receiver chain Id
     * @param _receiver - bytes array indicating the address of the receiver
     * @param _payload - bytes array containing message payload
     * @param _additionalParams - bytes array containing additional params application would like sent to the library.
     *                            For this library, it is the encoded address of the payment token. Empty for the native token.
     * @return isTokenAccepted - bool indicating whether the token passed in additionalParams is acceptable or not.
     * @return estimatedFee - uint256 indicating the estimatedFee
     */
    function getEstimatedFee(
        address _app,
        uint256 _receiverChainId,
        bytes memory _receiver,
        bytes memory _payload,
        bytes memory _additionalParams
    ) external view returns (bool isTokenAccepted, uint256 estimatedFee);

    /**
     * @dev - function returns an array of tokens that are accepted as fees by the oracle
     * @param _app - Address of the application
     * @param _receiverChainId - uint256 indicating the receiver chain Id
     * @param _receiver - bytes array indicating the address of the receiver
     * @param _payload - bytes array containing message payload
     * @return acceptedTokens - return array of address of tokens that it accepts.
     */
    function getAcceptedTokens(address _app, uint256 _receiverChainId, bytes memory _receiver, bytes memory _payload)
        external
        view
        returns (address[] memory acceptedTokens);

    /**
     * @dev - function returns whether a token is accepted as for fees or not.
     * @param _tokens - address of tokens we are inquirying about
     * @param _app - Address of the application
     * @param _receiverChainId - uint256 indicating the receiver chain Id
     * @param _receiver - bytes array indicating the address of the receiver
     * @param _payload - bytes array containing message payload
     * @return areAcceptedTokens - return array of address of tokens that it accepts.
     */
    function areTokensAccepted(
        address[] memory _tokens,
        address _app,
        uint256 _receiverChainId,
        bytes memory _receiver,
        bytes memory _payload
    ) external view returns (bool[] memory areAcceptedTokens);
}
