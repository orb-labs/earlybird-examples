// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/MockRelayer.sol";

contract MockRukhRelayerDeployment is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");

        string memory chainName = vm.envString("CHAIN_NAME");
        string memory addressFolder = vm.envString("ADDRESS_FOLDER");
        address expectedMockRukhRelayer = vm.envAddress("EXPECTED_MOCK_RUKH_RELAYER_ADDRESS");

        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockRukhRelayer)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockRelayer mockRukhRelayer = new MockRelayer();
            mockRukhRelayer.updateNativeTokenFee(true, 0);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "script/deploymentScripts/mockRukhRelayer/addresses/",
                addressFolder,
                "/",
                chainName,
                ".txt"
            );

            string memory mockRukhRelayerAddress = vm.toString(address(mockRukhRelayer));
            vm.writeFile(storagePath, mockRukhRelayerAddress);
            console.log("MockRukhRelayerAddress deployed on %s", chainName);
        } else {
            console.log("MockRukhRelayerAddress already deployed on %s", chainName);
        }
    }
}
