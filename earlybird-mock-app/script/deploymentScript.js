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
const earlybirdEndpointFactoryData = require("../out/IEarlybirdEndpoint.sol/IEarlybirdEndpoint.json");
const mockThunderbirdAppFactoryData = require("../out/ThunderbirdVersion/MockApp.sol/MockApp.json");
const mockThunderbirdRecsContractFactoryData = require("../out/ThunderbirdVersion/RecsContract.sol/RecsContract.json");
const mockRukhAppFactoryData = require("../out/RukhVersion/MockApp.sol/MockApp.json");
const mockRukhRecsContractFactoryData = require("../out/RukhVersion/RecsContract.sol/RecsContract.json");

// Function for deploying earlybird mock app
const deployEarlybirdMockApp = async () => {
  try {
    // Print statement to indicate beginning of script
    console.log("\n=== Earlybird Mock App EVM Deployments on %s ===\n", CHAIN_NAME);

    // Read deployment addresses
    let deploymentAddresses = await readData(DEPLOYMENT_ADDRESSES_FILE_PATH, false);

    // Read earlybird data on spoke chain
    let earlybirdData = await readDeploymentAddressesForProtocol(deploymentAddresses, "earlybirdDeploymentData", "");

    // Read earlybird periphery contracts data on spoke chain
    let earlybirdPeripheryContractsData = await readDeploymentAddressesForProtocol(
      deploymentAddresses,
      "earlybirdPeripheryContractsDeploymentData",
      ""
    );

    // Read expected earlybird mock app data
    let expectedEarlybirdMockAppData = await readDeploymentAddressesForProtocol(
      deploymentAddresses,
      "earlybirdMockAppDeploymentData",
      emptyEarlybirdMockAppDeploymentData()
    );

    // Get or deploy mock thunderbird app
    let mockThunderbirdApp = await useOrDeployMockThunderbirdApp(
      expectedEarlybirdMockAppData.mockThunderbirdApp,
      earlybirdData.earlybirdEndpoint
    );

    // Get or deploy mock thunderbird recs contract
    let mockThunderbirdRecsContract = await useOrDeployMockThunderbirdRecsContract(
      expectedEarlybirdMockAppData.mockThunderbirdRecsContract,
      earlybirdPeripheryContractsData.relayer
    );

    // Get configs for mock thunderbird app
    let configsForMockThunderbirdApp = await getConfigsForMockThunderbirdApp(
      mockThunderbirdRecsContract,
      earlybirdPeripheryContractsData
    );

    // Update configs for mock thunderbird app
    await updateConfigsForMockThunderbirdApp(
      mockThunderbirdApp,
      earlybirdData.earlybirdEndpoint,
      configsForMockThunderbirdApp.encodedMockThunderbirdAppConfigsForSending,
      configsForMockThunderbirdApp.encodedMockThunderbirdAppConfigsForReceiving
    );

    // Get or deploy mock rukh app
    let mockRukhApp = await useOrDeployMockRukhApp(
      expectedEarlybirdMockAppData.mockRukhApp,
      earlybirdData.earlybirdEndpoint
    );

    // Get or deploy mock rukh recs contract
    let mockRukhRecsContract = await useOrDeployMockRukhRecsContract(
      expectedEarlybirdMockAppData.mockRukhRecsContract,
      earlybirdPeripheryContractsData.relayer
    );

    // Get configs for mock rukh app
    let configsForMockRukhApp = await getConfigsForMockRukhApp(
      mockRukhRecsContract,
      earlybirdPeripheryContractsData
    );

    // Update configs for mock rukh app
    await updateConfigsForMockRukhApp(
      mockRukhApp,
      earlybirdData.earlybirdEndpoint,
      configsForMockRukhApp.encodedMockRukhAppConfigsForSending,
      configsForMockRukhApp.encodedMockRukhAppConfigsForReceiving
    );

    // Create earlybird mock app deployment data map
    deploymentAddresses.earlybirdMockAppDeploymentData = {
      mockThunderbirdApp: mockThunderbirdApp,
      mockThunderbirdRecsContract: mockThunderbirdRecsContract,
      mockRukhApp: mockRukhApp,
      mockRukhRecsContract: mockRukhRecsContract,
      configsForMockThunderbirdApp: configsForMockThunderbirdApp,
      configsForMockRukhApp: configsForMockRukhApp,
    };

    // Save deployment addresses
    fs.writeFileSync(DEPLOYMENT_ADDRESSES_FILE_PATH, JSON.stringify(deploymentAddresses, null, "\t"));

    // Print statement to indicate the end of script
    console.log("\x1b[32m%s\x1b[0m", "Script ran successfully\n");
  } catch (error) {
    console.log({ error });
  }
};

