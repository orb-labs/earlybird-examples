// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/RukhVersion/MockRecsContract.sol";

contract MockRukhRecsContractDeployment is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");

        string memory chainName = vm.envString("CHAIN_NAME");
        string memory addressFolder = vm.envString("ADDRESS_FOLDER");
        address rukhOutRelayer = vm.envAddress("EXPECTED_MOCK_RUKH_RELAYER_ADDRESS");
        address expectedMockRukhRecsContract = vm.envAddress("EXPECTED_MOCK_RUKH_RECS_CONTRACT_ADDRESS");

        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockRukhRecsContract)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockRecsContract mockRukhRecsContract = new MockRecsContract(rukhOutRelayer);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "script/deploymentScripts/mockRukhRecsContract/addresses/",
                addressFolder,
                "/",
                chainName,
                ".txt"
            );

            string memory mockRukhRecsContractAddress = vm.toString(address(mockRukhRecsContract));
            vm.writeFile(storagePath, mockRukhRecsContractAddress);
            console.log("MockRukhRecsContract deployed on %s", chainName);
        } else {
            console.log("MockRukhRecsContract already deployed on %s", chainName);
        }
    }
}
