// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/RecsContract.sol";

contract RukhRecsContractDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));

        string memory chainName = vm.envString("CHAIN_NAME");
        address expectedRukhRecsContract = vm.envAddress("EXPECTED_RUKH_RECS_CONTRACT_ADDRESS");
        
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedRukhRecsContract)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            RecsContract rukhRecsContract = new RecsContract(vm.envAddress("RELAYER_ADDRESS"));
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "addresses/",
                vm.envString("ENVIRONMENT"),
                "/",
                chainName,
                "/rukh/recs_contract.txt"
            );

            string memory rukhRecsContractAddress = vm.toString(address(rukhRecsContract));
            vm.writeFile(storagePath, rukhRecsContractAddress);
            console.log("RukhRecsContract deployed on %s", chainName);
        } else {
            console.log("RukhRecsContract already deployed on %s", chainName);
        }
    }
}