/**
 * Function for fetching already deployed mock thunderbird app or deploying it if it does not exist
 * @param {string} expectedMockThunderbirdApp - 20 byte string representing the expected mock thunderbird App
 * @param {string} earlybirdEndpointAddress - 20 byte string representing the earlybird endpoint address
 * @returns {string} mockThunderbirdAppAddress - 20 byte string representing the deployed mock thunderbird App Address
 */
async function useOrDeployMockThunderbirdApp(expectedMockThunderbirdApp, earlybirdEndpointAddress) {
  let mockThunderbirdAppAddress;

  // Check if the expected mock thunderbird app exists
  let expectedMockThunderbirdAppCode = await provider.getCode(expectedMockThunderbirdApp);

  // Check if the earlybird endpoint exists
  let earlybirdEndpointCode = await provider.getCode(earlybirdEndpointAddress);

  // If not, deploy earlybird endpoint
  if (expectedMockThunderbirdAppCode == "0x" && earlybirdEndpointCode != "0x") {
    const mockThunderbirdAppFactory = new ethers.ContractFactory(
      mockThunderbirdAppFactoryData.abi,
      mockThunderbirdAppFactoryData.bytecode,
      wallet
    );
    const mockThunderbirdAppContract = await mockThunderbirdAppFactory.deploy(
      earlybirdEndpointAddress,
      ethers.ZeroAddress
    );
    await mockThunderbirdAppContract.waitForDeployment();

    mockThunderbirdAppAddress = await mockThunderbirdAppContract.getAddress();
    console.log(
      "MockThunderbirdApp deployed on: %s, at: %s, using earlybird endpoint: %s",
      CHAIN_NAME,
      mockThunderbirdAppAddress,
      earlybirdEndpointAddress
    );
  } else {
    mockThunderbirdAppAddress = expectedMockThunderbirdApp;
    console.log(
      "MockThunderbirdApp already deployed on: %s, at: %s, using earlybird endpoint: %s",
      CHAIN_NAME,
      mockThunderbirdAppAddress,
      earlybirdEndpointAddress
    );
  }

  // return
  return mockThunderbirdAppAddress;
}

/**
 * Function for fetching already deployed mock thunderbird  recs contract or deploying it if it does not exist
 * @param {string} expectedMockThunderbirdRecsContract - 20 byte string representing the expected mock thunderbird  recs contract
 * @param {string} relayerAddress - 20 byte string representing the relayer address
 * @returns {string} mockThunderbirdRecsContractAddress - 20 byte string representing the deployed mock thunderbird  recs contract address
 */
