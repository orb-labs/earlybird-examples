// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/MockSendingRelayer.sol";

contract MockSendingRelayerDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));

        string memory chainName = vm.envString("CHAIN_NAME");

        address expectedMockSendingRelayerAddress = vm.envAddress("EXPECTED_MOCK_SENDING_RELAYER_ADDRESS");

        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockSendingRelayerAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockRelayer mockSendingRelayer = new MockRelayer();
            mockSendingRelayer.updateNativeTokenFee(true, 0);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "addresses/",
                vm.envString("ENVIRONMENT"),
                "/",
                chainName,
                "/sending_relayer.txt"
            );

            string memory mockSendingRelayerAddress = vm.toString(address(mockSendingRelayer));
            vm.writeFile(storagePath, mockSendingRelayerAddress);
            console.log("MockSendingRelayerAddress deployed on %s", chainName);
        } else {
            console.log("MockSendingRelayerAddress already deployed on %s", chainName);
        }
    }
}
