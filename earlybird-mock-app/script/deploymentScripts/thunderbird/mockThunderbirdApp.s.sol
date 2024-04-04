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
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");
        string memory chainName = vm.envString("CHAIN_NAME");
        address expectedMockAppAddress = vm.envAddress("EXPECTED_MOCK_THUNDERBIRD_APP_ADDRESS");
        address endpointAddress = vm.envAddress("EARLYBIRD_ENDPOINT_ADDRESS");
        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));
        string memory storagePath = string.concat("addresses/", vm.envString("ENVIRONMENT"), "/", chainName, "/thunderbird/app.txt");

        uint256 size;
        assembly {
            size := extcodesize(expectedMockAppAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockApp app = new MockApp(
                endpointAddress,
                address(0)
            );
            vm.stopBroadcast();

            vm.writeFile(storagePath, vm.toString(address(app)));
            console.log("MockThunderbirdApp deployed on %s", chainName);
            console.log("using endpoint address: ", endpointAddress);
        }
    }
}

contract MockThunderbirdAppConfigsUpdate is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");
        string memory chainName = vm.envString("CHAIN_NAME");
        address mockAppAddress = vm.envAddress("MOCK_THUNDERBIRD_APP_ADDRESS");
        address endpointAddress = vm.envAddress("EARLYBIRD_ENDPOINT_ADDRESS");
        address oracle = vm.envAddress("ORACLE_ADDRESS");
        address relayer = vm.envAddress("RELAYER_ADDRESS");
        address thunderbirdRecsContract = vm.envAddress("THUNDERBIRD_RECS_CONTRACT_ADDRESS");
        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));

        bool selfBroadcasting = false;
        bytes memory appConfigForSending = abi.encode(
            ISharedSendModule.AppConfig(
                selfBroadcasting,
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
                thunderbirdRecsContract,
                emitMsgProofs,
                directMsgsEnabled,
                msgDeliveryPaused
            )
        );

        uint256 size;
        assembly {
            size := extcodesize(mockAppAddress)
        }

        if (size > 0) {
            console.log("MockThunderbirdApp exists on %s at %s", chainName, mockAppAddress);
            vm.startBroadcast(deployerPrivateKey);

            bytes32 currentAppConfigsForSendingHash;
            try IEndpoint(endpointAddress).getAppConfigForSending(mockAppAddress) returns (bytes memory currentConfigsForSending) {
                currentAppConfigsForSendingHash = keccak256(currentConfigsForSending);
            } catch {}

            bytes32 currentAppConfigsForReceivingHash;
            try IEndpoint(endpointAddress).getAppConfigForReceiving(mockAppAddress) returns (bytes memory currentConfigsForReceiving) {
                currentAppConfigsForReceivingHash = keccak256(currentConfigsForReceiving);
            } catch {}
            
            bool sameConfigsForSending = (currentAppConfigsForSendingHash == keccak256(appConfigForSending));
            bool sameConfigsForReceiving = (currentAppConfigsForReceivingHash == keccak256(appConfigForReceiving));

            if (sameConfigsForSending && sameConfigsForReceiving) {
                console.log("Configs already set");
            } else {
                MockApp(mockAppAddress).setLibraryAndConfigs(
                    "Thunderbird V1",
                    appConfigForSending,
                    appConfigForReceiving
                );
                console.log("Setting configs");
            }
            vm.stopBroadcast();

            
            console.log("MockThunderbirdApp configs for sending - selfBroadcasting: %s, oracle: %s, relayer: %s", selfBroadcasting, oracle, relayer);
            console.log("MockThunderbirdApp configs for receiving - oracle: %s, relayer: %s, recsContract: %s", oracle, relayer, thunderbirdRecsContract);
            console.log("MockThunderbirdApp configs for receiving - emitMsgProofs: %s, directMsgsEnabled: %s, msgDeliveryPaused: %s", emitMsgProofs, directMsgsEnabled, msgDeliveryPaused);
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
