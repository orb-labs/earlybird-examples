// src/SendingOracle.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "../lib/earlybird-evm-interfaces/src/FeeCollector/IFeeCollector.sol";
import "../utils/TestToken.sol";

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
            nonNativeTokensToFeeObjects[acceptedTokensArray[i]] = NonNativeTokenFee(false, 0);
        }

        // Insert all the newAcceptedTokens
        for (uint256 i = 0; i < _newAcceptedTokens.length; i++) {
            nonNativeTokensToFeeObjects[_newAcceptedTokens[i]] = NonNativeTokenFee(true, _feeAmounts[i]);
        }

        acceptedTokensArray = _newAcceptedTokens;
    }

    function updateNativeTokenFee(bool _acceptNativeTokenForFees, uint256 _feeAmount) public {
        acceptsNativeToken = _acceptNativeTokenForFees;
        nativeTokenFeeAmount = _feeAmount;
    }

    function getEstimatedFee(
        address,
        uint256,
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
            (address feeToken, , ) = abi.decode(_additionalParams, (address, bool, uint256));

            if (feeToken == address(0)) {
                isTokenAccepted = acceptsNativeToken;
                estimatedFee = nativeTokenFeeAmount;
            } else {
                isTokenAccepted = nonNativeTokensToFeeObjects[feeToken].tokenAccepted;
                estimatedFee = nonNativeTokensToFeeObjects[feeToken].tokenFeeAmount;
            }
        }
    }

    function getAcceptedTokens(
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external view returns (address[] memory acceptedTokens) {
        // Figure out the count of tokens that are accepted.
        uint256 numberOfAcceeptedTokens = acceptedTokensArray.length;
        if (acceptsNativeToken == true) {
            numberOfAcceeptedTokens++;
        }

        // Create an array for them and migrate non-native tokens.
        acceptedTokens = new address[](numberOfAcceeptedTokens);
        for (uint256 i = 0; i < acceptedTokensArray.length; i++) {
            acceptedTokens[i] = acceptedTokensArray[i];
        }

        // Migrate the native token if applicable.
        if (acceptsNativeToken == true) {
            acceptedTokens[numberOfAcceeptedTokens - 1] = address(0);
        }
    }

    function areTokensAccepted(
        address[] memory _tokens,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external view returns (bool[] memory areAcceptedTokens) {
        areAcceptedTokens = new bool[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == address(0)) {
                areAcceptedTokens[i] = acceptsNativeToken;
            } else {
                areAcceptedTokens[i] = nonNativeTokensToFeeObjects[_tokens[i]].tokenAccepted;
            }
        }
    }
}
