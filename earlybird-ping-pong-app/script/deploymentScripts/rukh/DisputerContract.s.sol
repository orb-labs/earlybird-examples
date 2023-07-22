// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/DisputerContract.sol";
import "earlybird/src/Endpoint/IEndpoint/IEndpoint.sol";

contract DisputerContractDeployment is Script {
    function run() external {
        // get mnemonics and key indexes for app, oracle, relayer from env vars
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));

        string memory chainName = vm.envString("CHAIN_NAME");

        address expectedRukhVersionPingPongDisputerContractAddress = vm.envAddress(
            "EXPECTED_RUKH_VERSION_PINGPONG_DISPUTER_CONTRACT_ADDRESS"
        );

        uint256 size = 0;
        assembly {
            size := extcodesize(expectedRukhVersionPingPongDisputerContractAddress)
        }

        if (size == 0) {
            IEndpoint endpoint = IEndpoint(vm.envAddress("EARLYBIRD_ENDPOINT_ADDRESS"));
            (,, address rukhLibraryReceiveModuleAddress, bool isDeprecated) = endpoint.getLibraryInfo("Rukh V1");

            if (!isDeprecated) {
                address rukhVersionPingPongAddress = vm.envAddress("EXPECTED_RUKH_VERSION_PINGPONG_APP_ADDRESS");

                vm.startBroadcast(deployerPrivateKey);
                DisputerContract disputerContract = new DisputerContract(
                    rukhVersionPingPongAddress,
                    rukhLibraryReceiveModuleAddress
                );
                vm.stopBroadcast();

                string memory storagePath = string.concat(
                    "addresses/",
                    vm.envString("ENVIRONMENT"),
                    "/",
                    chainName,
                    "/rukh/disputer_contract.txt"
                );

                string memory appAddress = vm.toString(address(disputerContract));
                vm.writeFile(storagePath, appAddress);
                console.log("Rukh Version PingPong DisputerContract deployed on %s", chainName);
            } else {
                console.log("This library has been deprecated.  DisputerContract not deployed");
            }
        } else {
            console.log("Rukh Version PingPong DisputerContract already deployed on %s", chainName);
        }
    }
}
