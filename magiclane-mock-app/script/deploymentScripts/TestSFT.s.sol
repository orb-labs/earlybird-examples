// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../utils/TestSFT.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract TestSFTDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));
        uint256 sendingPrivateKey =
            vm.deriveKey(vm.envString("SENDING_MNEMONICS"), uint32(vm.envUint("SENDING_KEY_INDEX")));
        string memory chainName = vm.envString("CHAIN_NAME");

        for (uint256 i = 0; i < 10; i++) {
            string memory testSFTEnvName = string.concat("EXPECTED_TEST_FT_ADDRESSES_", Strings.toString(i));
            address expectedTestSFTAddress = vm.envAddress(testSFTEnvName);

            uint256 size = 0;
            assembly {
                size := extcodesize(expectedTestSFTAddress)
            }

            string memory testSFTName = string.concat("TestSFT-", Strings.toString(i));
            if (size == 0) {
                vm.startBroadcast(deployerPrivateKey);
                TestSFT testSFT = new TestSFT();
                testSFT.mint(vm.addr(sendingPrivateKey), i, 100_000_000);
                vm.stopBroadcast();

                string memory storagePath = string.concat(
                    "addresses/", vm.envString("ENVIRONMENT"), "/", chainName, "/TestSFTs", "/", testSFTName, ".txt"
                );

                string memory testSFTAddress = vm.toString(address(testSFT));
                vm.writeFile(storagePath, testSFTAddress);
                console.log("%s deployed on %s at %s", testSFTName, chainName, testSFTAddress);
            } else {
                console.log("%s already found on %s at %s", testSFTName, chainName, expectedTestSFTAddress);
            }
        }
    }
}
