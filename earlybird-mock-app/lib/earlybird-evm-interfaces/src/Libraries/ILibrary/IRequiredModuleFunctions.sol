// src/ILibrary/IRequiredModuleFunctions.sol
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 * @author - Orb Labs
 * @title  - IRequiredModuleFunctions
 * @notice - Interface for required functions for all library modules.
 *           These fuunctions are required becaused they are called by the endpoint.
 */
interface IRequiredModuleFunctions {
    /**
     * @dev - Endpoint-only function that allows endpoint to pass application configs to the library
     * @param _app - address of application passing the configs
     * @param _configs - bytes array containing encoded configs to be passed
     *                   to the library on the applications behalf
     */
    function setAppConfigs(address _app, bytes memory _configs) external;

    /**
     * @dev - Endpoint-only function that allows endpoint to retrieve an application configs in a library
     * @param _app - address of application passing the configs
     */
    function getAppConfigs(address _app) external view returns (bytes memory);

    /**
     * @dev - Endpoint-only function that allows endpoint to update an application's library configs
     * @param _app - address of application passing the configs
     * @param _configs - bytes array containing encoded configs to be passed
     *                   to the library on the applications behalf
     */
    function updateAppConfigs(address _app, bytes memory _configs) external;

    /**
     * @dev - Endpoint-only function that allows endpoint to update fee settings for the library.
     * @param _libraryFeeSettings - bytes array containing encoded endpoint fee settings.
     */
    function updateProtocolFeeSettings(bytes memory _libraryFeeSettings) external;

    /**
     * @dev - Endpoint-only function that allows endpoint to retrieve the library's fee settings.
     * @return feeSettings - bytes array containing encoded library fee settings
     */
    function getProtocolFeeSettings() external view returns (bytes memory feeSettings);

    /**
     * @dev - Endpoint-only function that allows endpoint to retrieve the library's fee settings.
     * @return isProtocolFeeOn - boolean that says whether the protocol fee is on or not.
     * @return protocolFeeToken - address of the protocol fee token.
     *                            returns address(0) if fee is in native token.
     * @return protocolFeeAmount - uint256 indicating the fee amount
     */
    function getProtocolFee()
        external
        view
        returns (bool isProtocolFeeOn, address protocolFeeToken, uint256 protocolFeeAmount);
}
