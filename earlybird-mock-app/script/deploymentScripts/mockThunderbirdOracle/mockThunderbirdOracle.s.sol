// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/ThunderbirdVersion/MockOracle.sol";

contract MockThunderbirdOracleDeployment is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");

        string memory chainName = vm.envString("CHAIN_NAME");
        string memory addressFolder = vm.envString("ADDRESS_FOLDER");
        address expectedMockThunderbirdOracleAddress = vm.envAddress("EXPECTED_MOCK_THUNDERBIRD_ORACLE_ADDRESS");

        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockThunderbirdOracleAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockOracle mockThunderbirdOracle = new MockOracle();
            mockThunderbirdOracle.updateNativeTokenFee(true, 0);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "script/deploymentScripts/mockThunderbirdOracle/addresses/",
                addressFolder,
                "/",
                chainName,
                ".txt"
            );

            string memory mockThunderbirdOracleAddress = vm.toString(address(mockThunderbirdOracle));
            vm.writeFile(storagePath, mockThunderbirdOracleAddress);
            console.log("MockThunderbirdOracle deployed on %s", chainName);
        } else {
            console.log("MockThunderbirdOracle already deployed on %s", chainName);
        }
    }
}
