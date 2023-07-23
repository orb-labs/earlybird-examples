// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/DisputerContract.sol";

contract RukhDisputerContractDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));

        string memory chainName = vm.envString("CHAIN_NAME");
        
        address expectedRukhDisputerContract = vm.envAddress("EXPECTED_RUKH_DISPUTER_CONTRACT_ADDRESS");

        uint256 size = 0;
        assembly {
            size := extcodesize(expectedRukhDisputerContract)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            DisputerContract rukhDisputerContract = new DisputerContract();
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "addresses/",
                vm.envString("ENVIRONMENT"),
                "/",
                chainName,
                "/rukh/disputer_contract.txt"
            );

            string memory rukhDisputerContractAddress = vm.toString(address(rukhDisputerContract));
            vm.writeFile(storagePath, rukhDisputerContractAddress);
            console.log("RukhDisputerContract deployed on %s", chainName);
        } else {
            console.log("RukhDisputerContract already deployed on %s", chainName);
        }
    }
}
