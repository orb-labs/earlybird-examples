// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/ThunderbirdVersion/RecsContract.sol";

contract ThunderbirdRecsContractDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));

        string memory chainName = vm.envString("CHAIN_NAME");
        
        address expectedThunderbirdRecsContract = vm.envAddress("EXPECTED_THUNDERBIRD_RECS_CONTRACT_ADDRESS");
        
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedThunderbirdRecsContract)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            RecsContract thunderbirdRecsContract = new RecsContract(vm.envAddress("RELAYER_ADDRESS"));
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "addresses/",
                vm.envString("ENVIRONMENT"),
                "/",
                chainName,
                "/thunderbird/recs_contract.txt"
            );

            string memory thunderbirdRecsContractAddress = vm.toString(address(thunderbirdRecsContract));
            vm.writeFile(storagePath, thunderbirdRecsContractAddress);
            console.log("ThunderbirdRecsContract deployed on %s", chainName);
        } else {
            console.log("ThunderbirdRecsContract already deployed on %s", chainName);
        }
    }
}
