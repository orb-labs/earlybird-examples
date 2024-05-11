const { ethers } = require("ethers");
const fs = require("node:fs");

// Fetching environment variables
const CHAIN_NAME = process.env.CHAIN_NAME;
const RPC_URL = process.env.RPC_URL;
const MNEMONICS = process.env.MNEMONICS;
const EARLYBIRD_DATA_FILE_PATH = process.env.EARLYBIRD_DATA_FILE_PATH;
const EARLYBIRD_PERIPHERY_CONTRACTS_DATA_FILE_PATH = process.env.EARLYBIRD_PERIPHERY_CONTRACTS_DATA_FILE_PATH;
const EARLYBIRD_MOCK_APP_DATA_FILE_PATH = process.env.EARLYBIRD_MOCK_APP_DATA_FILE_PATH;

// Instantiating providers and walelts
const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = ethers.Wallet.fromPhrase(MNEMONICS, provider);

// Fetching abis
const earlybirdEndpointV1FactoryData = require("../out/IEndpoint.sol/IEndpoint.json");
const mockThunderbirdV1AppFactoryData = require("../out/ThunderbirdVersion/MockApp.sol/MockApp.json");
const mockThunderbirdV1RecsContractFactoryData = require("../out/ThunderbirdVersion/RecsContract.sol/RecsContract.json");
const mockRukhV1AppFactoryData = require("../out/RukhVersion/MockApp.sol/MockApp.json");
const mockRukhV1RecsContractFactoryData = require("../out/RukhVersion/RecsContract.sol/RecsContract.json");

// Function for deploying earlybird mock app
const deployEarlybirdMockApp = async () => {
  try {
    // Print statement to indicate beginning of script
    console.log("\n=== Earlybird Mock App EVM Deployments on %s ===\n", CHAIN_NAME);

    // Read earlybird data on spoke chain
    let earlybirdData = await readData(EARLYBIRD_DATA_FILE_PATH);

    // Read earlybird periphery contracts data on spoke chain
    let earlybirdPeripheryContractsData = await readData(EARLYBIRD_PERIPHERY_CONTRACTS_DATA_FILE_PATH);

    // Read expected earlybird mock app data
    let expectedEarlybirdMockAppData = await readExpectedEarlybirdMockAppData(EARLYBIRD_MOCK_APP_DATA_FILE_PATH);

    // Get or deploy mock thunderbird v1 app
    let mockThunderbirdV1App = await useOrDeployMockThunderbirdV1App(
      expectedEarlybirdMockAppData.mockThunderbirdV1App,
      earlybirdData.earlybirdEndpoint
    );

    // Get or deploy mock thunderbird v1 recs contract
    let mockThunderbirdV1RecsContract = await useOrDeployMockThunderbirdV1RecsContract(
      expectedEarlybirdMockAppData.mockThunderbirdV1RecsContract,
      earlybirdPeripheryContractsData.relayer
    );

    // Get configs for mock thunderbird V1 app
    let configsForMockThunderbirdV1App = await getConfigsForMockThunderbirdV1App(
      mockThunderbirdV1RecsContract, 
      earlybirdPeripheryContractsData
    );

    // Update configs for mock thunderbird v1 app
    await updateConfigsForMockThunderbirdV1App(
      mockThunderbirdV1App,
      earlybirdData.earlybirdEndpoint,
      configsForMockThunderbirdV1App.encodedMockThunderbirdV1AppConfigsForSending,
      configsForMockThunderbirdV1App.encodedMockThunderbirdV1AppConfigsForReceiving
    );

    // Get or deploy mock rukh v1 app
    let mockRukhV1App = await useOrDeployMockRukhV1App(
      expectedEarlybirdMockAppData.mockRukhV1App,
      earlybirdData.earlybirdEndpoint
    );

    // Get or deploy mock rukh v1 recs contract
    let mockRukhV1RecsContract = await useOrDeployMockRukhV1RecsContract(
      expectedEarlybirdMockAppData.mockRukhV1RecsContract,
      earlybirdPeripheryContractsData.relayer
    );

    // Get configs for mock rukh V1 app
    let configsForMockRukhV1App = await getConfigsForMockRukhV1App(
      mockRukhV1RecsContract, 
      earlybirdPeripheryContractsData
    );

    // Update configs for mock rukh v1 app
    await updateConfigsForMockRukhV1App(
      mockRukhV1App,
      earlybirdData.earlybirdEndpoint,
      configsForMockRukhV1App.encodedMockRukhV1AppConfigsForSending,
      configsForMockRukhV1App.encodedMockRukhV1AppConfigsForReceiving
    );

    // Create earlybird data map
    let earlybirdMockAppData = {
      mockThunderbirdV1App: mockThunderbirdV1App,
      mockThunderbirdV1RecsContract: mockThunderbirdV1RecsContract,
      mockRukhV1App: mockRukhV1App,
      mockRukhV1RecsContract: mockRukhV1RecsContract,
      configsForMockThunderbirdV1App: configsForMockThunderbirdV1App,
      configsForMockRukhV1App: configsForMockRukhV1App,
    };

    // Save earlybird mock app data
    fs.writeFileSync(EARLYBIRD_MOCK_APP_DATA_FILE_PATH, JSON.stringify(earlybirdMockAppData, null, "\t"));

    // Print statement to indicate the end of script
    console.log("\x1b[32m%s\x1b[0m", "Script ran successfully\n");
  } catch (error) {
    console.log({ error });
  }
};