async function useOrDeployMockThunderbirdRecsContract(expectedMockThunderbirdRecsContract, relayerAddress) {
  let mockThunderbirdRecsContractAddress;

  // Check if the expected mock thunderbird  recs contract exists
  let expectedMockThunderbirdRecsContractCode = await provider.getCode(expectedMockThunderbirdRecsContract);

  // If not, deploy earlybird endpoint
  if (expectedMockThunderbirdRecsContractCode == "0x") {
    const mockThunderbirdRecsContractFactory = new ethers.ContractFactory(
      mockThunderbirdRecsContractFactoryData.abi,
      mockThunderbirdRecsContractFactoryData.bytecode,
      wallet
    );
    const mockThunderbirdRecsContract = await mockThunderbirdRecsContractFactory.deploy(relayerAddress);
    await mockThunderbirdRecsContract.waitForDeployment();

    mockThunderbirdRecsContractAddress = await mockThunderbirdRecsContract.getAddress();
    console.log(
      "MockThunderbirdRecsContract deployed on: %s, at: %s",
      CHAIN_NAME,
      mockThunderbirdRecsContractAddress
    );
  } else {
    mockThunderbirdRecsContractAddress = expectedMockThunderbirdRecsContract;
    console.log(
      "MockThunderbirdRecsContract already deployed on: %s, at: %s",
      CHAIN_NAME,
      mockThunderbirdRecsContractAddress
    );
  }

  // return
  return mockThunderbirdRecsContractAddress;
}

/**
 * Function for updating configs for mock thunderbird  app
 * @param {string} mockThunderbirdApp - 20 byte string representing the expected mock rukh  recs contract
 * @param {string} earlybirdEndpointAddress - 20 byte string representing the relayer address
 * @param {string} appConfigsForSending - encoded map indicating the mock thunderbird  app configs for sending messages
 * @param {string} appConfigsForReceiving - encoded map indicating the mock thunderbird  app configs for receiving messages
 */
async function updateConfigsForMockThunderbirdApp(
  mockThunderbirdApp,
  earlybirdEndpointAddress,
  appConfigsForSending,
  appConfigsForReceiving
) {
  // Check if the mock rukh  app exists
  let mockThunderbirdAppCode = await provider.getCode(mockThunderbirdApp);

  // Check if the earlybird endpoint exists
  let earlybirdEndpointCode = await provider.getCode(earlybirdEndpointAddress);

  // If not, throw error
  if (mockThunderbirdAppCode != "0x" && earlybirdEndpointCode != "0x") {
    const earlybirdEndpointContract = new ethers.Contract(
      earlybirdEndpointAddress,
      earlybirdEndpointFactoryData.abi,
      provider
    );

    let currentAppConfigsForSending;
    let currentAppConfigsForReceiving;
    try {
      currentAppConfigsForSending = await earlybirdEndpointContract.getAppConfigForSending(mockThunderbirdApp);
      currentAppConfigsForReceiving = await earlybirdEndpointContract.getAppConfigForReceiving(mockThunderbirdApp);
    } catch { }

    if (
      currentAppConfigsForSending == appConfigsForSending &&
      currentAppConfigsForReceiving == appConfigsForReceiving
    ) {
      console.log("MockThunderbirdApp on %s configs already set", CHAIN_NAME);
    } else {
      const mockThunderbirdAppContract = new ethers.Contract(
        mockThunderbirdApp,
        mockThunderbirdAppFactoryData.abi,
        wallet
      );
      const setConfigsTx = await mockThunderbirdAppContract.setLibraryAndConfigs(
        "Thunderbird ",
        appConfigsForSending,
        appConfigsForReceiving
      );
      await setConfigsTx.wait();
      console.log("MockThunderbirdApp on %s configs set", CHAIN_NAME);
    }
  }
}

/**
 * Function for fetching already deployed mock thunderbird  recs contract or deploying it if it does not exist
 * @param {string} expectedMockRukhApp - 20 byte string representing the expected mock rukh  app
 * @param {string} earlybirdEndpointAddress - 20 byte string representing the earlybird endpoint address
 * @returns {string} mockRukhAppAddress - 20 byte string representing the deployed mock rukh  app address
 */
