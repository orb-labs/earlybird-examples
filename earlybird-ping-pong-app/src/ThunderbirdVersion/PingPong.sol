// src/ThunderbirdVersion/PingPong.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Note: Contracts needs to be funded with token being used for message payment.abi

// This app send messages back and forth between chains until it runs out of money to send
// messages or is paused.

// The app demonstrates:
// 1. The ability for applications to select and configure the libraries they will like to use for sending messages.
// 2. The ability to send messages in many different ways using earlybird (i.e. fees paid in any token accepted by oracle and relayer,  messages delivered in ordered fashion, messages delivered in unordered fashion)
// 3. The ability to check and estimate the fee for sending messages in any currency.
// 4. The ability to recieve messages with recommened values desired by app (i.e. recommended dispute times, recommended revealed secrets, recommended relayers)

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";
import "earlybird/src/IReceiver/IReceiver.sol";
import "earlybird/src/Endpoint/IEndpoint/IEndpoint.sol";
import "earlybird/src/Endpoint/IEndpoint/IEndpointFunctionsForApps.sol";
import "earlybird/src/Endpoint/IEndpoint/IEndpointGetFunctions.sol";
import "earlybird/src/Libraries/Thunderbird/ThunderbirdReceiveModule/IRecsContractForThunderbirdReceiveModule.sol";

