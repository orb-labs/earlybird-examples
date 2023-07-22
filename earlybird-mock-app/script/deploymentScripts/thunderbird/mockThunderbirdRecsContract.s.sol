// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/ThunderbirdVersion/MockRecsContract.sol";

contract MockThunderbirdRecsContractDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));

        string memory chainName = vm.envString("CHAIN_NAME");
        
        address expectedMockThunderbirdRecsContract = vm.envAddress("EXPECTED_MOCK_THUNDERBIRD_RECS_CONTRACT_ADDRESS");
        
        address sendingRelayer = vm.envAddress("MOCK_SENDING_RELAYER_ADDRESS");

        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockThunderbirdRecsContract)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockRecsContract mockThunderbirdRecsContract = new MockRecsContract(sendingRelayer);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "addresses/",
                vm.envString("ENVIRONMENT"),
                "/",
                chainName,
                "/thunderbird/app.txt"
            );

            string memory mockThunderbirdRecsContractAddress = vm.toString(address(mockThunderbirdRecsContract));
            vm.writeFile(storagePath, mockThunderbirdRecsContractAddress);
            console.log("MockThunderbirdRecsContract deployed on %s", chainName);
        } else {
            console.log("MockThunderbirdRecsContract already deployed on %s", chainName);
        }
    }
}
