// src/RukhVersion/PingPong.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

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
import "earlybird/src/Libraries/Rukh/RukhReceiveModule/IRecsContractForRukhReceiveModule.sol";

contract PingPong is IReceiver, IRecsContractForRukhReceiveModule, Ownable, Pausable {
    // name of the library that the application is using
    string public libraryName = "Rukh V1";

    // Endpoint address
    address public endpoint;

    // The address of the library's receive module
    address public libraryReceiveModule;

    // The default token for paying fees
    address public defaultFeeToken;

    // Address of default receive relayer 1
    address public receiveDefaultRelayer;

    // Address of backup receive relayer 2
    address public receiveBackupRelayer;

    // Address of the recommendations contract
    address public recsContract;

    // Whether app wants to self broadcast messages or not. If app decides to self broadcast,
    // the burden of paying the oracle and relayer as well as ordering its nonces rest of the developer.
    bool private isSelfBroadcasting = false;

    // The least amount of blocks we are allowed to wait for disputes to a message proof.
    uint256 private minDisputeTime = 10;

    // The least amount of blocks we are allowed to wait for dispute resolutions to become final.
    uint256 private minDisputeResolutionExtension = 10;

    // The number of blocks in a dispute epoch.  A dispute epoch is an arbitrary amount of time
    // within which we track the number of disputes.
    uint256 private disputeEpochLength = 100;

    // The maximum number of valid disputes we can have in an epoch before it halts.
    uint256 private maxValidDisputesPerEpoch = 1;

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
        address _receiveBackupRelayer,
        address _disputersContract,
        address _disputeResolverContract
    ) {
        endpoint = _endpoint;
        recsContract = address(this);
        receiveDefaultRelayer = _receiveDefaultRelayer;
        receiveBackupRelayer = _receiveBackupRelayer;

        bytes memory sendModuleConfigs = abi.encode(isSelfBroadcasting, _sendingOracleAddress, _sendingRelayerAddress);
        bytes memory receiveModuleConfigs = abi.encode(
            minDisputeTime,
            minDisputeResolutionExtension,
            disputeEpochLength,
            maxValidDisputesPerEpoch,
            _receivingOracle,
            _receiveDefaultRelayer,
            _disputersContract,
            _disputeResolverContract,
            recsContract,
            emitMsgProofs,
            directMsgsEnabled,
            msgDeliveryPaused
        );

        IEndpointFunctionsForApps(endpoint).setLibraryAndConfigs(libraryName, sendModuleConfigs, receiveModuleConfigs);
        (, libraryReceiveModule, ) = IEndpointGetFunctions(endpoint).getLibraryInfo(libraryName);
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
    function updateSendModuleConfigs(
        bool _isSelfBroadcasting,
        address _sendingOracleAddress,
        address _sendingRelayerAddress
    ) external onlyOwner {
        isSelfBroadcasting = _isSelfBroadcasting;
        bytes memory sendModuleConfigs = abi.encode(_isSelfBroadcasting, _sendingOracleAddress, _sendingRelayerAddress);
        IEndpointFunctionsForApps(endpoint).updateSendModuleConfigs(sendModuleConfigs);
    }

    function updateReceiveModuleConfigs(
        uint256 _minDisputeTime,
        uint256 _minDisputeResolutionExtension,
        uint256 _disputeEpochLength,
        uint256 _maxValidDisputesPerEpoch,
        address _receivingOracle,
        address _receivingDefaultRelayer,
        address _disputersContract,
        address _disputeResolver,
        address _recsContract,
        bool _emitMsgProofs,
        bool _directMsgsEnabled,
        bool _msgDeliveryPaused
    ) external onlyOwner {
        minDisputeTime = _minDisputeTime;
        minDisputeResolutionExtension = _minDisputeResolutionExtension;
        disputeEpochLength = _disputeEpochLength;
        maxValidDisputesPerEpoch = _maxValidDisputesPerEpoch;
        receiveDefaultRelayer = _receivingDefaultRelayer;
        recsContract = _recsContract;
        emitMsgProofs = _emitMsgProofs;
        directMsgsEnabled = directMsgsEnabled;
        msgDeliveryPaused = _msgDeliveryPaused;

        bytes memory receiveModuleConfigs = abi.encode(
            _minDisputeTime,
            _minDisputeResolutionExtension,
            _disputeEpochLength,
            _maxValidDisputesPerEpoch,
            _receivingOracle,
            _receivingDefaultRelayer,
            _disputersContract,
            _disputeResolver,
            _recsContract,
            _emitMsgProofs,
            _directMsgsEnabled,
            _msgDeliveryPaused
        );

        IEndpointFunctionsForApps(endpoint).updateReceiveModuleConfigs(receiveModuleConfigs);
    }

    function updateDefaultFeeToken(address _feeToken) external onlyOwner {
        defaultFeeToken = _feeToken; // Set to zero address if you want to use native token for fees.
    }

    function approveTokenToEndpoint(address _tokenAddress, uint256 _amount) public onlyOwner {
        ERC20(_tokenAddress).approve(endpoint, _amount);
    }

    function ping(uint256 _dstChainId, address _dstAddress, uint256 pings) public whenNotPaused {
        // encode the payload with the number of pings
        bytes memory payload = abi.encode(pings);
        bool isOrderedMsg = true;
        bytes memory additionalParams = abi.encode(defaultFeeToken, isOrderedMsg, 500000);
        bytes memory _dst = abi.encode(_dstAddress);

        // Check how much it costs to send messages with the default token
        (bool isTokenAccepted, uint256 feeEstimated) = IEndpointGetFunctions(endpoint).getSendingFeeEstimate(
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

        IEndpointFunctionsForApps(endpoint).sendMessage{value: totalNativeTokenFee}(
            _dstChainId,
            _dst,
            payload,
            additionalParams
        );

        emit Ping(pings);
    }

    function receiveMsg(
        uint256 _senderChainId,
        bytes memory _sender,
        uint256 _nonce,
        bytes memory _payload,
        bytes memory _additionalInfo
    ) external onlyEndpointOrLibraryReceiveModule {
        // Get the recommended values for a message like this.
        (
            uint256 recommendedDisputeTime,
            uint256 recommendedDisputeResolutionExtension,
            bytes32 revealedMsgSecret,
            address recommendedRelayer
        ) = IRecsContractForRukhReceiveModule(recsContract).getAllRecs(_senderChainId, _sender, _nonce, _payload);

        // Get the supplied values
        (
            uint256 suppliedDisputeTime,
            uint256 suppliedDisputeResolutionExtension,
            bytes32 suppliedMsgSecret,
            address relayer
        ) = abi.decode(_additionalInfo, (uint256, uint256, bytes32, address));

        // Revert if supplied values are not correct
        require(
            (recommendedDisputeTime == suppliedDisputeTime) &&
                (recommendedDisputeResolutionExtension == suppliedDisputeResolutionExtension) &&
                (revealedMsgSecret == suppliedMsgSecret) &&
                (recommendedRelayer == relayer),
            "PingPong: Msg Delivered with wrong rec values"
        );

        // Extract sending address and chain
        address sendBackAddress = abi.decode(_sender, (address));

        // increase the number of pings
        uint256 pings = abi.decode(_payload, (uint256));

        // Call the ping function again.
        ping(_senderChainId, sendBackAddress, pings++);
    }

    // allow this contract to receive ether
    receive() external payable {}

    function getAllRecs(
        uint256,
        bytes memory,
        uint256,
        bytes memory _payload
    )
        public
        view
        returns (
            uint256 recommendedDisputeTime,
            uint256 recommendedDisputeResolutionExtension,
            bytes32 revealedMsgSecret,
            address recommendedRelayer
        )
    {
        // revealedSecret is the hash of the payload
        revealedMsgSecret = keccak256(_payload);
        uint256 pingCount = abi.decode(_payload, (uint256));
        if (pingCount % 2 == 1) {
            // RecommendedRelayer is the default relayer for every odd ping
            recommendedRelayer = receiveDefaultRelayer;
            // RecommendedDisputeTime is minDisputeTime for every odd ping
            recommendedDisputeTime = minDisputeTime;
            // RecommendedDisputeResolutionExtension is minDisputeResolutionExtension for every odd ping
            recommendedDisputeResolutionExtension = minDisputeResolutionExtension;
        } else {
            // RecommendedRelayer is the backup relayer for even pings
            recommendedRelayer = receiveBackupRelayer;
            // RecommendedDisputeTime is minDisputeTime + 1 for every even ping
            recommendedDisputeTime = minDisputeTime + 1;
            // RecommendedDisputeResolutionExtension is minDisputeResolutionExtension + 1 for every odd ping
            recommendedDisputeResolutionExtension = minDisputeResolutionExtension + 1;
        }
    }

    function getRecRelayer(
        uint256,
        bytes memory,
        uint256,
        bytes memory _payload
    ) public view returns (address recRelayer) {
        // RecRelayer is the default relayer for every odd ping and the backup relayer for even pings
        uint256 pingCount = abi.decode(_payload, (uint256));
        if (pingCount % 2 == 1) recRelayer = receiveDefaultRelayer;
        else recRelayer = receiveBackupRelayer;
    }

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
