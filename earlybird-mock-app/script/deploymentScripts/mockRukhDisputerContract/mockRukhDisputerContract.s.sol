// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/MockDisputerContract.sol";

contract MockRukhDisputerContractDeployment is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");

        string memory chainName = vm.envString("CHAIN_NAME");
        string memory addressFolder = vm.envString("ADDRESS_FOLDER");
        address expectedMockRukhDisputerContract = vm.envAddress("EXPECTED_MOCK_RUKH_DISPUTER_CONTRACT_ADDRESS");

        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockRukhDisputerContract)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockDisputerContract mockRukhDisputerContract = new MockDisputerContract();
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "script/deploymentScripts/mockRukhDisputerContract/addresses/",
                addressFolder,
                "/",
                chainName,
                ".txt"
            );

            string memory mockRukhDisputerContractAddress = vm.toString(address(mockRukhDisputerContract));
            vm.writeFile(storagePath, mockRukhDisputerContractAddress);
            console.log("MockRukhDisputerContract deployed on %s", chainName);
        } else {
            console.log("MockRukhDisputerContract already deployed on %s", chainName);
        }
    }
}
