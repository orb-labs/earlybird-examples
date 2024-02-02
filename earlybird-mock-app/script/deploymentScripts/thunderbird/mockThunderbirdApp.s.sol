// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/ThunderbirdVersion/MockApp.sol";
import "../../../lib/earlybird-evm-interfaces/src/Endpoint/IEndpoint/IEndpoint.sol";
import "../../../lib/earlybird-evm-interfaces/src/Libraries/Thunderbird/ThunderbirdReceiveModule/IThunderbirdReceiveModule.sol";
import "../../../lib/earlybird-evm-interfaces/src/Libraries/SharedSendModule/ISharedSendModule.sol";

contract MockThunderbirdAppDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(
            vm.envString("MNEMONICS"),
            uint32(vm.envUint("KEY_INDEX"))
        );

        string memory chainName = vm.envString("CHAIN_NAME");
        address expectedMockAppAddress = vm.envAddress(
            "EXPECTED_MOCK_THUNDERBIRD_APP_ADDRESS"
        );

        ISharedSendModule.AppConfig memory appConfigForSending = ISharedSendModule.AppConfig(
            false,
            vm.envAddress("ORACLE_FEE_COLLECTOR_ADDRESS"),
            vm.envAddress("RELAYER_FEE_COLLECTOR_ADDRESS")
        );

        IThunderbirdReceiveModule.AppConfig memory appConfigForReceiving = IThunderbirdReceiveModule.AppConfig(
            vm.envAddress("ORACLE_ADDRESS"), //oracle,
            vm.envAddress("RELAYER_ADDRESS"), //_defaultRelayer,
            vm.envAddress("THUNDERBIRD_RECS_CONTRACT_ADDRESS"), //recsContract
            true, // emitMsgProofs
            false, // directMsgsEnabled
            false // msgDeliveryPaused
        );

        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockAppAddress)
        }

        if (size == 0) {
            address endpointAddress = vm.envAddress("EARLYBIRD_ENDPOINT_ADDRESS");
            console.log("using endpoint address: ");
            console.logAddress(endpointAddress);
            vm.startBroadcast(deployerPrivateKey);
            
            MockApp app = new MockApp(
                endpointAddress,
                address(0)
            );

            app.setLibraryAndConfigs(
                "Thunderbird V1",
                abi.encode(appConfigForSending),
                abi.encode(appConfigForReceiving)
            );
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
            app.setLibraryAndConfigs(
                "Thunderbird V1",
                abi.encode(appConfigForSending),
                abi.encode(appConfigForReceiving)
            );
            vm.stopBroadcast();

            console.log(vm.envString("RELAYER_FEE_COLLECTOR_ADDRESS"));
            console.log(vm.envString("ORACLE_FEE_COLLECTOR_ADDRESS"));
            console.log("MockThunderbirdApp already deployed on %s at %s", chainName, expectedMockAppAddress);
            console.log("Resetting configs");
        }
    }
}

contract MockThunderbirdAppSendMessage is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(
            vm.envString("SENDING_MNEMONICS"),
            uint32(vm.envUint("SENDING_KEY_INDEX"))
        );
        
        ISharedSendModule.AdditionalParams memory additionalParams = ISharedSendModule.AdditionalParams(
            address(0), // address feeToken;
            true,       // bool isOrderedMsg;
            450000,     // uint256 destinationGas;
            // when using address 0, it will use the default relayer fee collector from the AppConfig
            address(0) // address expectedRelayerFeeCollector;
        );

        vm.startBroadcast(deployerPrivateKey);
        MockApp(vm.envAddress("MOCK_THUNDERBIRD_APP_ADDRESS")).sendMessage(
            vm.envBytes32("RECEIVER_EARLYBIRD_INSTANCE_ID"),
            abi.encode(vm.envAddress("RECEIVER_ADDRESS")),
            vm.envString("MESSAGE_STRING"),
            abi.encode(additionalParams)
        );
        vm.stopBroadcast();
        console.log("sent message on Thunderbird via Thunderbird mock app");
    }
}

contract MockThunderbirdAppGetAllMessages is Script {
    function run() external view {
        address mockAppAddress = vm.envAddress("MOCK_THUNDERBIRD_APP_ADDRESS");
        string memory chainName = vm.envString("CHAIN_NAME");
        string[] memory receivedMessages = MockApp(mockAppAddress)
            .getAllReceivedMessages();
        string[] memory sentMessages = MockApp(mockAppAddress)
            .getAllSentMessages();

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