/**
 * Function for fetching already deployed mock thunderbird V1 app or deploying it if it does not exist
 * @param {string} expectedMockThunderbirdV1App - 20 byte string representing the expected mock thunderbird V1 App
 * @param {string} earlybirdEndpointAddress - 20 byte string representing the earlybird endpoint address
 * @returns {string} mockThunderbirdV1AppAddress - 20 byte string representing the deployed mock thunderbird V1 App Address
 */
async function useOrDeployMockThunderbirdV1App(expectedMockThunderbirdV1App, earlybirdEndpointAddress) {
  let mockThunderbirdV1AppAddress;

  // Check if the expected mock thunderbird v1 app exists
  let expectedMockThunderbirdV1AppCode = await provider.getCode(expectedMockThunderbirdV1App);

  // Check if the earlybird endpoint exists
  let earlybirdEndpointCode = await provider.getCode(earlybirdEndpointAddress);

  // If not, deploy earlybird endpoint
  if (expectedMockThunderbirdV1AppCode == "0x" && earlybirdEndpointCode != "0x") {
    const mockThunderbirdV1AppFactory = new ethers.ContractFactory(
      mockThunderbirdV1AppFactoryData.abi,
      mockThunderbirdV1AppFactoryData.bytecode,
      wallet
    );
    const mockThunderbirdV1AppContract = await mockThunderbirdV1AppFactory.deploy(
      earlybirdEndpointAddress,
      ethers.ZeroAddress
    );
    await mockThunderbirdV1AppContract.waitForDeployment();

    mockThunderbirdV1AppAddress = await mockThunderbirdV1AppContract.getAddress();
    console.log(
      "MockThunderbirdV1App deployed on: %s, at: %s, using earlybird endpoint: %s",
      CHAIN_NAME,
      mockThunderbirdV1AppAddress,
      earlybirdEndpointAddress
    );
  } else {
    mockThunderbirdV1AppAddress = expectedMockThunderbirdV1App;
    console.log(
      "MockThunderbirdV1App already deployed on: %s, at: %s, using earlybird endpoint: %s",
      CHAIN_NAME,
      mockThunderbirdV1AppAddress,
      earlybirdEndpointAddress
    );
  }

  // return
  return mockThunderbirdV1AppAddress;
}

/**
 * Function for fetching already deployed mock thunderbird V1 recs contract or deploying it if it does not exist
 * @param {string} expectedMockThunderbirdV1RecsContract - 20 byte string representing the expected mock thunderbird V1 recs contract
 * @param {string} relayerAddress - 20 byte string representing the relayer address
 * @returns {string} mockThunderbirdV1RecsContractAddress - 20 byte string representing the deployed mock thunderbird V1 recs contract address
 */
