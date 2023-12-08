// src/MagiclaneMockApp.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import "../utils/TestFT.sol";
import "../utils/TestNFT.sol";
import "../utils/TestSFT.sol";
import "magiclane/src/magiclaneReceiver/IMagiclaneReceiver.sol";
import "magiclane/src/magiclaneSpoke/IMagiclaneSpokeEndpoint/IMagiclaneSpokeEndpointSendingFunctions.sol";
import "magiclane/src/magiclaneSharedLibrary.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract MagiclaneMockApp is Ownable, IMagiclaneReceiver {
    // to facilitate safe transfers of ERC20s
    using SafeERC20 for IERC20;

    // Endpoint address of the magiclane protcol
    address public magiclaneEndpoint;

    string[] public allSentMessages;
    string[] public allReceivedMessages;

    constructor(address _magiclaneEndpoint) {
        magiclaneEndpoint = _magiclaneEndpoint;
    }

    // Modifier to ensure only the magiclaneEndpoint can call a function
    modifier onlyMagiclaneEndpoint() {
        require(msg.sender == magiclaneEndpoint);
        _;
    }

    function getFeeEstimateForSendTokensRequest(
        IMagiclaneSpokeEndpointSendingFunctions.FTObjectForSendFunctions[] calldata _fungibleTokens,
        IMagiclaneSpokeEndpointSendingFunctions.NFTObjectForSendFunctions[] calldata _nonFungibleTokens,
        IMagiclaneSpokeEndpointSendingFunctions.SFTObjectForSendFunctions[] calldata _semiFungibleTokens,
        bytes calldata _message,
        PayoutAndRefund.Info calldata _info,
        Gas.Data calldata _gasOnHub,
        Gas.Data calldata _gasOnDest
    ) public view returns (bool isTokenAccepted, uint256 estimatedFee) {
        require(
            _fungibleTokens.length > 0 || _nonFungibleTokens.length > 0 || _semiFungibleTokens.length > 0,
            "No tokens to send"
        );

        require(instanceIdToAppAddress[_info.instanceId] != address(0), "instance not found");

        bytes memory payload = abi.encode(_message, _info);
        PayoutAndRefund.Info memory info = PayoutAndRefund.Info(
            _info.instanceId, abi.encode(instanceIdToAppAddress[_info.instanceId]), _info.refundAddress
        );

        IMagiclaneSpokeEndpointSendingFunctions.SendTokensRequest memory sendTokensRequest =
        IMagiclaneSpokeEndpointSendingFunctions.SendTokensRequest(
            false, // collectTokensThroughHook
            address(this), // placehloder for tokenSource
            _fungibleTokens,
            _nonFungibleTokens,
            _semiFungibleTokens,
            payload,
            info,
            _gasOnHub,
            _gasOnDest
        );

        return IMagiclaneSpokeEndpointSendingFunctions(magiclaneEndpoint).getFeeEstimateForSendTokensRequest(
            sendTokensRequest
        );
    }

    function sendTokens(
        IMagiclaneSpokeEndpointSendingFunctions.FTObjectForSendFunctions[] calldata _fungibleTokens,
        IMagiclaneSpokeEndpointSendingFunctions.NFTObjectForSendFunctions[] calldata _nonFungibleTokens,
        IMagiclaneSpokeEndpointSendingFunctions.SFTObjectForSendFunctions[] calldata _semiFungibleTokens,
        bytes calldata _message,
        Gas.Data calldata _gasOnHub,
        Gas.Data calldata _gasOnDest,
        address _receiver,
        bytes32 _destinationMagiclaneSpokeId,
        address _destinationMockAppAddress
    ) external {
        require(
            _fungibleTokens.length > 0 || _nonFungibleTokens.length > 0 || _semiFungibleTokens.length > 0,
            "No tokens to send"
        );

        bytes memory payload = abi.encode(_message, _receiver);
        PayoutAndRefund.Info memory info = PayoutAndRefund.Info(
            _destinationMagiclaneSpokeId, abi.encode(_destinationMockAppAddress), abi.encode(_receiver)
        );

        IMagiclaneSpokeEndpointSendingFunctions.SendTokensRequest memory sendTokensRequest =
        IMagiclaneSpokeEndpointSendingFunctions.SendTokensRequest(
            false, // collectTokensThroughHook
            address(this), // placehloder for tokenSource
            _fungibleTokens,
            _nonFungibleTokens,
            _semiFungibleTokens,
            payload,
            info,
            _gasOnHub,
            _gasOnDest
        );

        // Check if token is accepted by the protocol for fees
        (bool isTokenAccepted,) = IMagiclaneSpokeEndpointSendingFunctions(magiclaneEndpoint)
            .getFeeEstimateForSendTokensRequest(sendTokensRequest);

        require(isTokenAccepted, "Fee token is not accepted by oracle and relayer");

        // approve fts to be sent
        for (uint256 i = 0; i < _fungibleTokens.length; i++) {
            IERC20(_fungibleTokens[i].tokenAddress).approve(magiclaneEndpoint, _fungibleTokens[i].amount);
        }

        // approve nfts to be sent
        for (uint256 i = 0; i < _nonFungibleTokens.length; i++) {
            IERC721((_nonFungibleTokens[i].tokenAddress)).approve(magiclaneEndpoint, _nonFungibleTokens[i].id);
        }

        // approve sfts to be sent
        for (uint256 i = 0; i < _semiFungibleTokens.length; i++) {
            IERC1155(_semiFungibleTokens[i].tokenAddress).setApprovalForAll(magiclaneEndpoint, true);
        }

        // save the message that is being sent
        if (_message.length > 0) {
            allSentMessages.push(string(_message));
        }

        IMagiclaneSpokeEndpointSendingFunctions(magiclaneEndpoint).sendTokens(sendTokensRequest);
    }

    function receiveMsg(bytes32, bytes calldata, uint256, bytes calldata _payload, bytes calldata)
        external
        onlyMagiclaneEndpoint
    {
        allReceivedMessages.push(string(_payload));
    }

    function receiveTokenPayouts(
        bytes32,
        bytes calldata,
        IMagiclaneReceiver.Tokens calldata _tokens,
        bytes calldata _payload
    ) external onlyMagiclaneEndpoint {
        (bytes memory message, address payoutAddress) = abi.decode(_payload, (bytes, address));
        allReceivedMessages.push(string(message));

        // trasnfer fts to the final destination
        for (uint256 i = 0; i < _tokens.fungibleTokens.length; i++) {
            IERC20(_tokens.fungibleTokens[i].token).safeTransferFrom(
                address(this), payoutAddress, _tokens.fungibleTokens[i].amount
            );
        }

        // trasnfer nfts to the final destination
        for (uint256 i = 0; i < _tokens.nonFungibleTokens.length; i++) {
            IERC721(_tokens.nonFungibleTokens[i].token).safeTransferFrom(
                address(this), payoutAddress, _tokens.nonFungibleTokens[i].id
            );
        }

        // trasnfer sfts to the final destination
        for (uint256 i = 0; i < _tokens.semiFungibleTokens.length; i++) {
            IERC1155(_tokens.semiFungibleTokens[i].token).safeTransferFrom(
                address(this), payoutAddress, _tokens.semiFungibleTokens[i].id, _tokens.semiFungibleTokens[i].amount, ""
            );
        }
    }

    function getAllSentMessages() external view returns (string[] memory) {
        return allSentMessages;
    }

    function getLastTwoReceivedMessages() external view returns (string[] memory) {
        string[] memory lastTwoMessages = new string[](2);
        if (allReceivedMessages.length == 0) {
            lastTwoMessages[0] = "";
            lastTwoMessages[1] = "";
        } else if (allReceivedMessages.length == 1) {
            lastTwoMessages[0] = allReceivedMessages[0];
            lastTwoMessages[1] = "";
        } else {
            uint256 receivedMessageSize = allReceivedMessages.length;
            lastTwoMessages[0] = allReceivedMessages[receivedMessageSize - 2];
            lastTwoMessages[1] = allReceivedMessages[receivedMessageSize - 1];
        }

        return lastTwoMessages;
    }

    function getAllReceivedMessages() external view returns (string[] memory) {
        return allReceivedMessages;
    }

    function mintTestFT(address _tokenAddress, uint256 _amount) public {
        TestFT(_tokenAddress).mint(address(this), _amount);
    }

    function mintTestNFT(address _tokenAddress, uint256 _tokenId) public {
        TestNFT(_tokenAddress).mint(address(this), _tokenId);
    }

    function mintSFT(address _tokenAddress, uint256 _tokenId, uint256 _amount) public {
        TestSFT(_tokenAddress).mint(address(this), _tokenId, _amount);
    }
}