async function useOrDeployMockRukhApp(expectedMockRukhApp, earlybirdEndpointAddress) {
  let mockRukhAppAddress;

  // Check if the expected mock rukh  app exists
  let expectedMockRukhAppCode = await provider.getCode(expectedMockRukhApp);

  // Check if the earlybird endpoint exists
  let earlybirdEndpointCode = await provider.getCode(earlybirdEndpointAddress);

  // If not, deploy earlybird endpoint
  if (expectedMockRukhAppCode == "0x" && earlybirdEndpointCode != "0x") {
    const mockRukhAppFactory = new ethers.ContractFactory(
      mockRukhAppFactoryData.abi,
      mockRukhAppFactoryData.bytecode,
      wallet
    );
    const mockRukhAppContract = await mockRukhAppFactory.deploy(earlybirdEndpointAddress, ethers.ZeroAddress);
    await mockRukhAppContract.waitForDeployment();

    mockRukhAppAddress = await mockRukhAppContract.getAddress();
    console.log(
      "MockRukhApp deployed on: %s, at: %s, using earlybird endpoint: %s",
      CHAIN_NAME,
      mockRukhAppAddress,
      earlybirdEndpointAddress
    );
  } else {
    mockRukhAppAddress = expectedMockRukhApp;
    console.log(
      "MockRukhApp already deployed on: %s, at: %s, using earlybird endpoint: %s",
      CHAIN_NAME,
      mockRukhAppAddress,
      earlybirdEndpointAddress
    );
  }

  // return
  return mockRukhAppAddress;
}

/**
 * Function for fetching already deployed mock rukh  recs contract or deploying it if it does not exist
 * @param {string} expectedMockRukhRecsContract - 20 byte string representing the expected mock rukh  recs contract
 * @param {string} relayerAddress - 20 byte string representing the relayer address
 * @returns {string} mockRukhRecsContractAddress - 20 byte string representing the deployed mock rukh  recs contract address
 */
async function useOrDeployMockRukhRecsContract(expectedMockRukhRecsContract, relayerAddress) {
  let mockRukhRecsContractAddress;

  // Check if the expected mock thunderbird  recs contract exists
  let expectedMockRukhRecsContractCode = await provider.getCode(expectedMockRukhRecsContract);

  // If not, deploy earlybird endpoint
  if (expectedMockRukhRecsContractCode == "0x") {
    const mockRukhRecsContractFactory = new ethers.ContractFactory(
      mockRukhRecsContractFactoryData.abi,
      mockRukhRecsContractFactoryData.bytecode,
      wallet
    );
    const mockRukhRecsContract = await mockRukhRecsContractFactory.deploy(relayerAddress);
    await mockRukhRecsContract.waitForDeployment();

    mockRukhRecsContractAddress = await mockRukhRecsContract.getAddress();
    console.log("MockRukhRecsContract deployed on: %s, at: %s", CHAIN_NAME, mockRukhRecsContractAddress);
  } else {
    mockRukhRecsContractAddress = expectedMockRukhRecsContract;
    console.log("MockRukhRecsContract already deployed on: %s, at: %s", CHAIN_NAME, mockRukhRecsContractAddress);
  }

  // return
  return mockRukhRecsContractAddress;
}

/**
 * Function for updating configs for mock rukh  app
 * @param {string} mockRukhApp - 20 byte string representing the expected mock rukh  recs contract
 * @param {string} earlybirdEndpointAddress - 20 byte string representing the relayer address
 * @param {string} appConfigsForSending - encoded map indicating the mock rukh  app configs for sending messages
 * @param {string} appConfigsForReceiving - encoded map indicating the mock rukh  app configs for receiving messages
 */
async function updateConfigsForMockRukhApp(
  mockRukhApp,
  earlybirdEndpointAddress,
  appConfigsForSending,
  appConfigsForReceiving
) {
  // Check if the mock rukh  app exists
  let mockRukhAppCode = await provider.getCode(mockRukhApp);

  // Check if the earlybird endpoint exists
  let earlybirdEndpointCode = await provider.getCode(earlybirdEndpointAddress);

  // If not, throw error
  if (mockRukhAppCode != "0x" && earlybirdEndpointCode != "0x") {
    const earlybirdEndpointContract = new ethers.Contract(
      earlybirdEndpointAddress,
      earlybirdEndpointFactoryData.abi,
      provider
    );

    let currentAppConfigsForSending;
    let currentAppConfigsForReceiving;
    try {
      currentAppConfigsForSending = await earlybirdEndpointContract.getAppConfigForSending(mockRukhApp);
      currentAppConfigsForReceiving = await earlybirdEndpointContract.getAppConfigForReceiving(mockRukhApp);
    } catch { }

    if (
      currentAppConfigsForSending == appConfigsForSending &&
      currentAppConfigsForReceiving == appConfigsForReceiving
    ) {
      console.log("MockRukhApp on %s configs already set", CHAIN_NAME);
    } else {
      const mockRukhAppContract = new ethers.Contract(mockRukhApp, mockRukhAppFactoryData.abi, wallet);
      const setConfigsTx = await mockRukhAppContract.setLibraryAndConfigs(
        "Rukh ",
        appConfigsForSending,
        appConfigsForReceiving
      );
      await setConfigsTx.wait();
      console.log("MockRukhApp on %s configs set", CHAIN_NAME);
    }
  }
}