async function useOrDeployMockThunderbirdV1RecsContract(expectedMockThunderbirdV1RecsContract, relayerAddress) {
  let mockThunderbirdV1RecsContractAddress;

  // Check if the expected mock thunderbird v1 recs contract exists
  let expectedMockThunderbirdV1RecsContractCode = await provider.getCode(expectedMockThunderbirdV1RecsContract);

  // If not, deploy earlybird endpoint
  if (expectedMockThunderbirdV1RecsContractCode == "0x") {
    const mockThunderbirdV1RecsContractFactory = new ethers.ContractFactory(
      mockThunderbirdV1RecsContractFactoryData.abi,
      mockThunderbirdV1RecsContractFactoryData.bytecode,
      wallet
    );
    const mockThunderbirdV1RecsContract = await mockThunderbirdV1RecsContractFactory.deploy(relayerAddress);
    await mockThunderbirdV1RecsContract.waitForDeployment();

    mockThunderbirdV1RecsContractAddress = await mockThunderbirdV1RecsContract.getAddress();
    console.log(
      "MockThunderbirdV1RecsContract deployed on: %s, at: %s",
      CHAIN_NAME,
      mockThunderbirdV1RecsContractAddress
    );
  } else {
    mockThunderbirdV1RecsContractAddress = expectedMockThunderbirdV1RecsContract;
    console.log(
      "MockThunderbirdV1RecsContract already deployed on: %s, at: %s",
      CHAIN_NAME,
      mockThunderbirdV1RecsContractAddress
    );
  }

  // return
  return mockThunderbirdV1RecsContractAddress;
}

/**
 * Function for updating configs for mock thunderbird V1 app
 * @param {string} mockThunderbirdV1App - 20 byte string representing the expected mock rukh V1 recs contract
 * @param {string} earlybirdEndpointAddress - 20 byte string representing the relayer address
 * @param {string} appConfigsForSending - encoded map indicating the mock thunderbird V1 app configs for sending messages
 * @param {string} appConfigsForReceiving - encoded map indicating the mock thunderbird V1 app configs for receiving messages
 */
async function updateConfigsForMockThunderbirdV1App(
  mockThunderbirdV1App,
  earlybirdEndpointAddress,
  appConfigsForSending,
  appConfigsForReceiving
) {
  // Check if the mock rukh v1 app exists
  let mockThunderbirdV1AppCode = await provider.getCode(mockThunderbirdV1App);

  // Check if the earlybird endpoint exists
  let earlybirdEndpointCode = await provider.getCode(earlybirdEndpointAddress);

  // If not, throw error
  if (mockThunderbirdV1AppCode != "0x" && earlybirdEndpointCode != "0x") {
    const earlybirdEndpointContract = new ethers.Contract(
      earlybirdEndpointAddress,
      earlybirdEndpointV1FactoryData.abi,
      provider
    );

    let currentAppConfigsForSending;
    let currentAppConfigsForReceiving;
    try {
      currentAppConfigsForSending = await earlybirdEndpointContract.getAppConfigForSending(mockThunderbirdV1App);
      currentAppConfigsForReceiving = await earlybirdEndpointContract.getAppConfigForReceiving(mockThunderbirdV1App);
    } catch {}

    if (
      currentAppConfigsForSending == appConfigsForSending &&
      currentAppConfigsForReceiving == appConfigsForReceiving
    ) {
      console.log("MockThunderbirdV1App on %s configs already set", CHAIN_NAME);
    } else {
      const mockThunderbirdV1AppContract = new ethers.Contract(
        mockThunderbirdV1App,
        mockThunderbirdV1AppFactoryData.abi,
        wallet
      );
      const setConfigsTx = await mockThunderbirdV1AppContract.setLibraryAndConfigs(
        "Thunderbird V1",
        appConfigsForSending,
        appConfigsForReceiving
      );
      await setConfigsTx.wait();
      console.log("MockThunderbirdV1App on %s configs set", CHAIN_NAME);
    }
  }
}

/**
 * Function for fetching already deployed mock thunderbird V1 recs contract or deploying it if it does not exist
 * @param {string} expectedMockRukhV1App - 20 byte string representing the expected mock rukh V1 app
 * @param {string} earlybirdEndpointAddress - 20 byte string representing the earlybird endpoint address
 * @returns {string} mockRukhV1AppAddress - 20 byte string representing the deployed mock rukh V1 app address
 */
