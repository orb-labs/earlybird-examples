// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/MockOracle.sol";

contract MockRukhOracleDeployment is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");

        string memory chainName = vm.envString("CHAIN_NAME");
        string memory addressFolder = vm.envString("ADDRESS_FOLDER");
        address expectedMockRukhOracleAddress = vm.envAddress("EXPECTED_MOCK_RUKH_ORACLE_ADDRESS");

        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockRukhOracleAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockOracle mockRukhOracle = new MockOracle();
            mockRukhOracle.updateNativeTokenFee(true, 0);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "script/deploymentScripts/mockRukhOracle/addresses/",
                addressFolder,
                "/",
                chainName,
                ".txt"
            );

            string memory mockRukhOracleAddress = vm.toString(address(mockRukhOracle));
            vm.writeFile(storagePath, mockRukhOracleAddress);
            console.log("MockRukhOracle deployed on %s", chainName);
        } else {
            console.log("MockRukhOracle already deployed on %s", chainName);
        }
    }
}
