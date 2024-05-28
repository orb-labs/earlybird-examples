// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/RukhVersion/MockApp.sol";
import "../../lib/earlybird-evm-interfaces/src/Libraries/Rukh/IRukhReceiveModule.sol";
import "../../lib/earlybird-evm-interfaces/src/Libraries/SharedLibraryModules/ISharedSendModule.sol";
import "../../lib/earlybird-evm-interfaces/src/Libraries/ILibrary/IRequiredModuleFunctions.sol";


contract MockRukhV1AppDeployment is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        string memory chainName = vm.envString("CHAIN_NAME");
        uint256 keyIndex = vm.envUint("KEY_INDEX");
        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));

        address expectedMockRukhV1AppAddress = vm.envAddress("EXPECTED_MOCK_RUKH_V1_APP_ADDRESS");
        address earlybirdEndpointAddress = vm.envAddress("EARLYBIRD_ENDPOINT_ADDRESS");
        string memory storagePath = string.concat("addresses/", vm.envString("ENVIRONMENT"), "/", chainName, "/mockRukhV1App.txt");

        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockRukhV1AppAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockApp app = new MockApp(
                earlybirdEndpointAddress,
                address(0)
            );
            vm.stopBroadcast();

            string memory mockRukhV1AppAddress = vm.toString(address(app));
            vm.writeFile(storagePath, mockRukhV1AppAddress);
            console.log("MockRukhV1App deployed on: %s, at: %s, using earlybird endpoint address at: %s", chainName, mockRukhV1AppAddress, earlybirdEndpointAddress);
        } else {
            string memory mockRukhV1AppAddress = vm.toString(expectedMockRukhV1AppAddress);
            vm.writeFile(storagePath, vm.toString(expectedMockRukhV1AppAddress));
            console.log("MockRukhV1App deployed on: %s, at: %s, using earlybird endpoint address at: %s", chainName, mockRukhV1AppAddress, earlybirdEndpointAddress);
        }
    }
}

contract MockRukhV1AppConfigsUpdate is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        string memory chainName = vm.envString("CHAIN_NAME");
        uint256 keyIndex = vm.envUint("KEY_INDEX");
        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));

        address mockRukhV1AppAddress = vm.envAddress("MOCK_RUKH_V1_APP_ADDRESS");
        address earlybirdEndpointAddress = vm.envAddress("EARLYBIRD_ENDPOINT_ADDRESS");
        address oracle = vm.envAddress("ORACLE_ADDRESS");
        address relayer = vm.envAddress("RELAYER_ADDRESS");
        address disputerContract = vm.envAddress("RUKH_DISPUTER_CONTRACT_ADDRESS");
        address disputeResolverContract = vm.envAddress("RUKH_DISPUTE_RESOLVER_CONTRACT_ADDRESS");
        address mockRukhV1RecsContract = vm.envAddress("MOCK_RUKH_V1_RECS_CONTRACT_ADDRESS");

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
                mockRukhV1RecsContract, 
                emitMsgProofs,
                directMsgsEnabled,
                msgDeliveryPaused
            )
        );
        
        uint256 size = 0;
        assembly {
            size := extcodesize(mockRukhV1AppAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);

            bytes32 currentAppConfigsForSendingHash;
            try IEndpoint(earlybirdEndpointAddress).getAppConfigForSending(mockRukhV1AppAddress) returns (bytes memory currentConfigsForSending) {
                currentAppConfigsForSendingHash = keccak256(currentConfigsForSending);
            } catch {}

            bytes32 currentAppConfigsForReceivingHash;
            try IEndpoint(earlybirdEndpointAddress).getAppConfigForReceiving(mockRukhV1AppAddress) returns (bytes memory currentConfigsForReceiving) {
                currentAppConfigsForReceivingHash = keccak256(currentConfigsForReceiving);
            } catch {}
            
            bool sameConfigsForSending = (currentAppConfigsForSendingHash == keccak256(appConfigForSending));
            bool sameConfigsForReceiving = (currentAppConfigsForReceivingHash == keccak256(appConfigForReceiving));

            if (sameConfigsForSending && sameConfigsForReceiving) {
                console.log("MockRukhV1App configs already set");
            } else {
                MockApp(mockRukhV1AppAddress).setLibraryAndConfigs(
                    "Rukh V1",
                    appConfigForSending,
                    appConfigForReceiving
                );
                console.log("MockRukhV1App configs set");
            }
            vm.stopBroadcast();

            console.log("MockRukhV1App exists on %s at %s", chainName, mockRukhV1AppAddress);
            console.log("MockRukhV1App configs for sending - selfBroadcasting: %s, oracle: %s, relayer: %s", selfBroadcasting, oracle, relayer);
            console.log("MockRukhV1App configs for receiving - minDisputeTime: %s, minDisputeResolutionExtension: %s, disputeEpochLength: %s", minDisputeTime, minDisputeResolutionExtension, disputeEpochLength);
            console.log("MockRukhV1App configs for receiving - oracle: %s, relayer: %s, maxValidDisputesPerEpoch: %s", oracle, relayer, maxValidDisputesPerEpoch);
            console.log("MockRukhV1App configs for receiving - disputerContract: %s, disputeResolverContract: %s, recsContract: %s", disputerContract, disputeResolverContract, mockRukhV1RecsContract);
            console.log("MockRukhV1App configs for receiving - emitMsgProofs: %s, directMsgsEnabled: %s, msgDeliveryPaused: %s", emitMsgProofs, directMsgsEnabled, msgDeliveryPaused);
        }
    }
}

contract MockRukhV1AppSendMessage is Script {
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

        MockApp(vm.envAddress("MOCK_RUKH_V1_APP_ADDRESS")).sendMessage(
            vm.envBytes32("RECEIVER_EARLYBIRD_INSTANCE_ID"),
            abi.encode(vm.envAddress("RECEIVER_ADDRESS")),
            vm.envString("MESSAGE_STRING"),
            abi.encode(additionalParams)
        );
        vm.stopBroadcast();
    }
}

contract MockRukhV1AppGetAllMessages is Script {
    function run() external view {
        address mockAppAddress = vm.envAddress("MOCK_RUKH_V1_APP_ADDRESS");
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
