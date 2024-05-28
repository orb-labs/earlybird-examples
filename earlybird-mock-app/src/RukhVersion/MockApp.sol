// src/RukhVersion/MockApp.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../utils/TestToken.sol";
import "earlybird/src/EarlybirdMsgReceiver/IEarlybirdMsgReceiver.sol";
import "earlybird/src/EarlybirdEndpoint/IEarlybirdEndpointFunctionsForApps.sol";
import "earlybird/src/EarlybirdEndpoint/IEarlybirdEndpointGetFunctions.sol";
import "earlybird/src/EarlybirdEndpoint/IEarlybirdEndpoint.sol";
import "openzeppelin-contracts/access/Ownable.sol";

contract MockApp is IEarlybirdMsgReceiver, Ownable {
    // name of the library that the application is using
    string public libraryName = "Rukh";

    // Endpoint address
    address public endpoint;

    // The address of the library's receive module
    address public libraryReceiveModule;

    // The default token for paying fees
    address public defaultFeeToken;

    // Bool indicating whether messages should be delivered directly from library to app as opposed to going though the relayer.
    // Setting it to true reduces gas but application must be configured to receive messages from the library's receive module.
    bool private directMsgsEnabled = true;

    string[] public allSentMessages;
    string[] public allReceivedMessages;

    // Constructor hardcodes the endpoint address.
    constructor(address _endpoint, address _defaultFeeToken) {
        endpoint = _endpoint;
        defaultFeeToken = _defaultFeeToken;
    }

    // Modifier to ensure only the endpoint (if direct messages is disabled) or library receive module (if enabled) can call a function
    modifier onlyEndpointOrLibraryReceiveModule() {
        if (!directMsgsEnabled) {
            require(msg.sender == endpoint);
        } else {
            require(msg.sender == libraryReceiveModule);
        }
        _;
    }

    function setLibraryAndConfigs(
        string memory _libraryName,
        bytes memory _appConfigForSending,
        bytes memory _appConfigForReceiving
    ) external {
        IEarlybirdEndpointFunctionsForApps(endpoint).setLibraryAndConfigs(
            _libraryName, _appConfigForSending, _appConfigForReceiving
        );
        (,, libraryReceiveModule,) = IEarlybirdEndpointGetFunctions(endpoint).getLibraryInfo(libraryName);
        libraryName = _libraryName;
    }

    function updateAppConfigForSending(bytes memory _appConfigForSending) external {
        IEarlybirdEndpointFunctionsForApps(endpoint).updateAppConfigForSending(_appConfigForSending);
    }

    function updateAppConfigForReceiving(bytes memory _appConfigForReceiving) external {
        IEarlybirdEndpointFunctionsForApps(endpoint).updateAppConfigForReceiving(_appConfigForReceiving);
    }

    function sendMessage(
        bytes32 _receiverInstanceId,
        bytes memory _receiver,
        string memory _message,
        bytes memory _additionalParams
    ) external {
        allSentMessages.push(_message);
        bytes memory payload = abi.encode(_message);

        // Check how much it costs to send messages with the default token
        (bool isTokenAccepted, uint256 feeEstimated) = IEarlybirdEndpointGetFunctions(endpoint)
            .getEstimatedFeeForSending(address(this), _receiverInstanceId, _receiver, payload, _additionalParams);

        // Check that the fee token we indicated is accepted
        require(isTokenAccepted, "Default fee token is not accepted by oracle and relayer");

        // Get protocol fee and add it to token fees if
        (bool isProtocolFeeOn, address protocolFeeToken, uint256 protocolFeeAmount) = IEarlybirdEndpointGetFunctions(
            endpoint
        ).getProtocolFee(address(this), uint256(IEarlybirdEndpoint.ModuleType.SEND));

        uint256 totalNativeTokenFee;
        if (!isProtocolFeeOn) {
            totalNativeTokenFee = _handleSendingAndProtocolFees(feeEstimated, 0, address(0));
        } else {
            totalNativeTokenFee = _handleSendingAndProtocolFees(feeEstimated, protocolFeeAmount, protocolFeeToken);
        }

        IEarlybirdEndpointFunctionsForApps(endpoint).sendMessage{value: totalNativeTokenFee}(
            _receiverInstanceId, _receiver, payload, _additionalParams
        );
    }

    function receiveMsg(bytes32, bytes memory, uint256, bytes memory _payload, bytes memory)
        external
        onlyEndpointOrLibraryReceiveModule
    {
        string memory message = abi.decode(_payload, (string));
        allReceivedMessages.push(message);
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

    function mintTestToken(address _tokenAddress, uint256 _amount) public {
        TestToken(_tokenAddress).mint(_amount);
    }

    function approveTestTokenToEndpoint(address _tokenAddress, uint256 _amount) public {
        TestToken(_tokenAddress).approve(endpoint, _amount);
    }

    // Private function that handles the checks, calculations and approvals of sending and protocol fees.
    function _handleSendingAndProtocolFees(uint256 _sendingFee, uint256 _protocolFee, address _protocolFeeToken)
        private
        returns (uint256 totalNativeTokenFee)
    {
        if ((_protocolFeeToken == defaultFeeToken) && (defaultFeeToken == address(0))) {
            // Both fees are in native tokens
            totalNativeTokenFee = _sendingFee + _protocolFee;
            require(
                address(this).balance >= totalNativeTokenFee,
                "PingPong: Default fee token balance is less than estimatedFee + protocolFee"
            );
        } else if (defaultFeeToken == address(0)) {
            // Sending Fee is in native token but the protocol fee is in an ERC20
            totalNativeTokenFee = _sendingFee;
            require(
                address(this).balance >= totalNativeTokenFee,
                "PingPong: Default fee token balance is less than estimatedFee"
            );
            require(
                ERC20(_protocolFeeToken).balanceOf(address(this)) >= _protocolFee,
                "PingPong: Default fee token balance is less than protocolFee"
            );
            ERC20(_protocolFeeToken).approve(endpoint, _protocolFee);
        } else if (_protocolFeeToken == address(0)) {
            // Protocol Fee is in native token but the sending fee is in an ERC20
            totalNativeTokenFee = _protocolFee;
            require(
                address(this).balance >= totalNativeTokenFee,
                "PingPong: Default fee token balance is less than protocolFee"
            );
            require(
                ERC20(defaultFeeToken).balanceOf(address(this)) >= _sendingFee,
                "PingPong: Default fee token balance is less than estimatedFee"
            );
            ERC20(defaultFeeToken).approve(endpoint, _sendingFee);
        } else if ((_protocolFeeToken == defaultFeeToken) && (defaultFeeToken != address(0))) {
            // Both fees are in the same ERC20
            uint256 totalERC20Fee = _sendingFee + _protocolFee;
            require(
                ERC20(defaultFeeToken).balanceOf(address(this)) >= totalERC20Fee,
                "PingPong: Default fee token balance is less than estimatedFee + protocolFee"
            );
            ERC20(defaultFeeToken).approve(endpoint, totalERC20Fee);
        } else if (
            (_protocolFeeToken != defaultFeeToken) && (defaultFeeToken != address(0))
                && (_protocolFeeToken != address(0))
        ) {
            // Fees are listed in two different ERC20 tokens
            require(
                ERC20(defaultFeeToken).balanceOf(address(this)) >= _sendingFee,
                "PingPong: Default fee token balance is less than estimatedFee"
            );
            require(
                ERC20(_protocolFeeToken).balanceOf(address(this)) >= _protocolFee,
                "PingPong: Default fee token balance is less than protocolFee"
            );
            ERC20(defaultFeeToken).approve(endpoint, _sendingFee);
            ERC20(_protocolFeeToken).approve(endpoint, _protocolFee);
        }
    }
}
