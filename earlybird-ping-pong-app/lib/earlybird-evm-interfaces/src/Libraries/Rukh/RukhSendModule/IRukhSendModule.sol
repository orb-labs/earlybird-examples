// src/Libraries/Rukh/RukhSendModule/IRukhSendModule.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../../ILibrary/IRequiredSendModuleFunctions.sol";

/**
 * @author - Orb Labs
 * @title  - IRukhSendModule
 * @notice - Interface for Rukh library's send module
 */
interface IRukhSendModule is IRequiredSendModuleFunctions {
    /**
     * @dev - Enum representing config type the app would like updated.
     * BROADCAST_STATUS_CHANGE - represents broadcasting status being updated
     * ORACLE_CHANGE - represents oracle address being updated
     * RELAYER_CHANGE - represents relayer address being updated
     * NONCE_CHANGE - represents the app's msg nonce being updated.
     */
    enum ConfigType {
        BROADCAST_STATUS_CHANGE,
        ORACLE_CHANGE,
        RELAYER_CHANGE,
        NONCE_CHANGE
    }

    /**
     * @dev - Struct that represent protocol fee settings
     * feeOn - bool indicating whether protocol fees are on
     * feeTo - address indicating who protocol fees should be paid to.
     * collectInNativeToken - bool indicaitng whether protocol fees should be collected in native token.
     * nonNativeFeeToken - address indicating what non-native token protocol fees should be collected in if applicable.
     * amount - uint256 indicating amount of tokens that should be collected as fees.
     */
    struct ProtocolFeeSettings {
        bool feeOn;
        address feeTo;
        bool collectInNativeToken;
        address nonNativeFeeToken;
        uint256 amount;
    }

    /**
     * @dev - Struct representing an app's settings
     * isSelfBroadcasting - bool on whether the app is self broadcasting or not.
     * oracle - address of app's selected oracle
     * relayer - address of app's selected relayer
     * isInitialized - bool indicating whether the app settings have been initialized or not.
     */
    struct AppSettings {
        bool isSelfBroadcasting;
        address oracle;
        address relayer;
        bool isInitialized;
    }

    /**
     * @dev - Struct representing an app's settings
     * ordered - uint256 indicating nonce for ordered messages.  Starts from 0 and goes to 2**256 – 1.
     * unordered - uint256 indicating nonce for unordered messages. Starts from 2**256 – 1 and goes to 0.
     */
    struct Nonces {
        uint256 ordered;
        uint256 unordered;
    }

    /**
     * @dev - Event emitted when you send a message
     * @param app - address of the application
     * @param receiverChainId - uint256 indicating the receiver chain Id
     * @param receiver - bytes array indicating the address of the receiver
     * @param nonce - uint256 indicating the nonce of the message. The nonce is a unique number given to each message.
     * @param isOrderedMsg - bool indicating whether message must be delivered in order or not.
     * @param payload - bytes array containing message payload
     */
    event BroadcastMessage(
        address indexed app,
        uint256 indexed receiverChainId,
        bytes receiver,
        uint256 nonce,
        bool isOrderedMsg,
        bytes payload
    );
}
