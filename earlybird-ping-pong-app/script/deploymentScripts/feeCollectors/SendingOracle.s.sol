// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/FeeCollector.sol";

contract SendingOracleDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));
        
        string memory chainName = vm.envString("CHAIN_NAME");
        
        address expectedMockSendingOracleAddress = vm.envAddress("EXPECTED_SENDING_ORACLE_ADDRESS");

        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockSendingOracleAddress)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            FeeCollector mockSendingOracle = new FeeCollector();
            mockSendingOracle.updateNativeTokenFee(true, 0);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "addresses/",
                vm.envString("ENVIRONMENT"),
                "/",
                chainName,
                "/sending_oracle.txt"
            );

            string memory mockSendingOracleAddress = vm.toString(address(mockSendingOracle));
            vm.writeFile(storagePath, mockSendingOracleAddress);
            console.log("MockSendingOracle deployed on %s", chainName);
        } else {
            console.log("MockSendingOracle already deployed on %s", chainName);
        }
    }
}
