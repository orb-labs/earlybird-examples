const { ethers } = require("ethers");
const fs = require("node:fs");

// Fetching environment variables
const MNEMONICS = process.env.MNEMONICS;
const RPC_URL = process.env.RPC_URL;
const SOURCE_CHAIN = process.env.SOURCE_CHAIN;
const DESTINATION_CHAIN = process.env.DESTINATION_CHAIN;
const NUMBER_OF_FTS = process.env.NUMBER_OF_FTS;
const NUMBER_OF_NFTS = process.env.NUMBER_OF_NFTS;
const NUMBER_OF_SFTS = process.env.NUMBER_OF_SFTS;
const SOURCE_CHAIN_FILE_PATH = process.env.SOURCE_CHAIN_FILE_PATH;
const DESTINATION_CHAIN_FILE_PATH = process.env.DESTINATION_CHAIN_FILE_PATH;
const MESSAGE_STRING = process.env.MESSAGE_STRING;

// Instantiating providers and walelts
const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = ethers.Wallet.fromPhrase(MNEMONICS, provider);

// Fetching abis
const magiclaneSpokeEndpointFactoryData = require("../out/IMagiclaneSpokeEndpointSendingFunctions.sol/IMagiclaneSpokeEndpointSendingFunctions.json");
const testFungibleTokenFactoryData = require("../out/TestFT.sol/TestFT.json");
const testNonFungibleTokenFactoryData = require("../out/TestNFT.sol/TestNFT.json");
const testSemiFungibleTokenFactoryData = require("../out/TestSFT.sol/TestSFT.json");

