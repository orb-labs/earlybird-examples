const { ethers } = require("ethers");
const fs = require("node:fs");

// Fetching environment variables
const RPC_URL = process.env.RPC_URL;
const CHAIN_FILE_PATH = process.env.CHAIN_FILE_PATH;
const CHAIN_NAME = process.env.CHAIN_NAME;

// Instantiating providers and wallets
const provider = new ethers.JsonRpcProvider(RPC_URL);

// Fetching abis
const magiclaneMockAppFactoryData = require("../out/MagiclaneMockApp.sol/MagiclaneMockApp.json");

// Function for reading messages on mock app
const getAllMessagesOnMockApp = async () => {
  try {
    // Print statement to indicate beginning of script
    console.log("\n=== Reading Message to and from %s Mock App ===\n");

    // Read the source information
    const protocolData = readData(CHAIN_FILE_PATH, false);
    const mockData = readDeploymentAddressesForProtocol(protocolData, "magiclaneMockAppDeploymentData", "");

    // Read the chain data
    const appContract = new ethers.Contract(mockData.magiclaneMockApp, magiclaneMockAppFactoryData.abi, provider);
    const receivedMessages = await appContract.getAllReceivedMessages();
    const sentMessages = await appContract.getAllSentMessages();

    console.log(CHAIN_NAME, "\n");
    console.log("Sent Messages:");
    sentMessages.map((message, index) => {
      console.log(index, ":", message);
    });

    console.log("\n");
    console.log("Received Messages");
    receivedMessages.map((message, index) => {
      console.log(index, ":", message);
    });

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

getAllMessagesOnMockApp();
