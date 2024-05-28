// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/ThunderbirdVersion/MockApp.sol";
import "../../lib/earlybird-evm-interfaces/src/EarlybirdEndpoint/IEarlybirdEndpoint.sol";
import "../../lib/earlybird-evm-interfaces/src/Libraries/Thunderbird/IThunderbirdReceiveModule.sol";
import "../../lib/earlybird-evm-interfaces/src/Libraries/SharedLibraryModules/ISharedSendModule.sol";
import "../../lib/earlybird-evm-interfaces/src/Libraries/ILibrary/IRequiredModuleFunctions.sol";

contract MockThunderbirdV1AppDeployment is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        string memory chainName = vm.envString("CHAIN_NAME");
        uint256 keyIndex = vm.envUint("KEY_INDEX");
        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));

        address expectedMockThunderbirdV1AppAddress = vm.envAddress("EXPECTED_MOCK_THUNDERBIRD_V1_APP_ADDRESS");
        address earlybirdEndpointAddress = vm.envAddress("EARLYBIRD_ENDPOINT_ADDRESS");
        string memory storagePath = string.concat("addresses/", vm.envString("ENVIRONMENT"), "/", chainName, "/mockThunderbirdV1App.txt");

        uint256 size;
        assembly {
            size := extcodesize(expectedMockThunderbirdV1AppAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockApp app = new MockApp(earlybirdEndpointAddress, address(0));
            vm.stopBroadcast();

            string memory mockThunderbirdV1AppAddress = vm.toString(address(app));
            vm.writeFile(storagePath, mockThunderbirdV1AppAddress);
            console.log("MockThunderbirdV1App deployed on: %s, at: %s, using earlybird endpoint: %s", chainName, mockThunderbirdV1AppAddress, earlybirdEndpointAddress);
        } else {
            string memory mockThunderbirdV1AppAddress = vm.toString(expectedMockThunderbirdV1AppAddress);
            vm.writeFile(storagePath, mockThunderbirdV1AppAddress);
            console.log("MockThunderbirdV1App already deployed on: %s, at: %s, using earlybird endpoint: %s", chainName, mockThunderbirdV1AppAddress, earlybirdEndpointAddress);
        }
    }
}

contract MockThunderbirdV1AppConfigsUpdate is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        string memory chainName = vm.envString("CHAIN_NAME");
        uint256 keyIndex = vm.envUint("KEY_INDEX");
        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));

        address mockThunderbirdV1AppAddress = vm.envAddress("MOCK_THUNDERBIRD_V1_APP_ADDRESS");
        address earlybirdEndpointAddress = vm.envAddress("EARLYBIRD_ENDPOINT_ADDRESS");
        address oracle = vm.envAddress("ORACLE_ADDRESS");
        address relayer = vm.envAddress("RELAYER_ADDRESS");
        address mockThunderbirdV1RecsContract = vm.envAddress("MOCK_THUNDERBIRD_V1_RECS_CONTRACT_ADDRESS");

        bool selfBroadcasting = false;
        bytes memory appConfigForSending = abi.encode(
            ISharedSendModule.AppConfig(
                selfBroadcasting,
                false,
                oracle,
                relayer
            )
        );

        bool emitMsgProofs = true;
        bool directMsgsEnabled = false;
        bool msgDeliveryPaused = false;
        bytes memory appConfigForReceiving = abi.encode(
            IThunderbirdReceiveModule.AppConfig(
                oracle,
                relayer,
                mockThunderbirdV1RecsContract,
                emitMsgProofs,
                directMsgsEnabled,
                msgDeliveryPaused
            )
        );

        uint256 size;
        assembly {
            size := extcodesize(mockThunderbirdV1AppAddress)
        }

        if (size > 0) {
            vm.startBroadcast(deployerPrivateKey);

            bytes32 currentAppConfigsForSendingHash;
            try IEarlybirdEndpoint(earlybirdEndpointAddress).getAppConfigForSending(mockThunderbirdV1AppAddress) returns (bytes memory currentConfigsForSending) {
                currentAppConfigsForSendingHash = keccak256(currentConfigsForSending);
            } catch {}

            bytes32 currentAppConfigsForReceivingHash;
            try IEarlybirdEndpoint(earlybirdEndpointAddress).getAppConfigForReceiving(mockThunderbirdV1AppAddress) returns (bytes memory currentConfigsForReceiving) {
                currentAppConfigsForReceivingHash = keccak256(currentConfigsForReceiving);
            } catch {}
            
            bool sameConfigsForSending = (currentAppConfigsForSendingHash == keccak256(appConfigForSending));
            bool sameConfigsForReceiving = (currentAppConfigsForReceivingHash == keccak256(appConfigForReceiving));
            if (sameConfigsForSending && sameConfigsForReceiving) {
                console.log("MockThunderbirdV1App configs already set");
            } else {
                MockApp(mockThunderbirdV1AppAddress).setLibraryAndConfigs(
                    "Thunderbird V1",
                    appConfigForSending,
                    appConfigForReceiving
                );
                console.log("MockThunderbirdV1App configs set");
            }
            vm.stopBroadcast();

            console.log("MockThunderbirdV1App exists on %s at %s", chainName, mockThunderbirdV1AppAddress);
            console.log("MockThunderbirdV1App configs for sending - selfBroadcasting: %s, oracle: %s, relayer: %s", selfBroadcasting, oracle, relayer);
            console.log("MockThunderbirdV1App configs for receiving - oracle: %s, relayer: %s, recsContract: %s", oracle, relayer, mockThunderbirdV1RecsContract);
            console.log("MockThunderbirdV1App configs for receiving - emitMsgProofs: %s, directMsgsEnabled: %s, msgDeliveryPaused: %s", emitMsgProofs, directMsgsEnabled, msgDeliveryPaused);
        }
    }
}

contract MockThunderbirdV1AppSendMessage is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(
            vm.envString("SENDING_MNEMONICS"),
            uint32(vm.envUint("SENDING_KEY_INDEX"))
        );
        
        IRequiredModuleFunctions.AdditionalParams memory additionalParams = IRequiredModuleFunctions.AdditionalParams(
            address(0), // address feeToken;
            true,       // bool isOrderedMsg;
            450000,     // uint256 destinationGas;
            // when using address 0, it will use the default relayer fee collector from the AppConfig
            address(0) // address expectedRelayerFeeCollector;
        );

        vm.startBroadcast(deployerPrivateKey);
        MockApp(vm.envAddress("MOCK_THUNDERBIRD_V1_APP_ADDRESS")).sendMessage(
            vm.envBytes32("RECEIVER_EARLYBIRD_INSTANCE_ID"),
            abi.encode(vm.envAddress("RECEIVER_ADDRESS")),
            vm.envString("MESSAGE_STRING"),
            abi.encode(additionalParams)
        );
        vm.stopBroadcast();
        console.log("sent message on Thunderbird via Thunderbird mock app");
    }
}

contract MockThunderbirdV1AppGetAllMessages is Script {
    function run() external view {
        address mockAppAddress = vm.envAddress("MOCK_THUNDERBIRD_V1_APP_ADDRESS");
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