// Function for sending tokens on magiclane mock app
const magiclaneMockAppSendTokens = async () => {
  try {
    // Print statement to indicate beginning of script
    console.log("\n=== Sending Message from %s to %s ===\n", SOURCE_CHAIN, DESTINATION_CHAIN);

    // the deployment addresses
    const sourceProtocolData = readData(SOURCE_CHAIN_FILE_PATH, false);
    const sourceMagiclaneSpokeDeploymentData = readDeploymentAddressesForProtocol(
      sourceProtocolData,
      "magiclaneSpokeDeploymentData",
      ""
    );
    const sourceMagiclaneMockAppDeploymentData = readDeploymentAddressesForProtocol(
      sourceProtocolData,
      "magiclaneMockAppDeploymentData",
      ""
    );

    const spokeEndpoint = sourceMagiclaneSpokeDeploymentData.magiclaneSpokeEndpoint;

    const dstProtocolData = readData(DESTINATION_CHAIN_FILE_PATH, false);
    const dstMagiclaneSpokeDeploymentData = readDeploymentAddressesForProtocol(
      dstProtocolData,
      "magiclaneSpokeDeploymentData",
      ""
    );
    const dstMagiclaneMockAppDeploymentData = readDeploymentAddressesForProtocol(
      dstProtocolData,
      "magiclaneMockAppDeploymentData",
      ""
    );

    // iterate on the number of tokens that are being sent and approve the tokens
    // TODO(felix): run this in parallel
    const fungibleTokens = [{ tokenAddress: ethers.ZeroAddress, unwrap: true, amount: 10000, maxFees: 10000 }];
    for (let i = 0; i < NUMBER_OF_FTS; i++) {
      const ftName = "testFT_".concat(i);
      const tokenAddress = sourceMagiclaneMockAppDeploymentData[ftName];
      const amount = 10000 * (i + 1);
      const ftObject = { tokenAddress: tokenAddress, unwrap: true, amount, maxFees: amount };
      fungibleTokens.push(ftObject);
      const token = new ethers.Contract(tokenAddress, testFungibleTokenFactoryData.abi, wallet);
      const approveTx = await token.approve(spokeEndpoint, amount);
      await approveTx.wait();
    }

    // approve the non fungible tokens
    // TODO(felix): run this in parallel
    const nonFungibleTokens = [];
    for (let i = 0; i < NUMBER_OF_NFTS; i++) {
      const nftName = "testNFT_".concat(i);
      const tokenAddress = sourceMagiclaneMockAppDeploymentData[nftName];
      const nftObject = { tokenAddress: tokenAddress, unwrap: true, copyURI: false, id: i };
      nonFungibleTokens.push(nftObject);
      const token = new ethers.Contract(tokenAddress, testNonFungibleTokenFactoryData.abi, wallet);
      const approveTx = await token.approve(spokeEndpoint, nonFungibleTokens[i].id);
      await approveTx.wait();
    }

    // approve the semi fungible tokens
    // TODO(felix): run this in parallel
    const semiFungibleTokens = [];
    for (let i = 0; i < NUMBER_OF_SFTS; i++) {
      const sftName = "testSFT_".concat(i);
      const tokenAddress = sourceMagiclaneMockAppDeploymentData[sftName];
      const sftObject = { tokenAddress: tokenAddress, unwrap: true, copyURI: false, id: i, amount: 10_000 * i };
      semiFungibleTokens.push(sftObject);
      const token = new ethers.Contract(tokenAddress, testSemiFungibleTokenFactoryData.abi, wallet);
      const approveTx = await token.setApprovalForAll(spokeEndpoint, true);
      await approveTx.wait();
    }

    const payoutAddress = ethers.AbiCoder.defaultAbiCoder().encode(
      ["address"],
      [dstMagiclaneMockAppDeploymentData.magiclaneMockApp]
    );

    const refundAddress = ethers.AbiCoder.defaultAbiCoder().encode(["address"], [wallet.address]);
    const info = { instanceId: dstMagiclaneSpokeDeploymentData.magiclaneSpokeId, payoutAddress, refundAddress };
    const payload = ethers.AbiCoder.defaultAbiCoder().encode(
      ["bytes", "address"],
      [ethers.toUtf8Bytes(MESSAGE_STRING), wallet.address]
    );
    const gasOnHub = { gasAmount: 3_000_000, feeFungibleTokenIndex: 0, feeFungibleTokenAmount: 4_000 };
    const gasOnDest = { gasAmount: 3_000_000, feeFungibleTokenIndex: 0, feeFungibleTokenAmount: 4_000 };
    const sendTokensRequest = {
      collectTokensThroughHook: false, // bool collectTokensThroughHook
      tokenSource: wallet.address, // address tokenSource
      fungibleTokens: fungibleTokens, // FTObjectForSendFunctions[] fungibleTokens
      nonFungibleTokens: nonFungibleTokens, // NFTObjectForSendFunctions[] nonFungibleTokens
      semiFungibleTokens: semiFungibleTokens, // SFTObjectForSendFunctions[] semiFungibleTokens
      message: payload, // bytes message
      info: info, // PayoutAndRefund.Info info
      gasOnHub: gasOnHub, // Gas.Data gasOnHub
      gasOnDest: gasOnDest, // Gas.Data gasOnDest
    };
    const appContract = new ethers.Contract(spokeEndpoint, magiclaneSpokeEndpointFactoryData.abi, wallet);

    // TODO(felix): do the proper fee estimation at the destination
    const feeEstimateForSendTokensRequest = await appContract.getFeeEstimateForSendTokensRequest(sendTokensRequest);
    const amount = BigInt(10) * BigInt(feeEstimateForSendTokensRequest[1]);
    sendTokensRequest.fungibleTokens[0].maxFees = amount;
    sendTokensRequest.fungibleTokens[0].amount = amount;
    sendTokensRequest.gasOnHub.feeFungibleTokenAmount = feeEstimateForSendTokensRequest[1];
    sendTokensRequest.gasOnDest.feeFungibleTokenAmount = BigInt(9) * BigInt(feeEstimateForSendTokensRequest[1]);

    const submitTx = await appContract.sendTokens(sendTokensRequest, { value: amount });
    await submitTx.wait();

    // Print statement to indicate the end of script
    console.log("\x1b[32m%s\x1b[0m", "Script ran successfully\n");
  } catch (error) {
    console.log({ error });
  }
};

/**
 * Function for reading deployment addresses
 * @param {string} file_path - string representing the path for the file holding the deployment addresses
 * @param {bool} throw_err_if_empty - boolean indicating whether the function should throw error if empty
 * @returns {Map<String, String>} - map containing all the deployment addresses
 */
function readData(file_path, throw_err_if_empty) {
  try {
    data = fs.readFileSync(file_path);
    return JSON.parse(data);
  } catch (err) {
    if (throw_err_if_empty == true) {
      throw err;
    } else {
      return {};
    }
  }
}

/**
 * Function for reading deployment addresses for protocol from a file.
 * @param {Map<String, String>} deployment_addresses - map containing all the deployment addresses
 * @param {string} protocol - string indicating the protocol for which we are fetching deployed data
 * @param {Map<String, String>} defaultData - map containing default data that is returned if the
 *                                            deployed contract data is not found in the deployment addresses map
 * @returns {Map<String, String>} - map containing all the deployed contract data
 */
function readDeploymentAddressesForProtocol(deployment_addresses, protocol, defaultData) {
  let protocolData = deployment_addresses[protocol];
  if (protocolData === undefined) {
    if (defaultData == "") {
      throw "protocol not found";
    } else {
      return defaultData;
    }
  } else {
    return protocolData;
  }
}

magiclaneMockAppSendTokens();
