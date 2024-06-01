const { ethers } = require("ethers");
const fs = require("node:fs");

// Fetching environment variables
const MNEMONICS = process.env.MNEMONICS;
const RPC_URL = process.env.RPC_URL;
const SOURCE_CHAIN = process.env.SOURCE_CHAIN;
const DESTINATION_CHAIN = process.env.DESTINATION_CHAIN;
const MESSAGE_STRING = process.env.MESSAGE_STRING;
const LIBRARY = process.env.LIBRARY;

const SOURCE_CHAIN_FILE_PATH = process.env.SOURCE_CHAIN_FILE_PATH;
const DESTINATION_CHAIN_FILE_PATH = process.env.DESTINATION_CHAIN_FILE_PATH;

// Instantiating providers and wallets
const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = ethers.Wallet.fromPhrase(MNEMONICS, provider);

console.log(SOURCE_CHAIN, "RPC_URL", RPC_URL);

// Fetching abis
const mockThunderbirdAppFactoryData = require("../out/ThunderbirdVersion/MockApp.sol/MockApp.json");
const mockRukhAppFactoryData = require("../out/RukhVersion/MockApp.sol/MockApp.json");

// Function for deploying earlybird mock app
const sendMessageOnMockApp = async () => {
  try {
    // Print statement to indicate beginning of script
    console.log("\n=== Sending Message from %s to %s ===\n", SOURCE_CHAIN, DESTINATION_CHAIN);

    // Read the source information
    const sourceProtocolData = readData(SOURCE_CHAIN_FILE_PATH, false);
    const sourceMockData = readDeploymentAddressesForProtocol(sourceProtocolData, "earlybirdMockAppDeploymentData", "");

    // Read the destination information
    const dstProtocolData = readData(DESTINATION_CHAIN_FILE_PATH, false);
    const dstEarlybirdData = readDeploymentAddressesForProtocol(dstProtocolData, "earlybirdDeploymentData", "");
    const dstMockData = readDeploymentAddressesForProtocol(dstProtocolData, "earlybirdMockAppDeploymentData", "");

    // Encode the additional parameters and receiver
    const additionalParams = ethers.AbiCoder.defaultAbiCoder().encode(
      ["tuple(address feeToken, bool isOrderedMsg, uint256 destinationGas, address expectedRelayerFeeCollector)"],
      [
        {
          feeToken: ethers.ZeroAddress,
          isOrderedMsg: true,
          destinationGas: 450_000,
          expectedRelayerFeeCollector: ethers.ZeroAddress,
        },
      ]
    );

    // Send message on the mock app
    let appContract, receiver;
    if (LIBRARY == "Thunderbird") {
      receiver = ethers.AbiCoder.defaultAbiCoder().encode(["address"], [dstMockData.mockThunderbirdApp]);
      appContract = new ethers.Contract(sourceMockData.mockThunderbirdApp, mockThunderbirdAppFactoryData.abi, wallet);
    } else {
      receiver = ethers.AbiCoder.defaultAbiCoder().encode(["address"], [dstMockData.mockRukhApp]);
      appContract = new ethers.Contract(sourceMockData.mockRukhApp, mockRukhAppFactoryData.abi, wallet);
    }

    const submitTx = await appContract.sendMessage(
      dstEarlybirdData.earlybirdEndpointInstanceId, //  _receiverInstanceId,
      receiver, // _receiver,
      MESSAGE_STRING, // _message,
      additionalParams // _additionalParams
    );

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

sendMessageOnMockApp();
