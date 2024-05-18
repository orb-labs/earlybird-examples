const { ethers } = require("ethers");
const fs = require("node:fs");

// Fetching environment variables
const MNEMONICS = process.env.MNEMONICS;
const CHAIN_NAME = process.env.CHAIN_NAME;
const RPC_URL = process.env.RPC_URL;
const DEPLOYMENT_ADDRESSES_FILE_PATH = process.env.DEPLOYMENT_ADDRESSES_FILE_PATH;

// Instantiating providers and walelts
const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = ethers.Wallet.fromPhrase(MNEMONICS, provider);

// Fetching abis
const thunderbirdPingPongAppData = require("../out/ThunderbirdVersion/PingPong.sol/PingPong.json");
const rukhPingPongAppData = require("../out/RukhVersion/PingPong.sol/PingPong.json");

// Function for deploying earlybird ping pong app
const deployEarlybirdPingPongApp = async () => {
  try {
    // Print statement to indicate beginning of script
    console.log("\n=== Earlybird Ping Pong App EVM Deployments on %s ===\n", CHAIN_NAME);

    // Read deployment addresses
    let deploymentAddresses = await readData(DEPLOYMENT_ADDRESSES_FILE_PATH, false);

    // Read earlybird data on spoke chain
    let earlybirdData = await readDeploymentAddressesForProtocol(deploymentAddresses, "earlybirdDeploymentData", "");

    // Read earlybird periphery contracts data on spoke chain
    let earlybirdPeripheryContractsData = await readDeploymentAddressesForProtocol(deploymentAddresses, "earlybirdPeripheryContractsDeploymentData", "");

    // Read expected earlybird ping pong app data
    let expectedEarlybirdPingPongAppData = await readDeploymentAddressesForProtocol(deploymentAddresses, "earlybirdPingPongAppDeploymentData", emptyEarlybirdPingPongAppDeploymentData());

    // Get or deploy thunderbird ping pong app
    let thunderbirdPingPongApp = await useOrDeployThunderbirdPingPongApp(
      expectedEarlybirdPingPongAppData.thunderbirdPingPongApp,
      earlybirdData.earlybirdEndpoint,
      earlybirdPeripheryContractsData.oracle,
      earlybirdPeripheryContractsData.relayer,
      earlybirdPeripheryContractsData.oracle,
      earlybirdPeripheryContractsData.relayer,
      earlybirdPeripheryContractsData.relayer
    );

    // Get or deploy rukh ping pong app
    let rukhPingPongApp = await useOrDeployRukhPingPongApp(
      expectedEarlybirdPingPongAppData.rukhPingPongApp,
      earlybirdData.earlybirdEndpoint,
      earlybirdPeripheryContractsData.oracle,
      earlybirdPeripheryContractsData.relayer,
      earlybirdPeripheryContractsData.oracle,
      earlybirdPeripheryContractsData.relayer,
      earlybirdPeripheryContractsData.relayer,
      earlybirdPeripheryContractsData.disputerContract,
      earlybirdPeripheryContractsData.disputeResolver
    );

    // Create earlybird ping pong app data map
    deploymentAddresses.earlybirdPingPongAppDeploymentData = {
      thunderbirdPingPongApp: thunderbirdPingPongApp,
      rukhPingPongApp: rukhPingPongApp,
    };

    // Save earlybird ping pong app data
    fs.writeFileSync(DEPLOYMENT_ADDRESSES_FILE_PATH, JSON.stringify(deploymentAddresses, null, "\t"));

    // Print statement to indicate the end of script
    console.log("\x1b[32m%s\x1b[0m", "Script ran successfully\n");
  } catch (error) {
    console.log({ error });
  }
};

/**
 * Function for fetching already deployed thunderbird ping pong app or deploying it if it does not exist
 * @param {string} expectedThunderbirdPingPongApp - 20 byte string representing the expected thunderbird ping pong app
 * @param {string} earlybirdEndpointAddress - 20 byte string representing the earlybird endpoint address
 * @param {string} oracleFeeCollector - 20 byte string representing the oracle fee collector
 * @param {string} relayerFeeCollector - 20 byte string representing the relayer fee collector
 * @param {string} oracle - 20 byte string representing the oracle
 * @param {string} relayer - 20 byte string representing the relayer
 * @param {string} altRelayer - 20 byte string representing the alternative relayer
 * @returns {string} thunderbirdPingPongApp - 20 byte string representing the deployed thunderbird ping pong app
 */
