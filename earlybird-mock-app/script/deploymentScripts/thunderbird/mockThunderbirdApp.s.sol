// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/ThunderbirdVersion/MockApp.sol";

contract MockThunderbirdAppDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));

        string memory chainName = vm.envString("CHAIN_NAME");
        address earlybirdEndpointAddress = vm.envAddress("EARLYBIRD_ENDPOINT_ADDRESS");

        address expectedMockAppAddress = vm.envAddress("EXPECTED_MOCK_THUNDERBIRD_APP_ADDRESS");

        address sendingOracle = vm.envAddress("MOCK_SENDING_ORACLE_ADDRESS");
        address sendingRelayer = vm.envAddress("MOCK_SENDING_RELAYER_ADDRESS");

        bytes memory sendModuleConfigs = abi.encode(false, sendingOracle, sendingRelayer);
        bytes memory receiveModuleConfigs = abi.encode(
            vm.addr(vm.deriveKey(
                vm.envString("ORACLE_MNEMONICS"),
                uint32(vm.envUint("ORACLE_KEY_INDEX"))
            )), //_receivingOracle
             vm.addr(vm.deriveKey(
                vm.envString("RELAYER_MNEMONICS"),
                uint32(vm.envUint("RELAYER_KEY_INDEX"))
            )), //_receiveDefaultRelayer
            vm.envAddress("MOCK_THUNDERBIRD_RECS_CONTRACT_ADDRESS"), //recsContract
            true, // emitMsgProofs
            false, // directMsgsEnabled
            false // msgDeliveryPaused
        );

        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockAppAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockApp app = new MockApp(earlybirdEndpointAddress, address(0));
            app.setLibraryAndConfigs("Thunderbird V1", sendModuleConfigs, receiveModuleConfigs);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "addresses/",
                vm.envString("ENVIRONMENT"),
                "/",
                chainName,
                "/thunderbird/app.txt"
            );

            string memory mockAppAddress = vm.toString(address(app));
            vm.writeFile(storagePath, mockAppAddress);
            console.log("MockThunderbirdApp deployed on %s", chainName);
        } else {
            vm.startBroadcast(deployerPrivateKey);
            MockApp app = MockApp(expectedMockAppAddress);
            app.setLibraryAndConfigs("Thunderbird V1", sendModuleConfigs, receiveModuleConfigs);
            vm.stopBroadcast();

            console.log("MockAppAddress already deployed on %s", chainName);
            console.log("Resetting configs");
        }
    }
}

contract MockThunderbirdAppSendMessage is Script {
    function run() external {
        address sendingAppAddress = vm.envAddress("MOCK_THUNDERBIRD_APP_ADDRESS");
        uint256 receiverChainId = vm.envUint("RECEIVER_CHAIN_ID");
        address receiverAddress = vm.envAddress("RECEIVER_ADDRESS");
        string memory messageString = vm.envString("MESSAGE_STRING");
        
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("SENDING_MNEMONICS"), uint32(vm.envUint("SENDING_KEY_INDEX")));

        bytes memory additionalParams = abi.encode(address(0), true, 5000000);

        vm.startBroadcast(deployerPrivateKey);
        MockApp(sendingAppAddress).sendMessage(
            receiverChainId,
            abi.encode(receiverAddress),
            messageString,
            additionalParams
        );
        vm.stopBroadcast();
    }
}

contract MockThunderbirdAppGetAllMessages is Script {
    function run() external view {
        address mockAppAddress = vm.envAddress("MOCK_THUNDERBIRD_APP_ADDRESS");
        string memory chainName = vm.envString("CHAIN_NAME");
        string[] memory receivedMessages = MockApp(mockAppAddress).getAllReceivedMessages();
        string[] memory sentMessages = MockApp(mockAppAddress).getAllSentMessages();

        console.log(chainName, "\n");
        console.log("Sent Messages:");
        for (uint256 i = 0; i < sentMessages.length; i++) {
            console.log(i, ":", sentMessages[i]);
        }

        console.log("\n");
        console.log("Received Messages");
        for (uint256 i = 0; i < receivedMessages.length; i++) {
            console.log(i, ":", receivedMessages[i]);
        }

        console.log("\n");
    }
}