/**
 * Function for getting ad creating configs for mock thunderbird  app
 * @param {string} mockThunderbirdRecsContract - 20 byte string representing the mock thunderbird  recs contract
 * @param {Map<String, String>} earlybirdPeripheryContractsData - map indicating the earlybird periphery contract data
 * @returns {Map<String, Any>} map containing all the configs for mock thunderbird  app
 */
async function getConfigsForMockThunderbirdApp(mockThunderbirdRecsContract, earlybirdPeripheryContractsData) {
  // Instantiate abi encoder
  let abiCoder = new ethers.AbiCoder();

  // Creating mock thunderbird  app configs for sending
  let mockThunderbirdAppConfigsForSending = {
    isSelfBroadcasting: false,
    useGasEfficientBroadcasting: false,
    oracleFeeCollector: earlybirdPeripheryContractsData.oracle,
    relayerFeeCollector: earlybirdPeripheryContractsData.relayer,
  };

  // Encoding mock thunderbird  app configs for sending
  let encodedMockThunderbirdAppConfigsForSending = abiCoder.encode(
    ["tuple(bool a, bool b, address c, address d) e"],
    [
      [
        mockThunderbirdAppConfigsForSending.isSelfBroadcasting,
        mockThunderbirdAppConfigsForSending.useGasEfficientBroadcasting,
        mockThunderbirdAppConfigsForSending.oracleFeeCollector,
        mockThunderbirdAppConfigsForSending.relayerFeeCollector,
      ],
    ]
  );

  // Creating mock thunderbird  app configs for receiving
  let mockThunderbirdAppConfigsForReceiving = {
    oracle: earlybirdPeripheryContractsData.oracle,
    relayer: earlybirdPeripheryContractsData.relayer,
    recsContract: mockThunderbirdRecsContract,
    emitMsgProofs: true,
    directMsgsEnabled: false,
    msgDeliveryPaused: false,
  };

  // Encoding mock thunderbird  app configs for receiving
  let encodedMockThunderbirdAppConfigsForReceiving = abiCoder.encode(
    ["tuple(address a, address b, address c, bool d, bool e, bool f) g"],
    [
      [
        mockThunderbirdAppConfigsForReceiving.oracle,
        mockThunderbirdAppConfigsForReceiving.relayer,
        mockThunderbirdAppConfigsForReceiving.recsContract,
        mockThunderbirdAppConfigsForReceiving.emitMsgProofs,
        mockThunderbirdAppConfigsForReceiving.directMsgsEnabled,
        mockThunderbirdAppConfigsForReceiving.msgDeliveryPaused,
      ],
    ]
  );

  return {
    encodedMockThunderbirdAppConfigsForSending: encodedMockThunderbirdAppConfigsForSending,
    encodedMockThunderbirdAppConfigsForReceiving: encodedMockThunderbirdAppConfigsForReceiving,
    mockThunderbirdAppConfigsForSending: mockThunderbirdAppConfigsForSending,
    mockThunderbirdAppConfigsForReceiving: mockThunderbirdAppConfigsForReceiving,
  };
}