async function useOrDeployMockRukhV1App(expectedMockRukhV1App, earlybirdEndpointAddress) {
  let mockRukhV1AppAddress;

  // Check if the expected mock rukh v1 app exists
  let expectedMockRukhV1AppCode = await provider.getCode(expectedMockRukhV1App);

  // Check if the earlybird endpoint exists
  let earlybirdEndpointCode = await provider.getCode(earlybirdEndpointAddress);

  // If not, deploy earlybird endpoint
  if (expectedMockRukhV1AppCode == "0x" && earlybirdEndpointCode != "0x") {
    const mockRukhV1AppFactory = new ethers.ContractFactory(
      mockRukhV1AppFactoryData.abi,
      mockRukhV1AppFactoryData.bytecode,
      wallet
    );
    const mockRukhV1AppContract = await mockRukhV1AppFactory.deploy(earlybirdEndpointAddress, ethers.ZeroAddress);
    await mockRukhV1AppContract.waitForDeployment();

    mockRukhV1AppAddress = await mockRukhV1AppContract.getAddress();
    console.log(
      "MockRukhV1App deployed on: %s, at: %s, using earlybird endpoint: %s",
      CHAIN_NAME,
      mockRukhV1AppAddress,
      earlybirdEndpointAddress
    );
  } else {
    mockRukhV1AppAddress = expectedMockRukhV1App;
    console.log(
      "MockRukhV1App already deployed on: %s, at: %s, using earlybird endpoint: %s",
      CHAIN_NAME,
      mockRukhV1AppAddress,
      earlybirdEndpointAddress
    );
  }

  // return
  return mockRukhV1AppAddress;
}

/**
 * Function for fetching already deployed mock rukh V1 recs contract or deploying it if it does not exist
 * @param {string} expectedMockRukhV1RecsContract - 20 byte string representing the expected mock rukh V1 recs contract
 * @param {string} relayerAddress - 20 byte string representing the relayer address
 * @returns {string} mockRukhV1RecsContractAddress - 20 byte string representing the deployed mock rukh V1 recs contract address
 */
async function useOrDeployMockRukhV1RecsContract(expectedMockRukhV1RecsContract, relayerAddress) {
  let mockRukhV1RecsContractAddress;

  // Check if the expected mock thunderbird v1 recs contract exists
  let expectedMockRukhV1RecsContractCode = await provider.getCode(expectedMockRukhV1RecsContract);

  // If not, deploy earlybird endpoint
  if (expectedMockRukhV1RecsContractCode == "0x") {
    const mockRukhV1RecsContractFactory = new ethers.ContractFactory(
      mockRukhV1RecsContractFactoryData.abi,
      mockRukhV1RecsContractFactoryData.bytecode,
      wallet
    );
    const mockRukhV1RecsContract = await mockRukhV1RecsContractFactory.deploy(relayerAddress);
    await mockRukhV1RecsContract.waitForDeployment();

    mockRukhV1RecsContractAddress = await mockRukhV1RecsContract.getAddress();
    console.log("MockRukhV1RecsContract deployed on: %s, at: %s", CHAIN_NAME, mockRukhV1RecsContractAddress);
  } else {
    mockRukhV1RecsContractAddress = expectedMockRukhV1RecsContract;
    console.log("MockRukhV1RecsContract already deployed on: %s, at: %s", CHAIN_NAME, mockRukhV1RecsContractAddress);
  }

  // return
  return mockRukhV1RecsContractAddress;
}

/**
 * Function for updating configs for mock rukh V1 app
 * @param {string} mockRukhV1App - 20 byte string representing the expected mock rukh V1 recs contract
 * @param {string} earlybirdEndpointAddress - 20 byte string representing the relayer address
 * @param {string} appConfigsForSending - encoded map indicating the mock rukh V1 app configs for sending messages
 * @param {string} appConfigsForReceiving - encoded map indicating the mock rukh V1 app configs for receiving messages
 */
