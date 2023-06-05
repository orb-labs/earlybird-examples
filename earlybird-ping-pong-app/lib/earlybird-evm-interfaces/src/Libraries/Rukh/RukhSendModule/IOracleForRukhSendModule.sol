// src/Interfaces/IOracle/IOracleForRukhSendModule.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @author - Orb Labs
 * @title  - IOracleForRukhSendModule.sol
 * @notice - Interface for Rukh library's send module's oracle
 */
interface IOracleForRukhSendModule {
    /**
     * @dev - function returns the amount an oracle is willing to charge for passing a message
     * @param _app - address of the application
     * @param _receiverChainId - uint256 indicating the receiver chain Id
     * @param _receiver - bytes array indicating the address of the receiver
     * @param _payload - bytes array containing message payload
     * @param _additionalParams - bytes array containing additional params application would like sent to the library.
     *                            In this library, it is abi.encode(address feeToken, bool isOrderMsg).
     * @return isTokenAccepted - bool indicating whether the token passed in additionalParams is acceptable or not.
     * @return estimatedFee - uint256 indicating the estimatedFee
     */
    function getEstimatedFee(
        address _app,
        uint256 _receiverChainId,
        bytes calldata _receiver,
        bytes calldata _payload,
        bytes calldata _additionalParams
    ) external view returns (bool isTokenAccepted, uint256 estimatedFee);

    /**
     * @dev - function returns an array of tokens that are accepted as fees by the oracle
     * @param _app - address of the application
     * @param _receiverChainId - uint256 indicating the receiver chain Id
     * @param _receiver - bytes array indicating the address of the receiver
     * @param _payload - bytes array containing message payload
     * @return acceptedTokens - return array of address of tokens that it accepts.
     */
    function getAcceptedTokens(
        address _app,
        uint256 _receiverChainId,
        bytes calldata _receiver,
        bytes calldata _payload
    ) external view returns (address[] memory acceptedTokens);

    /**
     * @dev - function returns whether a token is accepted as for fees or not.
     * @param _tokens - address of tokens we are inquirying about
     * @param _app - address of the application
     * @param _receiverChainId - uint256 indicating the receiver chain Id
     * @param _receiver - bytes array indicating the address of the receiver
     * @param _payload - bytes array containing message payload
     * @return areAcceptedTokens - return array of address of tokens that it accepts.
     */
    function areTokensAccepted(
        address[] memory _tokens,
        address _app,
        uint256 _receiverChainId,
        bytes calldata _receiver,
        bytes calldata _payload
    ) external view returns (bool[] memory areAcceptedTokens);
}
