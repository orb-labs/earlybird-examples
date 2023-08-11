// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/MockApp.sol";

contract MockRukhAppDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));

        string memory chainName = vm.envString("CHAIN_NAME");
        
        address expectedMockAppAddress = vm.envAddress("EXPECTED_MOCK_RUKH_APP_ADDRESS");

        bytes memory appConfigForSending = abi.encode(
            false, 
            vm.envAddress("RELAYER_FEE_COLLECTOR_ADDRESS"),
            vm.envAddress("ORACLE_FEE_COLLECTOR_ADDRESS")
        );
        bool directMsgsEnabled = true;

        bytes memory appConfigForReceiving = abi.encode(
            10, //minDisputeTime,
            10, // minDisputeResolutionExtension,
            100, //disputeEpochLength,
            1, //maxValidDisputesPerEpoch,
            vm.envAddress("ORACLE_ADDRESS"), //oracle,
            vm.envAddress("RELAYER_ADDRESS"), //_defaultRelayer,
            vm.envAddress("RUKH_DISPUTER_CONTRACT_ADDRESS"), //_disputersContract,
            vm.addr(vm.deriveKey(
                vm.envString("DISPUTE_RESOLVER_MNEMONICS"),
                uint32(vm.envUint("DISPUTE_RESOLVER_KEY_INDEX"))
            )), //_disputeResolver,
            vm.envAddress("RUKH_RECS_CONTRACT_ADDRESS"), //recsContract,
            true, // emitMsgProofs,
            directMsgsEnabled, // directMsgsEnabled,
            false // msgDeliveryPaused
        );

        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockAppAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockApp app = new MockApp(vm.envAddress("EARLYBIRD_ENDPOINT_ADDRESS"), address(0), directMsgsEnabled);
            app.setLibraryAndConfigs("Rukh V1", appConfigForSending, appConfigForReceiving);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "addresses/",
                vm.envString("ENVIRONMENT"),
                "/",
                chainName,
                "/rukh/app.txt"
            );

            string memory mockAppAddress = vm.toString(address(app));
            vm.writeFile(storagePath, mockAppAddress);
            console.log("MockRukhApp deployed on %s", chainName);
        } else {
            vm.startBroadcast(deployerPrivateKey);
            MockApp app = MockApp(expectedMockAppAddress);
            app.setLibraryAndConfigs("Rukh V1", appConfigForSending, appConfigForReceiving);
            vm.stopBroadcast();

            console.log("MockRukhApp already deployed on %s", chainName);
            console.log("Resetting configs");
        }
    }
}

contract MockRukhAppSendMessage is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("SENDING_MNEMONICS"), uint32(vm.envUint("SENDING_KEY_INDEX")));

        bytes memory additionalParams = abi.encode(address(0), true, 5000000);

        vm.startBroadcast(deployerPrivateKey);
        MockApp(vm.envAddress("MOCK_RUKH_APP_ADDRESS")).sendMessage(
            bytes32(abi.encodePacked(vm.envString("RECEIVER_EARLYBIRD_INSTANCE_ID"))),
            abi.encode(vm.envAddress("RECEIVER_ADDRESS")),
            vm.envString("MESSAGE_STRING"),
            additionalParams
        );
        vm.stopBroadcast();
    }
}

contract MockRukhAppGetAllMessages is Script {
    function run() external view {
        address mockAppAddress = vm.envAddress("MOCK_RUKH_APP_ADDRESS");
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
