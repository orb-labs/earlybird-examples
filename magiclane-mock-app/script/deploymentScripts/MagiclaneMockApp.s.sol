// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../../src/MagiclaneMockApp.sol";
import "magiclane/src/magiclaneSpoke/IMagiclaneSpokeEndpoint/IMagiclaneSpokeEndpointSendingFunctions.sol";
import "magiclane/src/magiclaneSharedLibrary.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC1155/IERC1155.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract MagiclaneMockAppDeployment is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONICS"), uint32(vm.envUint("KEY_INDEX")));
        string memory chainName = vm.envString("CHAIN_NAME");
        address expectedMagiclaneMockAppAddress = vm.envAddress("EXPECTED_MAGICLANE_MOCK_APP_ADDRESS");

        uint256 size = 0;
        assembly {
            size := extcodesize(expectedMagiclaneMockAppAddress)
        }

        if (size == 0) {
            address magiclaneEndpoint = vm.envAddress("MAGICLANE_SPOKE_ENDPOINT_ADDRESS");
            vm.startBroadcast(deployerPrivateKey);
            MagiclaneMockApp magiclaneMockApp = new MagiclaneMockApp(magiclaneEndpoint);
            vm.stopBroadcast();

            string memory storagePath =
                string.concat("addresses/", vm.envString("ENVIRONMENT"), "/", chainName, "/", "MagiclaneMockApp.txt");

            string memory magiclaneMockAppAddress = vm.toString(address(magiclaneMockApp));
            vm.writeFile(storagePath, magiclaneMockAppAddress);
            console.log("MagiclaneMockApp deployed on %s at %s", chainName, magiclaneMockAppAddress);
        } else {
            console.log("MagiclaneMockApp already found on %s at %s", chainName, expectedMagiclaneMockAppAddress);
        }
    }
}

