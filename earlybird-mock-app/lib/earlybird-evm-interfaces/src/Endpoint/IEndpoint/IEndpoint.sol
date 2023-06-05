// src/Endpoint/IEndpoint/IEndpoint.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./IEndpointFunctionsForAdmins.sol";
import "./IEndpointFunctionsForApps.sol";
import "./IEndpointFunctionsForLibraries.sol";
import "./IEndpointGetFunctions.sol";
import "../../Libraries/ILibrary/IRequiredReceiveModuleFunctions.sol";
import "../../Libraries/ILibrary/IRequiredSendModuleFunctions.sol";

/**
 * @author - Orb Labs
 * @title  - IEndpoint
 * @notice - Complete Interface for Endpoint.
 */
interface IEndpoint is
    IEndpointFunctionsForAdmins,
    IEndpointFunctionsForApps,
    IEndpointFunctionsForLibraries,
    IEndpointGetFunctions
{
    /**
     * @dev - Enum representing library module types.
     * SEND - represents a libraries send module
     * RECEIVE - represents a libraries receive module
     */
    enum ModuleType {
        SEND,
        RECEIVE
    }

    /**
     * @dev - Struct representing an endpoint library
     * iSendModule - interface of the library's send module
     * iReceiveModule - interfaces of the library's receive module
     * isDeprecated - bool indicating whether the library is deprecated or not.
     * isInitialized - bool indicating whether the library is initialized or not.
     */
    struct LibraryObject {
        IRequiredSendModuleFunctions iSendModule;
        IRequiredReceiveModuleFunctions iReceiveModule;
        bool isDeprecated;
        bool isInitialized;
    }

    /**
     * @dev - Event emitted when a new library is added to the protocol.
     * @param libraryName - string indicating the library name.
     * @param sendModule - address of the library's send module
     * @param receiveModule - address of the library's receive module.
     */
    event NewLibraryAdded(string libraryName, address indexed sendModule, address indexed receiveModule);

    /**
     * @dev - Event emitted when a library is deprecated.
     * @param libraryName - string indicating the library name.
     * @param sendModule - address of the library's send module
     * @param receiveModule - address of the library's receive module.
     */
    event LibraryDeprecated(string libraryName, address indexed sendModule, address indexed receiveModule);

    /**
     * @dev - Event emitted when a library is undeprecated
     * @param libraryName - string indicating the library name.
     * @param sendModule - address of the library's send module
     * @param receiveModule - address of the library's receive module.
     */
    event LibraryUndeprecated(string libraryName, address indexed sendModule, address indexed receiveModule);

    /**
     * @dev - Event emitted when a library module's protocol fees settings are updated
     * @param libraryName - string indicating the library name.
     * @param moduleType - uint256 indicating whether it is the send or receive module
     * @param protocolFeeSettings - bytes indicating encoded protocol fee settings
     */
    event ProtocolFeeSettingsUpdated(string libraryName, uint256 indexed moduleType, bytes protocolFeeSettings);

    /**
     * @dev - Event emitted when an app's library selects and configures a library
     * @param app - address of the app selecting and passing its configs to the library
     * @param libraryName - string indicating the library name.
     */
    event AppLibraryAndConfigsSet(address indexed app, string libraryName);

    /**
     * @dev - Event emitted when an app updates its selected library's send module configs.
     * @param app - address of the app selecting and passing its configs to the library
     * @param libraryName - string indicating the library name.
     * @param sendModule - address of the library's send module
     * @param sendModuleConfigs - bytes indicating encoded send module configs
     */
    event AppSendModuleConfigsUpdated(
        address indexed app, string libraryName, address indexed sendModule, bytes sendModuleConfigs
    );

    /**
     * @dev - Event emitted when an app updates its selected library's receive module configs.
     * @param app - address of the app selecting and passing its configs to the library
     * @param libraryName - string indicating the library name.
     * @param receiveModule - address of the library's receive module
     * @param receiveModuleConfigs - bytes indicating encoded receive module configs
     */
    event AppReceiveModuleConfigsUpdated(
        address indexed app, string libraryName, address indexed receiveModule, bytes receiveModuleConfigs
    );

    /**
     * @dev - Event emitted when endpoint delivers message to an app.
     * @param app - address of app message was delivered to
     * @param senderChainId - uint256 indicating the sender's chain id
     * @param sender - bytes indicating the address of the sender
     *                 (bytes is used since the sender can be on an EVM or non-EVM chain)
     * @param libraryName - string indicating the library name.
     * @param nonce - uint256 indicating the nonce of the message that was passed
     */
    event MessageDeliveredToApp(
        address indexed app, uint256 indexed senderChainId, bytes sender, string libraryName, uint256 nonce
    );
}
