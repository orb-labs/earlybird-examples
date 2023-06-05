// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/DisputersContract.sol";
import "earlybird/src/Endpoint/IEndpoint/IEndpoint.sol";

contract DisputersContractDeployment is Script {
    function run() external {
        // get mnemonics and key indexes for app, oracle, relayer from env vars
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");
        string memory chainName = vm.envString("CHAIN_NAME");
        address payable expectedEarlybirdEndpointAdddress = payable(
            vm.envAddress("EXPECTED_EARLYBIRD_ENDPOINT_ADDRESS")
        );

        // expected address
        address expectedRukhVersionPingPongDisputersContractAddress = vm.envAddress(
            "EXPECTED_RUKH_VERSION_PINGPONG_DISPUTERS_CONTRACT_ADDRESS"
        );

        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));
        uint256 size = 0;

        assembly {
            size := extcodesize(expectedRukhVersionPingPongDisputersContractAddress)
        }

        if (size == 0) {
            IEndpoint endpoint = IEndpoint(expectedEarlybirdEndpointAdddress);
            (, address expectedRukhLibraryReceiveModuleAddress, bool isDeprecated) = endpoint.getLibraryInfo("Rukh V1");

            if (!isDeprecated) {
                address expectedRukhVersionPingPongAddress = vm.envAddress("EXPECTED_RUKH_VERSION_PINGPONG_ADDRESS");

                vm.startBroadcast(deployerPrivateKey);
                DisputersContract disputersContract = new DisputersContract(
                    expectedRukhVersionPingPongAddress,
                    expectedRukhLibraryReceiveModuleAddress
                );
                vm.stopBroadcast();

                string memory storagePath = string.concat(
                    "script/deploymentScripts/RukhVersion/addresses/",
                    vm.envString("ADDRESS_FOLDER"),
                    "/",
                    chainName,
                    "/disputers_contract.txt"
                );

                string memory appAddress = vm.toString(address(disputersContract));
                vm.writeFile(storagePath, appAddress);
                console.log("Rukh Version PingPong DisputersContract deployed on %s", chainName);
            } else {
                console.log("Rukh V1 has not been deployed yet");
            }
        } else {
            console.log("Rukh Version PingPong DisputersContract already deployed on %s", chainName);
        }
    }
}
