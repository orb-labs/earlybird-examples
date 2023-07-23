// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/FeeCollector.sol";

contract SendingOracleDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));
        
        string memory chainName = vm.envString("CHAIN_NAME");
        
        address expectedSendingOracleAddress = vm.envAddress("EXPECTED_SENDING_ORACLE_ADDRESS");

        uint256 size = 0;
        assembly {
            size := extcodesize(expectedSendingOracleAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            FeeCollector sendingOracle = new FeeCollector();
            sendingOracle.updateNativeTokenFee(true, 0);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "addresses/",
                vm.envString("ENVIRONMENT"),
                "/",
                chainName,
                "/sending_oracle.txt"
            );

            string memory sendingOracleAddress = vm.toString(address(sendingOracle));
            vm.writeFile(storagePath, sendingOracleAddress);
            console.log("SendingOracle deployed on %s", chainName);
        } else {
            console.log("SendingOracle already deployed on %s", chainName);
        }
    }
}
