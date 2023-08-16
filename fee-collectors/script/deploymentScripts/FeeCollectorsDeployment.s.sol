// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/FeeCollector.sol";


contract FeeCollectorsDeployment is Script {
    function deployFeeCollector(uint256 deployerPrivateKey, string memory chainName, string memory componentName, address expectedFeeCollectorAddress) private {
        uint256 size = 0;

        assembly {
            size := extcodesize(expectedFeeCollectorAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            FeeCollector feeCollector = new FeeCollector();
            feeCollector.updateNativeTokenFee(true, 0);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "addresses/",
                vm.envString("ENVIRONMENT"),
                "/",
                chainName,
                "/",
                componentName,
                ".txt"
            );

            string memory feeCollectorAddress = vm.toString(address(feeCollector));
            vm.writeFile(storagePath, feeCollectorAddress);
            console.log("%s deployed on %s", componentName, chainName);
        } else {
            console.log("%s already found on %s at %s", componentName, chainName, expectedFeeCollectorAddress);
        }
    }

    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));
        string memory chainName = vm.envString("CHAIN_NAME");
        
        deployFeeCollector(deployerPrivateKey, chainName, "oracleFeeCollector", vm.envAddress("EXPECTED_ORACLE_FEE_COLLECTOR_ADDRESS"));
        deployFeeCollector(deployerPrivateKey, chainName, "relayerFeeCollector", vm.envAddress("EXPECTED_RELAYER_FEE_COLLECTOR_ADDRESS"));
    }       
}
