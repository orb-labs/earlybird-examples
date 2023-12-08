// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../utils/TestNFT.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract TestNFTDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));
        uint256 sendingPrivateKey =
            vm.deriveKey(vm.envString("SENDING_MNEMONICS"), uint32(vm.envUint("SENDING_KEY_INDEX")));
        string memory chainName = vm.envString("CHAIN_NAME");

        for (uint256 i = 0; i < 10; i++) {
            string memory testNFTEnvName = string.concat("EXPECTED_TEST_NFT_ADDRESSES_", Strings.toString(i));
            address expectedTestNFTAddress = vm.envAddress(testNFTEnvName);

            uint256 size = 0;
            assembly {
                size := extcodesize(expectedTestNFTAddress)
            }

            string memory testNFTName = string.concat("testNFT-", Strings.toString(i));

            if (size == 0) {
                vm.startBroadcast(deployerPrivateKey);
                TestNFT testNFT = new TestNFT(testNFTName, testNFTName);
                testNFT.mint(vm.addr(sendingPrivateKey), i);
                vm.stopBroadcast();

                string memory storagePath = string.concat(
                    "addresses/", vm.envString("ENVIRONMENT"), "/", chainName, "/TestNFTs", "/", testNFTName, ".txt"
                );

                string memory testNFTAddress = vm.toString(address(testNFT));
                vm.writeFile(storagePath, testNFTAddress);
                console.log("%s deployed on %s at %s", testNFTName, chainName, testNFTAddress);
            } else {
                console.log("%s already found on %s at %s", testNFTName, chainName, expectedTestNFTAddress);
            }
        }
    }
}
