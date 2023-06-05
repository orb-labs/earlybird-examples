// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../../src/ThunderbirdVersion/MockRecsContract.sol";

contract MockThunderbirdRecsContractDeployment is Script {
    function run() external {
        string memory mnemonics = vm.envString("MNEMONICS");
        uint256 keyIndex = vm.envUint("KEY_INDEX");

        string memory chainName = vm.envString("CHAIN_NAME");
        string memory addressFolder = vm.envString("ADDRESS_FOLDER");
        address thunderbirdOutRelayer = vm.envAddress("EXPECTED_MOCK_THUNDERBIRD_RELAYER_ADDRESS");
        address expectedMockThunderbirdRecsContract = vm.envAddress("EXPECTED_MOCK_THUNDERBIRD_RECS_CONTRACT_ADDRESS");

        uint256 deployerPrivateKey = vm.deriveKey(mnemonics, uint32(keyIndex));
        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMockThunderbirdRecsContract)
        }

        if (size == 0) {
            vm.startBroadcast(deployerPrivateKey);
            MockRecsContract mockThunderbirdRecsContract = new MockRecsContract(thunderbirdOutRelayer);
            vm.stopBroadcast();

            string memory storagePath = string.concat(
                "script/deploymentScripts/mockThunderbirdRecsContract/addresses/",
                addressFolder,
                "/",
                chainName,
                ".txt"
            );

            string memory mockThunderbirdRecsContractAddress = vm.toString(address(mockThunderbirdRecsContract));
            vm.writeFile(storagePath, mockThunderbirdRecsContractAddress);
            console.log("MockThunderbirdRecsContract deployed on %s", chainName);
        } else {
            console.log("MockThunderbirdRecsContract already deployed on %s", chainName);
        }
    }
}
