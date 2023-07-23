// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/PingPong.sol";

contract PingPongRukhDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));

        string memory chainName = vm.envString("CHAIN_NAME");
        
        // expected app address
        address expectedRukhVersionPingPongAddress = vm.envAddress("EXPECTED_RUKH_VERSION_PINGPONG_APP_ADDRESS");

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
                address(vm.envAddress("EARLYBIRD_ENDPOINT_ADDRESS")),
                address(vm.envAddress("SENDING_ORACLE_ADDRESS")),
                address(vm.envAddress("SENDING_RELAYER_ADDRESS")),
                vm.addr(vm.deriveKey(vm.envString("ORACLE_MNEMONICS"), uint32(vm.envUint("ORACLE_KEY_INDEX")))),
                rukhReceivingRelayer,
                rukhReceivingRelayer,
                address(vm.envAddress("RUKH_VERSION_PINGPONG_DISPUTER_CONTRACT_ADDRESS")),
                address(vm.envAddress("RUKH_VERSION_PINGPONG_DISPUTER_CONTRACT_ADDRESS"))
            );
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "script/addresses/",
                vm.envString("ENVIRONMENT"),
                "/",
                chainName,
                "/rukh/app.txt"
            );

            string memory appAddress = vm.toString(address(app));
            vm.writeFile(storagePath, appAddress);
            console.log("Rukh Version PingPong App deployed on %s", chainName);
        } else {
            console.log("Rukh Version PingPong App already deployed on %s", chainName);
        }
    }
}

contract RukhPingPongAppSendPing is Script {
    function run() external {
        string memory sendingMnemonics = vm.envString("SENDING_MNEMONICS");
        uint256 sendingKeyIndex = vm.envUint("SENDING_KEY_INDEX");

        address payable pingPongAppAddress = payable(vm.envAddress("RUKH_PING_PONG_APP_ADDRESS"));
        uint256 receiverChainId = vm.envUint("RECEIVER_CHAIN_ID");
        address receiverAddress = vm.envAddress("RECEIVER_ADDRESS");
        uint256 pings = vm.envUint("PINGS");

        uint256 deployerPrivateKey = vm.deriveKey(sendingMnemonics, uint32(sendingKeyIndex));

        vm.startBroadcast(deployerPrivateKey);
        PingPong(pingPongAppAddress).ping(receiverChainId, receiverAddress, pings);
        vm.stopBroadcast();
    }
}
