// src/ThunderbirdVersion/MockReceiver.sol
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

import "../../lib/earlybird-evm-interfaces/src/IReceiver/IReceiver.sol";
import "../../lib/earlybird-evm-interfaces/src/Endpoint/IEndpoint/IEndpointFunctionsForApps.sol";
import "../../lib/earlybird-evm-interfaces/src/Libraries/Thunderbird/ThunderbirdReceiveModule/IThunderbirdReceiveModule.sol";

contract MockReceiver is IReceiver {
    address public endpoint;
    address public receiveLibrary;

    uint256 private constant _TESTING_NORMAL_DELIVERY = 0;
    uint256 private constant _TESTING_DELIVERY_FAILURE = 1;
    uint256 private constant _TESTING_REENTRANCY = 2;
    uint256 private constant _TESTING_CONTENT = 3;
    uint256 private constant _TESTING_MSG_DELIVERY_CONTRACT = 4;

    uint256 public testingType;

    event BroadcastedMessage(
        uint256 indexed senderChainId,
        bytes senderAddress,
        uint256 nonce,
        bytes payload,
        bytes additionalInfo
    );

    event BroadcastMsgDeliveryContract(address indexed deliveryContract);

    constructor(address _endpoint) {
        endpoint = _endpoint;
    }

    function setReceiveLibrary(address _receiveLibrary) external {
        receiveLibrary = _receiveLibrary;
    }

    function setTestType(uint256 _testType) external {
        testingType = _testType;
    }

    function setLibraryAndConfigs(
        string memory _libraryName,
        bytes memory _sendModuleConfigs,
        bytes memory _receiveModuleConfigs
    ) external {
        IEndpointFunctionsForApps(endpoint).setLibraryAndConfigs(
            _libraryName,
            _sendModuleConfigs,
            _receiveModuleConfigs
        );
    }

    function receiveMsg(
        uint256 _senderChainId,
        bytes memory _sender,
        uint256 _nonce,
        bytes memory _payload,
        bytes memory _additionalInfo
    ) external {
        if (testingType == _TESTING_NORMAL_DELIVERY) {
            // Do nothing
        } else if (testingType == _TESTING_REENTRANCY) {
            IThunderbirdReceiveModule.MsgsByAggregateProof[]
                memory msgsByAggregateProofs = new IThunderbirdReceiveModule.MsgsByAggregateProof[](1);
            IThunderbirdReceiveModule.MsgsByApp[] memory msgsByApps = new IThunderbirdReceiveModule.MsgsByApp[](1);
            msgsByApps[0] = IThunderbirdReceiveModule.MsgsByApp(
                address(this),
                _senderChainId,
                _sender,
                msgsByAggregateProofs
            );
            IThunderbirdReceiveModule(receiveLibrary).submitMessages(msgsByApps);
        } else if (testingType == _TESTING_DELIVERY_FAILURE) {
            require(false, "MockReceiver: Not receiving messages.");
        } else if (testingType == _TESTING_CONTENT) {
            emit BroadcastedMessage(_senderChainId, _sender, _nonce, _payload, _additionalInfo);
        } else if (testingType == _TESTING_MSG_DELIVERY_CONTRACT) {
            emit BroadcastMsgDeliveryContract(msg.sender);
        }
    }
}
