// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/MockApp.sol";
import "../../../lib/earlybird-evm-interfaces/src/Libraries/Rukh/RukhReceiveModule/IRukhReceiveModule.sol";
import "../../../lib/earlybird-evm-interfaces/src/Libraries/SharedSendModule/ISharedSendModule.sol";


contract MockRukhAppDeployment is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");
        string memory chainName = vm.envString("CHAIN_NAME");
        address expectedMockAppAddress = vm.envAddress("EXPECTED_MOCK_RUKH_APP_ADDRESS");
        address endpointAddress = vm.envAddress("EARLYBIRD_ENDPOINT_ADDRESS");
        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));
        string memory storagePath = string.concat("addresses/", vm.envString("ENVIRONMENT"), "/", chainName, "/rukh/app.txt");

        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockAppAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            bool directMsgsEnabled = true;
            MockApp app = new MockApp(
                endpointAddress, 
                address(0), 
                directMsgsEnabled
            );
            vm.stopBroadcast();

            vm.writeFile(storagePath, vm.toString(address(app)));
            console.log("MockRukhApp deployed on %s", chainName);
            console.log("using endpoint address: ", endpointAddress);
        }
    }
}

contract MockRukhAppConfigsUpdate is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");
        string memory chainName = vm.envString("CHAIN_NAME");
        address mockAppAddress = vm.envAddress("MOCK_RUKH_APP_ADDRESS");
        address endpointAddress = vm.envAddress("EARLYBIRD_ENDPOINT_ADDRESS");
        address oracle = vm.envAddress("ORACLE_ADDRESS");
        address relayer = vm.envAddress("RELAYER_ADDRESS");
        address disputerContract = vm.envAddress("RUKH_DISPUTER_CONTRACT_ADDRESS");
        address disputeResolverContract = vm.envAddress("RUKH_DISPUTE_RESOLVER_CONTRACT_ADDRESS");
        address rukhRecsContract = vm.envAddress("RUKH_RECS_CONTRACT_ADDRESS");
        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));

        bool selfBroadcasting = false;
        bytes memory appConfigForSending = abi.encode(
            ISharedSendModule.AppConfig(
                selfBroadcasting,
                oracle,
                relayer
            )
        );

        uint256 minDisputeTime = 10;
        uint256 minDisputeResolutionExtension = 10;
        uint256 disputeEpochLength = 100;
        uint256 maxValidDisputesPerEpoch = 1;
        bool emitMsgProofs = true;
        bool directMsgsEnabled = true;
        bool msgDeliveryPaused = false;
        bytes memory appConfigForReceiving = abi.encode(
            IRukhReceiveModule.AppConfig(
                minDisputeTime,
                minDisputeResolutionExtension,
                disputeEpochLength,
                maxValidDisputesPerEpoch,
                oracle,
                relayer,
                disputerContract,
                disputeResolverContract,
                rukhRecsContract, 
                emitMsgProofs,
                directMsgsEnabled,
                msgDeliveryPaused
            )
        );

        
        uint256 size = 0;
        assembly {
            size := extcodesize(mockAppAddress)
        }

        if (size == 0) {
            console.log("MockRukhApp exists on %s at %s", chainName, mockAppAddress);
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
                    "Rukh V1",
                    appConfigForSending,
                    appConfigForReceiving
                );
                console.log("Setting configs");
            }
            vm.stopBroadcast();

            console.log("MockRukhApp configs for sending - selfBroadcasting: %s, oracle: %s, relayer: %s", selfBroadcasting, oracle, relayer);
            console.log("MockRukhApp configs for receiving - minDisputeTime: %s, minDisputeResolutionExtension: %s, disputeEpochLength: %s", minDisputeTime, minDisputeResolutionExtension, disputeEpochLength);
            console.log("MockRukhApp configs for receiving - oracle: %s, relayer: %s, maxValidDisputesPerEpoch: %s", oracle, relayer, maxValidDisputesPerEpoch);
            console.log("MockRukhApp configs for receiving - disputerContract: %s, disputeResolverContract: %s, rukhRecsContract: %s", disputerContract, disputeResolverContract, rukhRecsContract);
            console.log("MockRukhApp configs for receiving - emitMsgProofs: %s, directMsgsEnabled: %s, msgDeliveryPaused: %s", emitMsgProofs, directMsgsEnabled, msgDeliveryPaused);
        }
    }
}

contract MockRukhAppSendMessage is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(
            vm.envString("SENDING_MNEMONICS"),
            uint32(vm.envUint("SENDING_KEY_INDEX"))
        );

        // Add in expectedRelayerFeeCollector as the 4th argument
        ISharedSendModule.AdditionalParams memory additionalParams = ISharedSendModule.AdditionalParams(
            address(0),
            true,
            450000,     // uint256 destinationGas;
            // when using address 0, it will use the default relayer fee collector from the AppConfig
            address(0) // address expectedRelayerFeeCollector;
        );

        vm.startBroadcast(deployerPrivateKey);

        MockApp(vm.envAddress("MOCK_RUKH_APP_ADDRESS")).sendMessage(
            vm.envBytes32("RECEIVER_EARLYBIRD_INSTANCE_ID"),
            abi.encode(vm.envAddress("RECEIVER_ADDRESS")),
            vm.envString("MESSAGE_STRING"),
            abi.encode(additionalParams)
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