async function updateConfigsForMockRukhV1App(
  mockRukhV1App,
  earlybirdEndpointAddress,
  appConfigsForSending,
  appConfigsForReceiving
) {
  // Check if the mock rukh v1 app exists
  let mockRukhV1AppCode = await provider.getCode(mockRukhV1App);

  // Check if the earlybird endpoint exists
  let earlybirdEndpointCode = await provider.getCode(earlybirdEndpointAddress);

  // If not, throw error
  if (mockRukhV1AppCode != "0x" && earlybirdEndpointCode != "0x") {
    const earlybirdEndpointContract = new ethers.Contract(
      earlybirdEndpointAddress,
      earlybirdEndpointV1FactoryData.abi,
      provider
    );

    let currentAppConfigsForSending;
    let currentAppConfigsForReceiving;
    try {
      currentAppConfigsForSending = await earlybirdEndpointContract.getAppConfigForSending(mockRukhV1App);
      currentAppConfigsForReceiving = await earlybirdEndpointContract.getAppConfigForReceiving(mockRukhV1App);
    } catch {}

    if (
      currentAppConfigsForSending == appConfigsForSending &&
      currentAppConfigsForReceiving == appConfigsForReceiving
    ) {
      console.log("MockRukhV1App on %s configs already set", CHAIN_NAME);
    } else {
      const mockRukhV1AppContract = new ethers.Contract(mockRukhV1App, mockRukhV1AppFactoryData.abi, wallet);
      const setConfigsTx = await mockRukhV1AppContract.setLibraryAndConfigs(
        "Rukh V1",
        appConfigsForSending,
        appConfigsForReceiving
      );
      await setConfigsTx.wait();
      console.log("MockRukhV1App on %s configs set", CHAIN_NAME);
    }
  }
}

/**
 * Function for getting ad creating configs for mock thunderbird V1 app
 * @param {string} mockThunderbirdV1RecsContract - 20 byte string representing the mock thunderbird V1 recs contract
 * @param {Map<String, String>} earlybirdPeripheryContractsData - map indicating the earlybird periphery contract data
 * @returns {Map<String, Any>} map containing all the configs for mock thunderbird V1 app
 */
async function getConfigsForMockThunderbirdV1App(mockThunderbirdV1RecsContract, earlybirdPeripheryContractsData) {
  // Instantiate abi encoder
  let abiCoder = new ethers.AbiCoder();

  // Creating mock thunderbird V1 app configs for sending
  let mockThunderbirdV1AppConfigsForSending = {
    isSelfBroadcasting: false,
    oracleFeeCollector: earlybirdPeripheryContractsData.oracle,
    relayerFeeCollector: earlybirdPeripheryContractsData.relayer,
  };

  // Encoding mock thunderbird V1 app configs for sending
  let encodedMockThunderbirdV1AppConfigsForSending = abiCoder.encode(
    ["tuple(bool a, address b, address c) d"],
    [
      [
        mockThunderbirdV1AppConfigsForSending.isSelfBroadcasting,
        mockThunderbirdV1AppConfigsForSending.oracleFeeCollector,
        mockThunderbirdV1AppConfigsForSending.relayerFeeCollector,
      ],
    ]
  );

  // Creating mock thunderbird V1 app configs for receiving
  let mockThunderbirdV1AppConfigsForReceiving = {
    oracle: earlybirdPeripheryContractsData.oracle,
    relayer: earlybirdPeripheryContractsData.relayer,
    recsContract: mockThunderbirdV1RecsContract,
    emitMsgProofs: true,
    directMsgsEnabled: false,
    msgDeliveryPaused: false,
  };

  // Encoding mock thunderbird V1 app configs for receiving
  let encodedMockThunderbirdV1AppConfigsForReceiving = abiCoder.encode(
    ["tuple(address a, address b, address c, bool d, bool e, bool f) g"],
    [
      [
        mockThunderbirdV1AppConfigsForReceiving.oracle,
        mockThunderbirdV1AppConfigsForReceiving.relayer,
        mockThunderbirdV1AppConfigsForReceiving.recsContract,
        mockThunderbirdV1AppConfigsForReceiving.emitMsgProofs,
        mockThunderbirdV1AppConfigsForReceiving.directMsgsEnabled,
        mockThunderbirdV1AppConfigsForReceiving.msgDeliveryPaused,
      ],
    ]
  );

  return {
    encodedMockThunderbirdV1AppConfigsForSending: encodedMockThunderbirdV1AppConfigsForSending,
    encodedMockThunderbirdV1AppConfigsForReceiving: encodedMockThunderbirdV1AppConfigsForReceiving,
    mockThunderbirdV1AppConfigsForSending: mockThunderbirdV1AppConfigsForSending,
    mockThunderbirdV1AppConfigsForReceiving: mockThunderbirdV1AppConfigsForReceiving
  }
}