contract MagiclaneMockAppSendMessage is Script {
    // to facilitate safe transfers of ERC20s
    using SafeERC20 for IERC20;

    function run() external {
        uint256 sendingPrivateKey =
            vm.deriveKey(vm.envString("SENDING_MNEMONICS"), uint32(vm.envUint("SENDING_KEY_INDEX")));
        address senderAddress = vm.addr(sendingPrivateKey);
        address magiclaneEndpoint = vm.envAddress("MAGICLANE_SPOKE_ENDPOINT_ADDRESS");
        address receiverMagiclaneMockAppAdddress = vm.envAddress("RECEIVER_MOCK_MAGICLANE_APP_ADDRESS");
        uint256 numberOfFTs = vm.envUint("NUMBER_OF_FTS");
        uint256 numberOfNFTs = vm.envUint("NUMBER_OF_NFTS");
        uint256 numberOfSFTs = vm.envUint("NUMBER_OF_SFTS");

        IMagiclaneSpokeEndpointSendingFunctions.FTObjectForSendFunctions[] memory fungibleTokens =
            new IMagiclaneSpokeEndpointSendingFunctions.FTObjectForSendFunctions[](numberOfFTs);
        for (uint256 i = 0; i < numberOfFTs; i++) {
            address tokenAddress = vm.envAddress(string.concat("TEST_FT_ADDRESSES_", Strings.toString(i)));
            IMagiclaneSpokeEndpointSendingFunctions.FTObjectForSendFunctions memory ftObject =
            IMagiclaneSpokeEndpointSendingFunctions.FTObjectForSendFunctions(tokenAddress, true, 10_000 * i, 10_000 * i);

            fungibleTokens[i] = ftObject;
            IERC20(fungibleTokens[i].tokenAddress).approve(magiclaneEndpoint, fungibleTokens[i].amount);
        }

        IMagiclaneSpokeEndpointSendingFunctions.NFTObjectForSendFunctions[] memory nonFungibleTokens =
            new IMagiclaneSpokeEndpointSendingFunctions.NFTObjectForSendFunctions[](numberOfNFTs);
        for (uint256 i = 0; i < numberOfNFTs; i++) {
            address tokenAddress = vm.envAddress(string.concat("TEST_NFT_ADDRESSES_", Strings.toString(i)));
            IMagiclaneSpokeEndpointSendingFunctions.NFTObjectForSendFunctions memory nftObject =
                IMagiclaneSpokeEndpointSendingFunctions.NFTObjectForSendFunctions(tokenAddress, true, false, i);

            nonFungibleTokens[i] = nftObject;
            IERC721((nonFungibleTokens[i].tokenAddress)).approve(magiclaneEndpoint, nonFungibleTokens[i].id);
        }

        IMagiclaneSpokeEndpointSendingFunctions.SFTObjectForSendFunctions[] memory semiFungibleTokens =
            new IMagiclaneSpokeEndpointSendingFunctions.SFTObjectForSendFunctions[](numberOfSFTs);
        for (uint256 i = 0; i < numberOfSFTs; i++) {
            address tokenAddress = vm.envAddress(string.concat("TEST_SFT_ADDRESSES_", Strings.toString(i)));
            IMagiclaneSpokeEndpointSendingFunctions.SFTObjectForSendFunctions memory sftObject =
            IMagiclaneSpokeEndpointSendingFunctions.SFTObjectForSendFunctions(tokenAddress, true, false, i, 10_000 * i);

            semiFungibleTokens[i] = sftObject;
            IERC1155(semiFungibleTokens[i].tokenAddress).setApprovalForAll(magiclaneEndpoint, true);
        }

        string memory message = vm.envString("MESSAGE_STRING");
        bytes32 receiverSpokeInstanceId = vm.envBytes32("RECEIVER_SPOKE_INSTANCE_ID");
        PayoutAndRefund.Info memory info =
            PayoutAndRefund.Info(receiverSpokeInstanceId, abi.encode(senderAddress), abi.encode(senderAddress));

        bytes memory payload = abi.encode(message, info);
        info.payoutAddress = abi.encode(receiverMagiclaneMockAppAdddress);
        Gas.Data memory gasOnHub = Gas.Data(500_000, 0, 2_000);
        Gas.Data memory gasOnDest = Gas.Data(500_000, 0, 2_000);

        IMagiclaneSpokeEndpointSendingFunctions.SendTokensRequest memory sendTokensRequest =
        IMagiclaneSpokeEndpointSendingFunctions.SendTokensRequest(
            false, // collectTokensThroughHook
            address(this), // placehloder for tokenSource
            fungibleTokens,
            nonFungibleTokens,
            semiFungibleTokens,
            payload,
            info,
            gasOnHub,
            gasOnDest
        );

        vm.startBroadcast(sendingPrivateKey);
        IMagiclaneSpokeEndpointSendingFunctions(magiclaneEndpoint).sendTokens(sendTokensRequest);
        vm.stopBroadcast();
        console.log("sent message on Thunderbird via Thunderbird mock app");
    }
}

contract MagiclaneMockAppGetAllMessages is Script {
    function run() external view {
        address mockAppAddress = vm.envAddress("MOCK_MAGICLANE_APP_ADDRESS");
        string memory chainName = vm.envString("CHAIN_NAME");
        string[] memory receivedMessages = MagiclaneMockApp(mockAppAddress).getAllReceivedMessages();
        string[] memory sentMessages = MagiclaneMockApp(mockAppAddress).getAllSentMessages();

        console.log(chainName, "\n");
        console.log("Sent Messages:");
        for (uint256 i = 0; i < sentMessages.length; i++) {
            console.log(i, ":", sentMessages[i]);
        }

        console.log("\n");
        console.log("Received Messages");
        for (uint256 i = 0; i < receivedMessages.length; i++) {
            console.log(i, ":", receivedMessages[i]);
        }

        console.log("\n");
    }
}
