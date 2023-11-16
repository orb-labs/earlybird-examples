// src/FeeCollector.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../lib/earlybird-evm-interfaces/src/FeeCollector/IFeeCollector.sol";

contract FeeCollector is IFeeCollector {
    struct NonNativeTokenFee {
        bool tokenAccepted;
        uint256 tokenFeeAmount;
    }

    bool public acceptsNativeToken;
    uint256 public nativeTokenFeeAmount;
    mapping(address => NonNativeTokenFee) public nonNativeTokensToFeeObjects;
    address[] public acceptedTokensArray;

    receive() external payable {}

    function updateNonNativeTokenAcceptedForFees(
        address[] calldata _newAcceptedTokens,
        uint256[] calldata _feeAmounts
    ) public {
        // Remove all the acceptedTokens
        for (uint256 i = 0; i < acceptedTokensArray.length; i++) {
            nonNativeTokensToFeeObjects[
                acceptedTokensArray[i]
            ] = NonNativeTokenFee(false, 0);
        }

        // Insert all the newAcceptedTokens
        for (uint256 i = 0; i < _newAcceptedTokens.length; i++) {
            nonNativeTokensToFeeObjects[
                _newAcceptedTokens[i]
            ] = NonNativeTokenFee(true, _feeAmounts[i]);
        }

        acceptedTokensArray = _newAcceptedTokens;
    }

    function updateNativeTokenFee(
        bool _acceptNativeTokenForFees,
        uint256 _feeAmount
    ) public {
        acceptsNativeToken = _acceptNativeTokenForFees;
        nativeTokenFeeAmount = _feeAmount;
    }

    function getEstimatedFeeForDeliveredMessage(
        address _receiverApp,
        bytes32 _senderInstanceId,
        bytes calldata _sender,
        bytes calldata _payload,
        bytes calldata _additionalParams
    ) external view returns (bool isTokenAccepted, uint256 feeEstimate) {
        isTokenAccepted=true;
        feeEstimate=0;
    }

    function getEstimatedFeeForSendingMsg(
        address,
        bytes32,
        bytes calldata,
        bytes calldata,
        bytes calldata _additionalParams
    ) external view returns (bool isTokenAccepted, uint256 estimatedFee) {
        if (_additionalParams.length == 0) {
            // Pay fee in native
            isTokenAccepted = acceptsNativeToken;
            estimatedFee = nativeTokenFeeAmount;
        } else {
            // Pay fee in token specified in _additionalParams
            (address feeToken, , ) = abi.decode(
                _additionalParams,
                (address, bool, uint256)
            );

            if (feeToken == address(0)) {
                isTokenAccepted = acceptsNativeToken;
                estimatedFee = nativeTokenFeeAmount;
            } else {
                isTokenAccepted = nonNativeTokensToFeeObjects[feeToken]
                    .tokenAccepted;
                estimatedFee = nonNativeTokensToFeeObjects[feeToken]
                    .tokenFeeAmount;
            }
        }
    }

    function getAcceptedTokens(
        address,
        bytes32,
        bytes calldata,
        bytes calldata
    ) external view returns (address[] memory acceptedTokens) {
        // Figure out the count of tokens that are accepted.
        uint256 numberOfAcceptedTokens = acceptedTokensArray.length;
        if (acceptsNativeToken == true) {
            numberOfAcceptedTokens++;
        }

        // Create an array for them and migrate non-native tokens.
        acceptedTokens = new address[](numberOfAcceptedTokens);
        for (uint256 i = 0; i < acceptedTokensArray.length; i++) {
            acceptedTokens[i] = acceptedTokensArray[i];
        }

        // Migrate the native token if applicable.
        if (acceptsNativeToken == true) {
            acceptedTokens[numberOfAcceptedTokens - 1] = address(0);
        }
    }

    function areTokensAccepted(
        address[] memory _tokens,
        address,
        bytes32,
        bytes calldata,
        bytes calldata
    ) external view returns (bool[] memory areAcceptedTokens) {
        areAcceptedTokens = new bool[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == address(0)) {
                areAcceptedTokens[i] = acceptsNativeToken;
            } else {
                areAcceptedTokens[i] = nonNativeTokensToFeeObjects[_tokens[i]]
                    .tokenAccepted;
            }
        }
    }

    function getBookmarkedFee(address _receiverApp, address _feeToken, bytes32 _msgHash)
        external
        view
        returns (bool isTokenAccepted, uint256 fee)
    {}

    function feePaidToSendMsg(
        address _app,
        bytes32 _receiverInstanceId,
        bytes calldata _receiver,
        bytes calldata _payload,
        bytes calldata _additionalParams
    ) external {}

    function feePaidForDeliveredMsg(
        address _receiverApp,
        bytes32 _senderInstanceId,
        bytes calldata _sender,
        bytes calldata _payload,
        bytes calldata _additionalParams
    ) external {}

    function bookmarkFeesForDeliveredMessage(
        bytes32 _msgHash,
        address _receiverApp,
        bytes32 _senderInstanceId,
        bytes calldata _sender,
        uint256 _nonce,
        bytes calldata _payload,
        bytes calldata _additionalParams
    ) external returns (bool feeBookmarked) {}

    function bookmarkedFeesPaid(address _receiverApp, address _feeToken, bytes32 _msgHash) external {}
}
