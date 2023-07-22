// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/MockRecsContract.sol";

contract MockRukhRecsContractDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));

        string memory chainName = vm.envString("CHAIN_NAME");
        
        address expectedMockRukhRecsContract = vm.envAddress("EXPECTED_MOCK_RUKH_RECS_CONTRACT_ADDRESS");
        
        address sendingRelayer = vm.envAddress("MOCK_SENDING_RELAYER_ADDRESS");
        
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockRukhRecsContract)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockRecsContract mockRukhRecsContract = new MockRecsContract(sendingRelayer);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "addresses/",
                vm.envString("ENVIRONMENT"),
                "/",
                chainName,
                "/rukh/recs_contract.txt"
            );

            string memory mockRukhRecsContractAddress = vm.toString(address(mockRukhRecsContract));
            vm.writeFile(storagePath, mockRukhRecsContractAddress);
            console.log("MockRukhRecsContract deployed on %s", chainName);
        } else {
            console.log("MockRukhRecsContract already deployed on %s", chainName);
        }
    }
}