/**
 * Function for getting ad creating configs for mock rukh  app
 * @param {string} mockRukhRecsContract - 20 byte string representing the mock rukh  recs contract
 * @param {Map<String, String>} earlybirdPeripheryContractsData - map indicating the earlybird periphery contract data
 * @returns {Map<String, Any>} map containing all the configs for mock rukh  app
 */
async function getConfigsForMockRukhApp(mockRukhRecsContract, earlybirdPeripheryContractsData) {
  // Instantiate abi encoder
  let abiCoder = new ethers.AbiCoder();

  // Creating mock rukh  app configs for sending
  let mockRukhAppConfigsForSending = {
    isSelfBroadcasting: false,
    useGasEfficientBroadcasting: false,
    oracleFeeCollector: earlybirdPeripheryContractsData.oracle,
    relayerFeeCollector: earlybirdPeripheryContractsData.relayer,
  };

  // Encoding mock rukh  app configs for sending
  let encodedMockRukhAppConfigsForSending = abiCoder.encode(
    ["tuple(bool a, bool b, address c, address d) e"],
    [
      [
        mockRukhAppConfigsForSending.isSelfBroadcasting,
        mockRukhAppConfigsForSending.useGasEfficientBroadcasting,
        mockRukhAppConfigsForSending.oracleFeeCollector,
        mockRukhAppConfigsForSending.relayerFeeCollector,
      ],
    ]
  );

  // Creating mock thunderbird  app configs for receiving
  let mockRukhAppConfigsForReceiving = {
    minDisputeTime: 10,
    minDisputeResolutionExtension: 10,
    disputeEpochLength: 100,
    maxValidDisputesPerEpoch: 1,
    oracle: earlybirdPeripheryContractsData.oracle,
    defaultRelayer: earlybirdPeripheryContractsData.relayer,
    disputersContract: earlybirdPeripheryContractsData.disputerContract,
    disputeResolver: earlybirdPeripheryContractsData.disputeResolver,
    recsContract: mockRukhRecsContract,
    emitMsgProofs: true,
    directMsgsEnabled: true,
    msgDeliveryPaused: false,
  };

  // Encoding mock thunderbird  app configs for receiving
  let encodedMockRukhAppConfigsForReceiving = abiCoder.encode(
    [
      "tuple(uint256 a, uint256 b, uint256 c, uint256 d, address e, address f, address g, address h, address i, bool j, bool k, bool l) m",
    ],
    [
      [
        mockRukhAppConfigsForReceiving.minDisputeTime,
        mockRukhAppConfigsForReceiving.minDisputeResolutionExtension,
        mockRukhAppConfigsForReceiving.disputeEpochLength,
        mockRukhAppConfigsForReceiving.maxValidDisputesPerEpoch,
        mockRukhAppConfigsForReceiving.oracle,
        mockRukhAppConfigsForReceiving.defaultRelayer,
        mockRukhAppConfigsForReceiving.disputersContract,
        mockRukhAppConfigsForReceiving.disputeResolver,
        mockRukhAppConfigsForReceiving.recsContract,
        mockRukhAppConfigsForReceiving.emitMsgProofs,
        mockRukhAppConfigsForReceiving.directMsgsEnabled,
        mockRukhAppConfigsForReceiving.msgDeliveryPaused,
      ],
    ]
  );

  return {
    encodedMockRukhAppConfigsForSending: encodedMockRukhAppConfigsForSending,
    encodedMockRukhAppConfigsForReceiving: encodedMockRukhAppConfigsForReceiving,
    mockRukhAppConfigsForSending: mockRukhAppConfigsForSending,
    mockRukhAppConfigsForReceiving: mockRukhAppConfigsForReceiving,
  };
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
 * Function that returns an empty earlybird mock app deployment data map
 */
function emptyEarlybirdMockAppDeploymentData() {
  return {
    mockThunderbirdApp: ethers.ZeroAddress,
    mockThunderbirdRecsContract: ethers.ZeroAddress,
    mockRukhApp: ethers.ZeroAddress,
    mockRukhRecsContract: ethers.ZeroAddress,
  };
}

deployEarlybirdMockApp();
