const { ethers } = require("ethers");
const fs = require("node:fs");

// Fetching environment variables
const CHAIN_NAME = process.env.CHAIN_NAME;
const RPC_URL = process.env.RPC_URL;
const MNEMONICS = process.env.MNEMONICS;
const EARLYBIRD_DATA_FILE_PATH = process.env.EARLYBIRD_DATA_FILE_PATH;
const EARLYBIRD_PERIPHERY_CONTRACTS_DATA_FILE_PATH = process.env.EARLYBIRD_PERIPHERY_CONTRACTS_DATA_FILE_PATH;
const EARLYBIRD_PING_PONG_APP_DATA_FILE_PATH = process.env.EARLYBIRD_PING_PONG_APP_DATA_FILE_PATH;

// Instantiating providers and walelts
const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = ethers.Wallet.fromPhrase(MNEMONICS, provider);

// Fetching abis
const thunderbirdPingPongAppData = require("../out/ThunderbirdVersion/PingPong.sol/PingPong.json");
const rukhDisputersContractData = require("../out/DisputerContract.sol/DisputerContract.json");
const rukhPingPongAppData = require("../out/RukhVersion/PingPong.sol/PingPong.json");

// Function for deploying earlybird ping pong app
const deployEarlybirdPingPongApp = async () => {
  try {
    // Print statement to indicate beginning of script
    console.log("\n=== Earlybird Ping Pong App EVM Deployments on %s ===\n", CHAIN_NAME);

    // Read earlybird data
    let earlybirdData = await readData(EARLYBIRD_DATA_FILE_PATH);

    // Read earlybird periphery contracts data
    let earlybirdPeripheryContractsData = await readData(EARLYBIRD_PERIPHERY_CONTRACTS_DATA_FILE_PATH);

    // Read expected earlybird ping pong app data
    let expectedEarlybirdPingPongAppData = await readExpectedEarlybirdPingPongAppData(
      EARLYBIRD_PING_PONG_APP_DATA_FILE_PATH
    );

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

    // Get or deploy rukh disputer contract
    let rukhDisputerContract = await useOrDeployRukhDisputerContract(
      expectedEarlybirdPingPongAppData.rukhDisputerContract,
      earlybirdData.rukhV1ReceiveModule
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
      rukhDisputerContract,
      earlybirdPeripheryContractsData.disputeResolver
    );

    // Update the rukh disputer contract app address to the rukh ping pong app
    await updateAppAddressOnRukhDisputerContract(rukhDisputerContract, rukhPingPongApp);

    // Create magiclane mock app data map
    let earlybirdPingPongAppData = {
      thunderbirdPingPongApp: thunderbirdPingPongApp,
      rukhPingPongApp: rukhPingPongApp,
      rukhDisputerContract: rukhDisputerContract,
    };

    // Save earlybird ping pong app data
    fs.writeFileSync(EARLYBIRD_PING_PONG_APP_DATA_FILE_PATH, JSON.stringify(earlybirdPingPongAppData, null, "\t"));

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
 * Function for fetching already deployed rukh disputer contract or deploying it if it does not exist
 * @param {string} expectedRukhDisputerContract - 20 byte string representing the expected rukh disputer contract
 * @param {string} rukhLibraryReceiveModule - 20 byte string representing the rukh library receive module
 * @returns {string} rukhDisputerContractAddress - 20 byte string representing the deployed rukh disputer contract address
 */
async function useOrDeployRukhDisputerContract(expectedRukhDisputerContract, rukhLibraryReceiveModule) {
  let rukhDisputerContractAddress;

  // Check if the expected magiclane mock app exists
  let expectedRukhDisputerContractCode = await provider.getCode(expectedRukhDisputerContract);

  // If not, deploy magiclane mock app
  if (expectedRukhDisputerContractCode == "0x") {
    const rukhDisputerContractFactory = new ethers.ContractFactory(
      rukhDisputersContractData.abi,
      rukhDisputersContractData.bytecode,
      wallet
    );
    const rukhDisputerContract = await rukhDisputerContractFactory.deploy(rukhLibraryReceiveModule);
    await rukhDisputerContract.waitForDeployment();

    rukhDisputerContractAddress = await rukhDisputerContract.getAddress();
    console.log("Rukh Disputers Contract deployed on %s at %s", CHAIN_NAME, rukhDisputerContractAddress);
  } else {
    rukhDisputerContractAddress = expectedRukhDisputerContract;
    console.log("Rukh Disputers Contract already deployed on %s at %s", CHAIN_NAME, rukhDisputerContractAddress);
  }

  // return
  return rukhDisputerContractAddress;
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
 * Function for fetching already deployed rukh disputer contract or deploying it if it does not exist
 * @param {string} rukhDisputerContractAddress - 20 byte string representing the rukh disputer contract address
 * @param {string} expectedAppAddress - 20 byte string representing the expected app address
 */
async function updateAppAddressOnRukhDisputerContract(rukhDisputerContractAddress, expectedAppAddress) {
  // Check if the rukh disputer contract exists
  let rukhDisputerContractCode = await provider.getCode(rukhDisputerContractAddress);

  // If it does get the current app address
  if (rukhDisputerContractCode != "0x") {
    let rukhDisputerContract = new ethers.Contract(
      rukhDisputerContractAddress,
      rukhDisputersContractData.abi,
      provider
    );
    let currentAppAddress = await rukhDisputerContract.app();
    

    // Check if the current app address matches what is expected, if not update
    if (currentAppAddress != expectedAppAddress) {
      rukhDisputerContract = new ethers.Contract(rukhDisputerContractAddress, rukhDisputersContractData.abi, wallet);
      let updateTx = await rukhDisputerContract.updateApp(expectedAppAddress);
      await updateTx.wait();
      console.log("Rukh Disputers Contract app address updated to %s on %s", expectedAppAddress, CHAIN_NAME);
    } else {
      console.log("Rukh Disputers Contract app address already updated to %s on %s", expectedAppAddress, CHAIN_NAME);
    }
  } else {
    console.log("Rukh Disputers Contract not found on %s", CHAIN_NAME);
  }
}

/**
 * Function for reading data from a file.
 * @param {string} file_path - string representing the path for the file being read
 * @returns {Map<String, String>} - map containing the data that was read
 */
async function readData(file_path) {
  try {
    data = fs.readFileSync(file_path);
    return JSON.parse(data);
  } catch (err) {
    throw err;
  }
}

/**
 * Function for reading expected earlybird ping pong app data from a file.
 * @param {string} file_path - string representing the path for the file holding the expected earlybird ping pong app data
 * @returns {Map<String, String>} - map containing all the expected earlybird ping pong app data
 */
async function readExpectedEarlybirdPingPongAppData(file_path) {
  try {
    data = fs.readFileSync(file_path);
    return JSON.parse(data);
  } catch (err) {
    return {
      thunderbirdPingPongApp: ethers.ZeroAddress,
      rukhPingPongApp: ethers.ZeroAddress,
      rukhDisputerContract: ethers.ZeroAddress,
    };
  }
}

deployEarlybirdPingPongApp();
