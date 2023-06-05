// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/ThunderbirdVersion/SendingRelayer.sol";

contract SendingRelayerDeployment is Script {
    function run() external {
        // get mnemonics and key indexes for app, oracle, relayer from env vars
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");
        string memory chainName = vm.envString("CHAIN_NAME");

        // expected address
        address expectedThunderbirdVersionPingPongSendingRelayerAddress = vm.envAddress(
            "EXPECTED_THUNDERBIRD_VERSION_PINGPONG_SENDING_ORACLE_ADDRESS"
        );

        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));
        uint256 size = 0;

        assembly {
            size := extcodesize(expectedThunderbirdVersionPingPongSendingRelayerAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            SendingRelayer sendingRelayer = new SendingRelayer();
            sendingRelayer.updateNativeTokenFee(true, 0);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "script/deploymentScripts/ThunderbirdVersion/addresses/",
                vm.envString("ADDRESS_FOLDER"),
                "/",
                chainName,
                "/sending_relayer.txt"
            );
            console.log(storagePath);

            vm.writeFile(storagePath, vm.toString(address(sendingRelayer)));
            console.log("Thunderbird Version PingPong SendingRelayer deployed on %s", chainName);
        } else {
            console.log("Thunderbird Version PingPong SendingRelayer already deployed on %s", chainName);
        }
    }
}
