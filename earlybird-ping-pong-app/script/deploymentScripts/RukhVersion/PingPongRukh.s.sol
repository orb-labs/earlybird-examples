// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/PingPong.sol";

contract PingPongRukhDeployment is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");

        // expected app address
        address expectedRukhVersionPingPongAddress = vm.envAddress("EXPECTED_RUKH_VERSION_PINGPONG_ADDRESS");

        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));
        string memory chainName = vm.envString("CHAIN_NAME");
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedRukhVersionPingPongAddress)
        }

        if (size == 0) {
            address rukhReceivingRelayer = vm.addr(
                vm.deriveKey(vm.envString("RELAYER_MNEMONICS"), uint32(vm.envUint("RELAYER_KEY_INDEX")))
            );

            vm.startBroadcast(deployerPrivateKey);
            PingPong app = new PingPong(
                address(vm.envAddress("EXPECTED_EARLYBIRD_ENDPOINT_ADDRESS")),
                address(vm.envAddress("EXPECTED_RUKH_VERSION_PINGPONG_SENDING_ORACLE_ADDRESS")),
                address(vm.envAddress("EXPECTED_RUKH_VERSION_PINGPONG_SENDING_RELAYER_ADDRESS")),
                vm.addr(vm.deriveKey(vm.envString("ORACLE_MNEMONICS"), uint32(vm.envUint("ORACLE_KEY_INDEX")))),
                rukhReceivingRelayer,
                rukhReceivingRelayer,
                address(vm.envAddress("EXPECTED_RUKH_VERSION_PINGPONG_DISPUTERS_CONTRACT_ADDRESS")),
                address(vm.envAddress("EXPECTED_RUKH_VERSION_PINGPONG_DISPUTERS_CONTRACT_ADDRESS"))
            );
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "script/deploymentScripts/RukhVersion/addresses/",
                vm.envString("ADDRESS_FOLDER"),
                "/",
                chainName,
                "/app.txt"
            );

            string memory appAddress = vm.toString(address(app));
            vm.writeFile(storagePath, appAddress);
            console.log("Rukh Version PingPong App deployed on %s", chainName);
        } else {
            console.log("Rukh Version PingPong App already deployed on %s", chainName);
        }
    }
}

contract MockRukhPingPongAppSendPing is Script {
    function run() external {
        string memory sendingMnemonics = vm.envString("SENDING_MNEMONICS");
        uint256 sendingKeyIndex = vm.envUint("SENDING_KEY_INDEX");

        address payable mockPingPongAppAddress = payable(vm.envAddress("MOCK_RUKH_PING_PONG_APP_ADDRESS"));
        uint256 receiverChainId = vm.envUint("RECEIVER_CHAIN_ID");
        address receiverAddress = vm.envAddress("RECEIVER_ADDRESS");
        uint256 pings = vm.envUint("PINGS");

        uint256 deployerPrivateKey = vm.deriveKey(sendingMnemonics, uint32(sendingKeyIndex));

        vm.startBroadcast(deployerPrivateKey);
        PingPong(mockPingPongAppAddress).ping(receiverChainId, receiverAddress, pings);
        vm.stopBroadcast();
    }
}
