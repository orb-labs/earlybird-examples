// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/ThunderbirdVersion/MockRelayer.sol";

contract MockThunderbirdRelayerDeployment is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");

        string memory chainName = vm.envString("CHAIN_NAME");
        string memory addressFolder = vm.envString("ADDRESS_FOLDER");
        address expectedMockThunderbirdRelayer = vm.envAddress("EXPECTED_MOCK_THUNDERBIRD_RELAYER_ADDRESS");

        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockThunderbirdRelayer)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockRelayer mockThunderbirdRelayer = new MockRelayer();
            mockThunderbirdRelayer.updateNativeTokenFee(true, 0);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "script/deploymentScripts/mockThunderbirdRelayer/addresses/",
                addressFolder,
                "/",
                chainName,
                ".txt"
            );

            string memory mockThunderbirdRelayerAddress = vm.toString(address(mockThunderbirdRelayer));
            vm.writeFile(storagePath, mockThunderbirdRelayerAddress);
            console.log("MockThunderbirdRelayerAddress deployed on %s", chainName);
        } else {
            console.log("MockThunderbirdRelayerAddress already deployed on %s", chainName);
        }
    }
}
