// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../utils/TestFT.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract TestFTDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));
        uint256 sendingPrivateKey =
            vm.deriveKey(vm.envString("SENDING_MNEMONICS"), uint32(vm.envUint("SENDING_KEY_INDEX")));
        string memory chainName = vm.envString("CHAIN_NAME");

        for (uint256 i = 0; i < 10; i++) {
            string memory testFTEnvName = string.concat("EXPECTED_TEST_FT_ADDRESSES_", Strings.toString(i));
            address expectedTestFTAddress = vm.envAddress(testFTEnvName);

            uint256 size = 0;
            assembly {
                size := extcodesize(expectedTestFTAddress)
            }

            string memory testFTName = string.concat("testFT-", Strings.toString(i));
            if (size == 0) {
                vm.startBroadcast(deployerPrivateKey);
                TestFT testFT = new TestFT(testFTName, testFTName);
                testFT.mint(vm.addr(sendingPrivateKey), 100_000_000);
                vm.stopBroadcast();

                string memory storagePath = string.concat(
                    "addresses/", vm.envString("ENVIRONMENT"), "/", chainName, "/TestFTs", "/", testFTName, ".txt"
                );

                string memory testFTAddress = vm.toString(address(testFT));
                vm.writeFile(storagePath, testFTAddress);
                console.log("%s deployed on %s at %s", testFTName, chainName, testFTAddress);
            } else {
                console.log("%s already found on %s at %s", testFTName, chainName, expectedTestFTAddress);
            }
        }
    }
}
