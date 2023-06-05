// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/MockApp.sol";

contract MockRukhAppDeployment is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");

        string memory oracleMnemonics = vm.envString("ORACLE_MNEMONICS");
        uint256 oracleKeyIndex = vm.envUint("ORACLE_KEY_INDEX");

        string memory relayerMnemonics = vm.envString("RELAYER_MNEMONICS");
        uint256 relayerKeyIndex = vm.envUint("RELAYER_KEY_INDEX");

        string memory disputeResolverMnemonics = vm.envString("DISPUTE_RESOLVER_MNEMONICS");
        uint256 disputeResolverKeyIndex = vm.envUint("DISPUTE_RESOLVER_KEY_INDEX");

        bool directMsgsEnabled = true;

        address expectedEarlybirdEndpointAdddress = vm.envAddress("EXPECTED_EARLYBIRD_ENDPOINT_ADDRESS");
        address rukhOutOracle = vm.envAddress("EXPECTED_MOCK_RUKH_ORACLE_ADDRESS");
        address rukhOutRelayer = vm.envAddress("EXPECTED_MOCK_RUKH_RELAYER_ADDRESS");
        address rukhRecsContract = vm.envAddress("EXPECTED_MOCK_RUKH_RECS_CONTRACT_ADDRESS");
        address disputerContract = vm.envAddress("EXPECTED_MOCK_RUKH_DISPUTER_CONTRACT_ADDRESS");

        string memory chainName = vm.envString("CHAIN_NAME");
        string memory addressFolder = vm.envString("ADDRESS_FOLDER");
        address expectedMockAppAddress = vm.envAddress("EXPECTED_MOCK_RUKH_APP_ADDRESS");

        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockAppAddress)
        }

        if (size == 0) {
            uint256 rukhInOraclePrivateKey = vm.deriveKey(oracleMnemonics, uint32(oracleKeyIndex));
            uint256 rukhInRelayerPrivateKey = vm.deriveKey(relayerMnemonics, uint32(relayerKeyIndex));
            uint256 rukhDisputerResolverPrivateKey = vm.deriveKey(
                disputeResolverMnemonics,
                uint32(disputeResolverKeyIndex)
            );
            address rukhInOracle = vm.addr(rukhInOraclePrivateKey);
            address rukhInRelayer = vm.addr(rukhInRelayerPrivateKey);
            address rukhDisputerResolver = vm.addr(rukhDisputerResolverPrivateKey);

            console.log(expectedEarlybirdEndpointAdddress);

            vm.startBroadcast(deployerPrivateKey);
            MockApp app = new MockApp(expectedEarlybirdEndpointAdddress, address(0), directMsgsEnabled);

            bytes memory sendModuleConfigs = abi.encode(false, rukhOutOracle, rukhOutRelayer);
            bytes memory receiveModuleConfigs = abi.encode(
                10, //minDisputeTime,
                10, // minDisputeResolutionExtension,
                100, //disputeEpochLength,
                1, //maxValidDisputesPerEpoch,
                rukhInOracle, //_receivingOracle,
                rukhInRelayer, //_receiveDefaultRelayer,
                disputerContract, //_disputersContract,
                rukhDisputerResolver, //_disputeResolver,
                rukhRecsContract, //recsContract,
                true, // emitMsgProofs,
                directMsgsEnabled, // directMsgsEnabled,
                false // msgDeliveryPaused
            );

            app.setLibraryAndConfigs("Rukh V1", sendModuleConfigs, receiveModuleConfigs);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "script/deploymentScripts/mockRukhApp/addresses/",
                addressFolder,
                "/",
                chainName,
                ".txt"
            );

            string memory mockAppAddress = vm.toString(address(app));
            vm.writeFile(storagePath, mockAppAddress);
            console.log("MockRukhAppAddress deployed on %s", chainName);
        } else {
            uint256 rukhInOraclePrivateKey = vm.deriveKey(oracleMnemonics, uint32(oracleKeyIndex));
            uint256 rukhInRelayerPrivateKey = vm.deriveKey(relayerMnemonics, uint32(relayerKeyIndex));
            uint256 rukhDisputerResolverPrivateKey = vm.deriveKey(
                disputeResolverMnemonics,
                uint32(disputeResolverKeyIndex)
            );
            address rukhInOracle = vm.addr(rukhInOraclePrivateKey);
            address rukhInRelayer = vm.addr(rukhInRelayerPrivateKey);
            address rukhDisputerResolver = vm.addr(rukhDisputerResolverPrivateKey);
            console.log(expectedEarlybirdEndpointAdddress);

            vm.startBroadcast(deployerPrivateKey);
            MockApp app = MockApp(expectedMockAppAddress);
            bytes memory sendModuleConfigs = abi.encode(false, rukhOutOracle, rukhOutRelayer);
            bytes memory receiveModuleConfigs = abi.encode(
                10, //minDisputeTime,
                10, // minDisputeResolutionExtension,
                100, //disputeEpochLength,
                1, //maxValidDisputesPerEpoch,
                rukhInOracle, //_receivingOracle,
                rukhInRelayer, //_receiveDefaultRelayer,
                disputerContract, //_disputersContract,
                rukhDisputerResolver, //_disputeResolver,
                rukhRecsContract, //recsContract,
                true, // emitMsgProofs,
                directMsgsEnabled, // directMsgsEnabled,
                false // msgDeliveryPaused
            );
            app.setLibraryAndConfigs("Rukh V1", sendModuleConfigs, receiveModuleConfigs);
            vm.stopBroadcast();

            console.log("MockRukhAppAddress already deployed on %s", chainName);
            console.log("Resetting configs");
        }
    }
}

contract MockRukhAppSendMessage is Script {
    function run() external {
        string memory sendingMnemonics = vm.envString("SENDING_MNEMONICS");
        uint256 sendingKeyIndex = vm.envUint("SENDING_KEY_INDEX");

        address mockAppAddress = vm.envAddress("MOCK_RUKH_APP_ADDRESS");
        uint256 receiverChainId = vm.envUint("RECEIVER_CHAIN_ID");
        address receiverAddress = vm.envAddress("RECEIVER_ADDRESS");
        string memory messageString = vm.envString("MESSAGE_STRING");

        uint256 deployerPrivateKey = vm.deriveKey(sendingMnemonics, uint32(sendingKeyIndex));

        bytes memory additionalParams = abi.encode(address(0), true, 5000000);

        vm.startBroadcast(deployerPrivateKey);
        MockApp(mockAppAddress).sendMessage(
            receiverChainId,
            abi.encode(receiverAddress),
            messageString,
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
