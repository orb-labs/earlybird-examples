// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/RukhVersion/RecsContract.sol";

contract MockRukhV1RecsContractDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));
        string memory chainName = vm.envString("CHAIN_NAME");
        address expectedMockRukhV1RecsContract = vm.envAddress("EXPECTED_MOCK_RUKH_V1_RECS_CONTRACT_ADDRESS");
        string memory storagePath = string.concat("addresses/", vm.envString("ENVIRONMENT"), "/", chainName, "/mockRukhV1RecsContract.txt");
        
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockRukhV1RecsContract)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            RecsContract mockRukhV1RecsContract = new RecsContract(vm.envAddress("RELAYER_ADDRESS"));
            vm.stopBroadcast();

            string memory mockRukhV1RecsContractAddress = vm.toString(address(mockRukhV1RecsContract));
            vm.writeFile(storagePath, mockRukhV1RecsContractAddress);
            console.log("MockRukhV1RecsContract deployed on: %s, at: %s", chainName, mockRukhV1RecsContractAddress);
        } else {
            string memory mockRukhV1RecsContractAddress = vm.toString(expectedMockRukhV1RecsContract);
            vm.writeFile(storagePath, mockRukhV1RecsContractAddress);
            console.log("MockRukhV1RecsContract already deployed on: %s at: %s", chainName, mockRukhV1RecsContractAddress);
        }
    }
}