contract PingPong is IReceiver, IRecsContractForThunderbirdReceiveModule, Ownable, Pausable {
    // name of the library that the application is using
    string public libraryName = "Thunderbird V1";

    // Endpoint address
    address public endpoint;

    // The address of the library's receive module
    address public libraryReceiveModule;

    // The default token for paying fees
    address public defaultFeeToken;

    // Address of the recommendations contract
    address public recsContract;

    // Address of default receive relayer 1
    address public receiveDefaultRelayer;

    // Address of backup receive relayer 2
    address public receiveBackupRelayer;

    // Whether app wants to self broadcast messages or not. If app decides to self broadcast,
    // the burden of paying the oracle and relayer as well as ordering its nonces rest of the developer.
    bool private isSelfBroadcasting = false;

    // Bool indicating whether the endpoint should broadcast submitted message proofs or not.
    // Setting it to false reduces gas but increases relayer and oracle implementation complexity.
    bool private emitMsgProofs = false;

    // Bool indicating whether messages should be delivered directly from library to app as opposed to going though the relayer.
    // Setting it to true reduces gas but application must be configured to receive messages from the library's receive module.
    bool private directMsgsEnabled = false;

    // Bool indicating whether message delivery for the application is paused on the library level or not.
    bool private msgDeliveryPaused = false;

    // event emitted during every ping call
    event Ping(uint pings);

    // Constructor hardcodes the endpoint address.
    constructor(
        address _endpoint,
        address _sendingOracleAddress,
        address _sendingRelayerAddress,
        address _receivingOracle,
        address _receiveDefaultRelayer,
        address _receiveBackupRelayer
    ) {
        endpoint = _endpoint;
        recsContract = address(this);
        receiveDefaultRelayer = _receiveDefaultRelayer;
        receiveBackupRelayer = _receiveBackupRelayer;

        bytes memory sendModuleConfigs = abi.encode(isSelfBroadcasting, _sendingOracleAddress, _sendingRelayerAddress);
        bytes memory receiveModuleConfigs = abi.encode(
            _receivingOracle,
            _receiveDefaultRelayer,
            recsContract,
            emitMsgProofs,
            directMsgsEnabled,
            msgDeliveryPaused
        );

        IEndpointFunctionsForApps(endpoint).setLibraryAndConfigs(libraryName, sendModuleConfigs, receiveModuleConfigs);
        (,, libraryReceiveModule, ) = IEndpointGetFunctions(endpoint).getLibraryInfo(libraryName);
    }

    // Modifier used for the receive function to endure that the only address
    // that can call the function is the endpoint
    modifier onlyEndpointOrLibraryReceiveModule() {
        if (!directMsgsEnabled) {
            require(msg.sender == endpoint);
        } else {
            require(msg.sender == libraryReceiveModule);
        }
        _;
    }

    // Pausing ping pong match
    function pauseMatch(bool status) external {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

    // Updates the send module configs of the earlybird library we are using
    function updateAppConfigForSending(
        bool _isSelfBroadcasting,
        address _sendingOracleAddress,
        address _sendingRelayerAddress
    ) external onlyOwner {
        isSelfBroadcasting = _isSelfBroadcasting;
        bytes memory sendModuleConfigs = abi.encode(_isSelfBroadcasting, _sendingOracleAddress, _sendingRelayerAddress);
        IEndpointFunctionsForApps(endpoint).updateAppConfigForSending(sendModuleConfigs);
    }

    function updateAppConfigForReceiving(
        address _receivingOracle,
        address payable _receivingDefaultRelayer,
        address _recsContract,
        bool _emitMsgProofs,
        bool _directMsgsEnabled,
        bool _msgDeliveryPaused
    ) external onlyOwner {
        recsContract = _recsContract;
        emitMsgProofs = _emitMsgProofs;
        // looks like a bug here
        directMsgsEnabled = directMsgsEnabled;
        msgDeliveryPaused = _msgDeliveryPaused;
        receiveDefaultRelayer = _receivingDefaultRelayer;

        bytes memory receiveModuleConfigs = abi.encode(
            _receivingOracle,
            _receivingDefaultRelayer,
            _recsContract,
            _emitMsgProofs,
            _directMsgsEnabled,
            _msgDeliveryPaused
        );

        IEndpointFunctionsForApps(endpoint).updateAppConfigForReceiving(receiveModuleConfigs);
    }

    function updateDefaultFeeToken(address _feeToken) external onlyOwner {
        defaultFeeToken = _feeToken; // Set to zero address if you want to use native token for fees.
    }

    function approveTokenToEndpoint(address _tokenAddress, uint256 _amount) public onlyOwner {
        ERC20(_tokenAddress).approve(endpoint, _amount);
    }

    function getFees(bytes32 _dstChainId, address _dstAddress, uint256 pings) public returns (uint256) {
        bytes memory payload = abi.encode(pings);
        bool isOrderedMsg = true;
        bytes memory additionalParams = abi.encode(defaultFeeToken, isOrderedMsg, 500000);
        bytes memory _dst = abi.encode(_dstAddress);
        
        (bool isTokenAccepted, uint256 feeEstimated) = IEndpointGetFunctions(endpoint).getEstimatedFeeForSending(
            address(this),
            _dstChainId,
            _dst,
            payload,
            additionalParams
        );

        // Check that the fee token we indicated is accepted
        require(isTokenAccepted, "PingPong: Default fee token is not accepted by oracle and relayer");

        // Get protocol fee and add it to token fees if
        (bool isProtocolFeeOn, address protocolFeeToken, uint256 protocolFeeAmount) = IEndpointGetFunctions(endpoint)
            .getProtocolFee(address(this), uint256(IEndpoint.ModuleType.SEND));

        uint256 totalNativeTokenFee;
        if (!isProtocolFeeOn) {
            totalNativeTokenFee = _handleSendingAndProtocolFees(feeEstimated, 0, address(0));
        } else {
            totalNativeTokenFee = _handleSendingAndProtocolFees(feeEstimated, protocolFeeAmount, protocolFeeToken);
        }
        return totalNativeTokenFee * pings;
    }

    function sendPing(bytes32 _dstChainId, address   _dstAddress, uint256 pings, uint256 totalNativeTokenFee) private {
        bytes memory payload = abi.encode(pings);
        bool isOrderedMsg = true;
        bytes memory additionalParams = abi.encode(defaultFeeToken, isOrderedMsg, 500000);
        bytes memory _dst = abi.encode(_dstAddress);

        IEndpointFunctionsForApps(endpoint).sendMessage{value: totalNativeTokenFee}(
            _dstChainId,
            _dst,
            payload,
            additionalParams
        );

        emit Ping(pings);
    }


    function ping(bytes32 _dstChainId, address _dstAddress, uint256 pings) public whenNotPaused payable {
        uint256 totalNativeTokenFee = this.getFees(_dstChainId, _dstAddress, pings);
        require(totalNativeTokenFee <= msg.value, "Too many pings, too little coin, friend");
        sendPing(_dstChainId, _dstAddress, pings, totalNativeTokenFee);
    }


    function receiveMsg(
        bytes32 _senderChainId,
        bytes memory _sender,
        uint256 _nonce,
        bytes memory _payload,
        bytes memory _additionalInfo
    ) external onlyEndpointOrLibraryReceiveModule {
        // Get the recommended values for a message like this.
        (bytes32 revealedMsgSecret, address recommendedRelayer) = IRecsContractForThunderbirdReceiveModule(recsContract)
            .getAllRecs(_senderChainId, _sender, _nonce, _payload);

        // Get the supplied values
        (bytes32 suppliedMsgSecret, address relayer) = abi.decode(_additionalInfo, (bytes32, address));

        // Revert if they are not
        require(
            (revealedMsgSecret == suppliedMsgSecret) && (recommendedRelayer == relayer),
            "PingPong: Msg Delivered with wrong rec values"
        );

        // Extract sending address and chain
        address sendBackAddress = abi.decode(_sender, (address));

        // increase the number of pings
        uint256 pings = abi.decode(_payload, (uint256));
        // Call the ping function again.
        if (pings > 0)  { 
            ping(_senderChainId, sendBackAddress, pings--); 
        }
    }

    function getAllRecs(
        bytes32,
        bytes memory,
        uint256,
        bytes memory _payload
    ) public view returns (bytes32 revealedMsgSecret, address payable recommendedRelayer) {
        // revealedSecret is the hash of the payload
        revealedMsgSecret = keccak256(_payload);

        // RecommendedRelayer is the default relayer for every odd ping and the backup relayer for even pings
        uint256 pingCount = abi.decode(_payload, (uint256));
        if (pingCount % 2 == 1) recommendedRelayer = payable(receiveDefaultRelayer);
        else recommendedRelayer = payable(receiveBackupRelayer);
    }

    function getRecRelayer(
        bytes32,
        bytes memory,
        uint256,
        bytes memory _payload
    ) public view returns (address payable recRelayer) {
        // RecRelayer is the default relayer for every odd ping and the backup relayer for even pings
        uint256 pingCount = abi.decode(_payload, (uint256));
        if (pingCount % 2 == 1) recRelayer = payable(receiveDefaultRelayer);
        else recRelayer = payable(receiveBackupRelayer);
    }

    // allow this contract to receive ether
    receive() external payable {}

    // Private function that handles the checks, calculations and approvals of sending and protocol fees.
    function _handleSendingAndProtocolFees(
        uint256 _sendingFee,
        uint256 _protocolFee,
        address _protocolFeeToken
    ) private returns (uint256 totalNativeTokenFee) {
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
            (_protocolFeeToken != defaultFeeToken) &&
            (defaultFeeToken != address(0)) &&
            (_protocolFeeToken != address(0))
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