/**
 * Function for getting ad creating configs for mock rukh V1 app
 * @param {string} mockRukhV1RecsContract - 20 byte string representing the mock rukh V1 recs contract
 * @param {Map<String, String>} earlybirdPeripheryContractsData - map indicating the earlybird periphery contract data
 * @returns {Map<String, Any>} map containing all the configs for mock rukh V1 app
 */
async function getConfigsForMockRukhV1App(mockRukhV1RecsContract, earlybirdPeripheryContractsData) {
  // Instantiate abi encoder
  let abiCoder = new ethers.AbiCoder();

  // Creating mock rukh V1 app configs for sending
  let mockRukhV1AppConfigsForSending = {
    isSelfBroadcasting: false,
    oracleFeeCollector: earlybirdPeripheryContractsData.oracle,
    relayerFeeCollector: earlybirdPeripheryContractsData.relayer,
  };

  // Encoding mock rukh V1 app configs for sending
  let encodedMockRukhV1AppConfigsForSending = abiCoder.encode(
    ["tuple(bool a, address b, address c) d"],
    [
      [
        mockRukhV1AppConfigsForSending.isSelfBroadcasting,
        mockRukhV1AppConfigsForSending.oracleFeeCollector,
        mockRukhV1AppConfigsForSending.relayerFeeCollector,
      ],
    ]
  );

  // Creating mock thunderbird V1 app configs for receiving
  let mockRukhV1AppConfigsForReceiving = {
    minDisputeTime: 10,
    minDisputeResolutionExtension: 10,
    disputeEpochLength: 100,
    maxValidDisputesPerEpoch: 1,
    oracle: earlybirdPeripheryContractsData.oracle,
    defaultRelayer: earlybirdPeripheryContractsData.relayer,
    disputersContract: earlybirdPeripheryContractsData.disputerContract,
    disputeResolver: earlybirdPeripheryContractsData.disputeResolver,
    recsContract: mockRukhV1RecsContract,
    emitMsgProofs: true,
    directMsgsEnabled: true,
    msgDeliveryPaused: false,
  };

  // Encoding mock thunderbird V1 app configs for receiving
  let encodedMockRukhV1AppConfigsForReceiving = abiCoder.encode(
    [
      "tuple(uint256 a, uint256 b, uint256 c, uint256 d, address e, address f, address g, address h, address i, bool j, bool k, bool l) m",
    ],
    [
      [
        mockRukhV1AppConfigsForReceiving.minDisputeTime,
        mockRukhV1AppConfigsForReceiving.minDisputeResolutionExtension,
        mockRukhV1AppConfigsForReceiving.disputeEpochLength,
        mockRukhV1AppConfigsForReceiving.maxValidDisputesPerEpoch,
        mockRukhV1AppConfigsForReceiving.oracle,
        mockRukhV1AppConfigsForReceiving.defaultRelayer,
        mockRukhV1AppConfigsForReceiving.disputersContract,
        mockRukhV1AppConfigsForReceiving.disputeResolver,
        mockRukhV1AppConfigsForReceiving.recsContract,
        mockRukhV1AppConfigsForReceiving.emitMsgProofs,
        mockRukhV1AppConfigsForReceiving.directMsgsEnabled,
        mockRukhV1AppConfigsForReceiving.msgDeliveryPaused,
      ],
    ]
  );

  return {
    encodedMockRukhV1AppConfigsForSending: encodedMockRukhV1AppConfigsForSending,
    encodedMockRukhV1AppConfigsForReceiving: encodedMockRukhV1AppConfigsForReceiving,
    mockRukhV1AppConfigsForSending: mockRukhV1AppConfigsForSending,
    mockRukhV1AppConfigsForReceiving: mockRukhV1AppConfigsForReceiving
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
 * Function for reading expected Earlybird Mock App data from a file.
 * @param {string} file_path - string representing the path for the file holding the expected earlybird mock app data
 * @returns {Map<String, String>} - map containing all the expected earlybird mock app data
 */
async function readExpectedEarlybirdMockAppData(file_path) {
  try {
    data = fs.readFileSync(file_path);
    return JSON.parse(data);
  } catch (err) {
    return {
      mockThunderbirdV1App: ethers.ZeroAddress,
      mockThunderbirdV1RecsContract: ethers.ZeroAddress,
      mockRukhV1App: ethers.ZeroAddress,
      mockRukhV1RecsContract: ethers.ZeroAddress,
    };
  }
}

deployEarlybirdMockApp();
