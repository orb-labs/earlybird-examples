// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/FeeCollector.sol";

contract SendingRelayerDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));

        string memory chainName = vm.envString("CHAIN_NAME");

        address expectedSendingRelayerAddress = vm.envAddress("EXPECTED_SENDING_RELAYER_ADDRESS");

        uint256 size = 0;
        assembly {
            size := extcodesize(expectedSendingRelayerAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            FeeCollector sendingRelayer = new FeeCollector();
            sendingRelayer.updateNativeTokenFee(true, 0);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "addresses/",
                vm.envString("ENVIRONMENT"),
                "/",
                chainName,
                "/sending_relayer.txt"
            );

            string memory sendingRelayerAddress = vm.toString(address(sendingRelayer));
            vm.writeFile(storagePath, sendingRelayerAddress);
            console.log("SendingRelayerAddress deployed on %s", chainName);
        } else {
            console.log("SendingRelayerAddress already deployed on %s", chainName);
        }
    }
}
