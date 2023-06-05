// src/Endpoint/IEndpoint/IEndpointFunctionsForAdmins.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @author - Orb Labs
 * @title  - IEndpointFunctionsForAdmins
 * @notice - Interface for Endpoint functions only the admin can call
 */
interface IEndpointFunctionsForAdmins {
    /**
     * @dev - Admin-only function that adds a new message library to the endpoint
     * @param _libraryName - name of the library that is being added
     * @param _sendModule - address of the module responsible for sending messages
     * @param _receiveModule - address of the module responsible for receiving messages
     */
    function addNewLibrary(string calldata _libraryName, address _sendModule, address _receiveModule) external;

    /**
     * @dev - Admin-only function that adds a new inbound message library to the endpoint
     * @param _libraryName - name of the library that is being deprecated
     */
    function deprecateLibrary(string calldata _libraryName) external;

    /**
     * @dev - Admin-only function that adds a new inbound message library to the endpoint
     * @param _libraryName - name of the library that is being undeprecated
     */
    function undeprecateLibrary(string calldata _libraryName) external;

    /**
     * @dev - Admin-only function that allows admin to update protocol library fees
     * @param _libraryName - name of the library that is being added
     * @param _moduleType - uint256 indicating whether its the sendModule or
     *                      receiveModule whose settings are being updated
     * @param _protocolFeeSettings - bytes value indicating the encoded protocol fee settings
     */
    function updateProtocolFeeSettings(
        string calldata _libraryName,
        uint256 _moduleType,
        bytes calldata _protocolFeeSettings
    ) external;
}
