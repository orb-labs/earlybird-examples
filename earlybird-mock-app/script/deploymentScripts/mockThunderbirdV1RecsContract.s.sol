// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/ThunderbirdVersion/RecsContract.sol";

contract MockThunderbirdV1RecsContractDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));
        string memory chainName = vm.envString("CHAIN_NAME");

        address expectedThunderbirdV1RecsContract = vm.envAddress("EXPECTED_MOCK_THUNDERBIRD_V1_RECS_CONTRACT_ADDRESS");
        string memory storagePath = string.concat("addresses/", vm.envString("ENVIRONMENT"), "/", chainName, "/mockThunderbirdV1RecsContract.txt");
        
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedThunderbirdV1RecsContract)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            RecsContract thunderbirdV1RecsContract = new RecsContract(vm.envAddress("RELAYER_ADDRESS"));
            vm.stopBroadcast();

            string memory thunderbirdV1RecsContractAddress = vm.toString(address(thunderbirdV1RecsContract));
            vm.writeFile(storagePath, thunderbirdV1RecsContractAddress);
            console.log("MockThunderbirdV1RecsContract deployed on: %s, at: %s", chainName, thunderbirdV1RecsContractAddress);
        } else {
            string memory thunderbirdV1RecsContractAddress = vm.toString(expectedThunderbirdV1RecsContract);
            vm.writeFile(storagePath, thunderbirdV1RecsContractAddress);
            console.log("MockThunderbirdV1RecsContract already deployed on: %s, at: %s", chainName, thunderbirdV1RecsContractAddress);
        }
    }
}