async function useOrDeployThunderbirdPingPongApp(
  expectedThunderbirdPingPongApp,
  earlybirdEndpointAddress,
  oracleFeeCollector,
  relayerFeeCollector,
  oracle,
  relayer,
  altRelayer
) {
  let thunderbirdPingPongApp;

  // Check if the expected magiclane mock app exists
  let expectedThunderbirdPingPongAppCode = await provider.getCode(expectedThunderbirdPingPongApp);

  // Check if the earlybird endpoint exists
  let earlybirdEndpointCode = await provider.getCode(earlybirdEndpointAddress);

  // If not, deploy magiclane mock app
  if (expectedThunderbirdPingPongAppCode == "0x" && earlybirdEndpointCode != "0x") {
    const thunderbirdPingPongAppFactory = new ethers.ContractFactory(
      thunderbirdPingPongAppData.abi,
      thunderbirdPingPongAppData.bytecode,
      wallet
    );
    const thunderbirdPingPongAppContract = await thunderbirdPingPongAppFactory.deploy(
      earlybirdEndpointAddress,
      oracleFeeCollector,
      relayerFeeCollector,
      oracle,
      relayer,
      altRelayer
    );

    await thunderbirdPingPongAppContract.waitForDeployment();
    thunderbirdPingPongApp = await thunderbirdPingPongAppContract.getAddress();
    console.log("Thunderbird Version PingPong App deployed on %s at %s", CHAIN_NAME, thunderbirdPingPongApp);
  } else {
    thunderbirdPingPongApp = expectedThunderbirdPingPongApp;
    console.log("Thunderbird Version PingPong App already deployed on %s at %s", CHAIN_NAME, thunderbirdPingPongApp);
  }

  // return
  return thunderbirdPingPongApp;
}

/**
 * Function for fetching already deployed rukh ping pong app or deploying it if it does not exist
 * @param {string} expectedRukhPingPongApp - 20 byte string representing the expected rukh ping pong app
 * @param {string} earlybirdEndpointAddress - 20 byte string representing the earlybird endpoint address
 * @param {string} oracleFeeCollector - 20 byte string representing the oracle fee collector
 * @param {string} relayerFeeCollector - 20 byte string representing the relayer fee collector
 * @param {string} oracle - 20 byte string representing the oracle
 * @param {string} relayer - 20 byte string representing the relayer
 * @param {string} altRelayer - 20 byte string representing the alternative relayer
 * @param {string} disputersContract - 20 byte string representing the disputer contract
 * @param {string} disputeResolver - 20 byte string representing the dispute resolver
 * @returns {string} rukhPingPongApp - 20 byte string representing the deployed rukh ping pong app
 */
async function useOrDeployRukhPingPongApp(
  expectedRukhPingPongApp,
  earlybirdEndpointAddress,
  oracleFeeCollector,
  relayerFeeCollector,
  oracle,
  relayer,
  altRelayer,
  disputersContract,
  disputeResolver
) {
  let rukhPingPongApp;

  // Check if the expected magiclane mock app exists
  let expectedRukhPingPongAppCode = await provider.getCode(expectedRukhPingPongApp);

  // Check if the earlybird endpoint exists
  let earlybirdEndpointCode = await provider.getCode(earlybirdEndpointAddress);

  // If not, deploy magiclane mock app
  if (expectedRukhPingPongAppCode == "0x" && earlybirdEndpointCode != "0x") {
    const rukhPingPongAppFactory = new ethers.ContractFactory(
      rukhPingPongAppData.abi,
      rukhPingPongAppData.bytecode,
      wallet
    );
    const rukhPingPongAppContract = await rukhPingPongAppFactory.deploy(
      earlybirdEndpointAddress,
      oracleFeeCollector,
      relayerFeeCollector,
      oracle,
      relayer,
      altRelayer,
      disputersContract,
      disputeResolver
    );

    await rukhPingPongAppContract.waitForDeployment();
    rukhPingPongApp = await rukhPingPongAppContract.getAddress();
    console.log("Rukh Version PingPong App deployed on %s at %s", CHAIN_NAME, rukhPingPongApp);
  } else {
    rukhPingPongApp = expectedRukhPingPongApp;
    console.log("Rukh Version PingPong App already deployed on %s at %s", CHAIN_NAME, rukhPingPongApp);
  }

  // return
  return rukhPingPongApp;
}

/**
 * Function for reading deployment addresses
 * @param {string} file_path - string representing the path for the file holding the deployment addresses
 * @param {bool} throw_err_if_empty - boolean indicating whether the function should throw error if empty
 * @returns {Map<String, String>} - map containing all the deployment addresses
 */
async function readData(file_path, throw_err_if_empty) {
  try {
      data = fs.readFileSync(file_path);
      return JSON.parse(data);
    } catch (err) {
      if (throw_err_if_empty == true) {
        throw(err)
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
async function readDeploymentAddressesForProtocol(deployment_addresses, protocol, defaultData) {
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

/**
* Function that returns an empty earlybird ping pong app deployment data map
*/
function emptyEarlybirdPingPongAppDeploymentData() {
  return {
    thunderbirdPingPongApp: ethers.ZeroAddress,
    rukhPingPongApp: ethers.ZeroAddress,
  };
}

deployEarlybirdPingPongApp();
