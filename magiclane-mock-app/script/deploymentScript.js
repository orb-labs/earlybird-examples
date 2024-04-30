const { ethers } = require('ethers');
const fs = require('node:fs');

// Fetching environment variables
const CHAIN_NAME = process.env.CHAIN_NAME;
const RPC_URL = process.env.RPC_URL;
const MNEMONICS = process.env.MNEMONICS;
const NUMBER_OF_TOKENS = process.env.NUMBER_OF_TOKENS;
const MAGICLANE_SPOKE_DATA_FILE_PATH = process.env.MAGICLANE_SPOKE_DATA_FILE_PATH;
const MAGICLANE_MOCK_APP_DATA_FILE_PATH = process.env.MAGICLANE_MOCK_APP_DATA_FILE_PATH;

// Instantiating providers and walelts
const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = ethers.Wallet.fromPhrase(MNEMONICS, provider);

// Fetching abis
const magiclaneMockAppFactoryData = require('../out/MagiclaneMockApp.sol/MagiclaneMockApp.json');
const testFungibleTokenFactoryData = require('../out/TestFT.sol/TestFT.json');
const testNonFungibleTokenFactoryData = require('../out/TestNFT.sol/TestNFT.json');
const testSemiFungibleTokenFactoryData = require('../out/TestSFT.sol/TestSFT.json');

// Function for deploying magiclane mock app
const deployMagiclaneMockApp = async () => {
  try {
    // Print statement to indicate beginning of script
    console.log("\n=== Magiclane Mock App EVM Deployments on %s ===\n", CHAIN_NAME);

    // Read magiclane data on spoke chain
    let magiclaneSpokeData = await readData(MAGICLANE_SPOKE_DATA_FILE_PATH);

    // Read expected magiclane mock app data
    let expectedMagiclaneMockAppData = await readExpectedMagiclaneMockAppData(MAGICLANE_MOCK_APP_DATA_FILE_PATH);

    // Get or deploy magiclane mock app
    let magiclaneMockApp = await useOrDeployMagiclaneMockApp(expectedMagiclaneMockAppData.magiclaneMockApp, magiclaneSpokeData.magiclaneSpoke);

    // Create magiclane mock app data map
    let magiclaneMockAppData = {
        "magiclaneMockApp": magiclaneMockApp
    };
    
    // Create test tokens
    for (let i = 0; i < NUMBER_OF_TOKENS; i++) {
        // Set mint amounts and mint receipient
        let mintAmount = 100_000_000;
        let mintReceipient = wallet.address;

        // Creating test fungible tokens
        let ftName = "testFT_".concat(i);
        magiclaneMockAppData[ftName] = await useOrDeployTestFungibleToken(expectedMagiclaneMockAppData[ftName], ftName, mintReceipient, mintAmount);

        // Creating test non fungible tokens
        let nftName = "testNFT_".concat(i);
        magiclaneMockAppData[nftName] = await useOrDeployTestNonFungibleToken(expectedMagiclaneMockAppData[nftName], nftName, mintReceipient, i);

        // Creating test semi fungible tokens
        let sftName = "testSFT_".concat(i);
        magiclaneMockAppData[sftName] = await useOrDeployTestSemiFungibleToken(expectedMagiclaneMockAppData[sftName], sftName, mintReceipient, i, mintAmount)
    }
    
    // Save magiclane mock app data
    fs.writeFileSync(MAGICLANE_MOCK_APP_DATA_FILE_PATH, JSON.stringify(magiclaneMockAppData, null, '\t'));

    // Print statement to indicate the end of script
    console.log('\x1b[32m%s\x1b[0m', "Script ran successfully\n");
  } catch (error) {
    console.log({ error });
  }
}

/**
* Function for fetching already deployed magiclane mock app or deploying it if it does not exist
* @param {string} expectedMagiclaneMockApp - 20 byte string representing the expected magiclane mock App
* @param {string} magiclaneSpokeAddress - 20 byte string representing the magiclane spoke address
* @returns {string} magiclaneMockAppAddress - 20 byte string representing the deployed magiclane mock app address
*/
async function useOrDeployMagiclaneMockApp(expectedMagiclaneMockApp, magiclaneSpokeAddress) {
    let magiclaneMockAppAddress;

    // Check if the expected magiclane mock app exists
    let expectedMagiclaneMockAppCode = await provider.getCode(expectedMagiclaneMockApp);

    // Check if the magiclane spoke exists
    let magiclaneSpokeCode = await provider.getCode(magiclaneSpokeAddress);

    // If not, deploy magiclane mock app
    if ((expectedMagiclaneMockAppCode == '0x') && (magiclaneSpokeCode != '0x')) {
        const magiclaneMockAppFactory = new ethers.ContractFactory(magiclaneMockAppFactoryData.abi, magiclaneMockAppFactoryData.bytecode, wallet);
        const magiclaneMockAppContract = await magiclaneMockAppFactory.deploy(magiclaneSpokeAddress);
        await magiclaneMockAppContract.waitForDeployment();

        magiclaneMockAppAddress = await magiclaneMockAppContract.getAddress();
        console.log("MagiclaneMockApp deployed on %s at %s", CHAIN_NAME, magiclaneMockAppAddress);
    } else {
        magiclaneMockAppAddress = expectedMagiclaneMockApp;
        console.log("MagiclaneMockApp already deployed on %s at %s", CHAIN_NAME, magiclaneMockAppAddress);
    }

    // return
    return magiclaneMockAppAddress;
}

/**
* Function for fetching already deployed test fungible token or deploying it if it does not exist
* @param {string} expectedTestFungibleTokenAddress - 20 byte string representing the expected test fungible token address
* @param {string} testFungibleTokenName - 20 byte string representing the test fungible token name
* @param {string} mintReceipient - 20 byte string representing the address we are minting to
* @param {number} mintAmount - number representing the amount of the token we are minting to the receipient
* @returns {string} testFungibleTokenAddress - 20 byte string representing the deployed test fungible token address
*/
async function useOrDeployTestFungibleToken(expectedTestFungibleTokenAddress, testFungibleTokenName, mintReceipient, mintAmount) {
    let testFungibleTokenAddress;

    // Check if the expected address is undefined and if it is, replace it so things dont break
    if (typeof expectedTestFungibleTokenAddress == 'undefined') {
        expectedTestFungibleTokenAddress = ethers.ZeroAddress;
    }

    // Check if the expected test fungible token exists
    let expectedTestFungibleTokenCode = await provider.getCode(expectedTestFungibleTokenAddress);

    // If not, deploy test fungible token
    if (expectedTestFungibleTokenCode == '0x') {
        const testFungibleTokenFactory = new ethers.ContractFactory(testFungibleTokenFactoryData.abi, testFungibleTokenFactoryData.bytecode, wallet);
        const testFungibleTokenContract = await testFungibleTokenFactory.deploy(testFungibleTokenName, testFungibleTokenName);
        await testFungibleTokenContract.waitForDeployment();

        // Mint tokens to mint receipient
        let mintTx = await testFungibleTokenContract.mint(mintReceipient, mintAmount);
        await mintTx.wait();

        testFungibleTokenAddress = await testFungibleTokenContract.getAddress();
        console.log("%s deployed on %s at %s", testFungibleTokenName, CHAIN_NAME, testFungibleTokenAddress);
    } else {
        testFungibleTokenAddress = expectedTestFungibleTokenAddress;
        console.log("%s already found on %s at %s", testFungibleTokenName, CHAIN_NAME, testFungibleTokenAddress);
    }

    // return
    return testFungibleTokenAddress;
}

/**
* Function for fetching already deployed test non fungible token or deploying it if it does not exist
* @param {string} expectedTestNonFungibleTokenAddress - 20 byte string representing the expected test non fungible token address
* @param {string} testNonFungibleTokenName - 20 byte string representing the test non fungible token name
* @param {string} mintReceipient - 20 byte string representing the address we are minting to
* @param {number} mintIndex - number representing the index of the token we are minting to the receipient
* @returns {string} testNonFungibleTokenAddress - 20 byte string representing the deployed test fungible token address
*/
async function useOrDeployTestNonFungibleToken(expectedTestNonFungibleTokenAddress, testNonFungibleTokenName, mintReceipient, mintIndex) {
    let testNonFungibleTokenAddress;

    // Check if the expected address is undefined and if it is, replace it so things dont break
    if (typeof expectedTestNonFungibleTokenAddress == 'undefined') {
        expectedTestNonFungibleTokenAddress = ethers.ZeroAddress;
    }

    // Check if the expected test fungible token exists
    let expectedTestNonFungibleTokenCode = await provider.getCode(expectedTestNonFungibleTokenAddress);

    // If not, deploy test fungible token
    if (expectedTestNonFungibleTokenCode == '0x') {
        const testNonFungibleTokenFactory = new ethers.ContractFactory(testNonFungibleTokenFactoryData.abi, testNonFungibleTokenFactoryData.bytecode, wallet);
        const testNonFungibleTokenContract = await testNonFungibleTokenFactory.deploy(testNonFungibleTokenName, testNonFungibleTokenName);
        await testNonFungibleTokenContract.waitForDeployment();

        // Mint tokens to mint receipient
        let mintTx = await testNonFungibleTokenContract.mint(mintReceipient, mintIndex);
        await mintTx.wait();

        testNonFungibleTokenAddress = await testNonFungibleTokenContract.getAddress();
        console.log("%s deployed on %s at %s", testNonFungibleTokenName, CHAIN_NAME, testNonFungibleTokenAddress);
    } else {
        testNonFungibleTokenAddress = expectedTestNonFungibleTokenAddress;
        console.log("%s already found on %s at %s", testNonFungibleTokenName, CHAIN_NAME, testNonFungibleTokenAddress);
    }

    // return
    return testNonFungibleTokenAddress;
}

/**
* Function for fetching already deployed test semi fungible token or deploying it if it does not exist
* @param {string} expectedTestSemiFungibleTokenAddress - 20 byte string representing the expected test semis fungible token address
* @param {string} testSemiFungibleTokenName - 20 byte string representing the test semi fungible token name
* @param {string} mintReceipient - 20 byte string representing the address we are minting to
* @param {number} mintIndex - number representing the index of the token we are minting to the receipient
* @param {number} mintAmount - number representing the amount of the indexed token we are minting to the receipient
* @returns {string} testSemiFungibleTokenAddress - 20 byte string representing the deployed test semi fungible token address
*/
async function useOrDeployTestSemiFungibleToken(expectedTestSemiFungibleTokenAddress, testSemiFungibleTokenName, mintReceipient, mintIndex, mintAmount) {
    let testSemiFungibleTokenAddress;

    // Check if the expected address is undefined and if it is, replace it so things dont break
    if (typeof expectedTestSemiFungibleTokenAddress == 'undefined') {
        expectedTestSemiFungibleTokenAddress = ethers.ZeroAddress;
    }

    // Check if the expected test fungible token exists
    let expectedTestSemiFungibleTokenCode = await provider.getCode(expectedTestSemiFungibleTokenAddress);

    // If not, deploy test fungible token
    if (expectedTestSemiFungibleTokenCode == '0x') {
        const testSemiFungibleTokenFactory = new ethers.ContractFactory(testSemiFungibleTokenFactoryData.abi, testSemiFungibleTokenFactoryData.bytecode, wallet);
        const testSemiFungibleTokenContract = await testSemiFungibleTokenFactory.deploy();
        await testSemiFungibleTokenContract.waitForDeployment();

        // Mint tokens to mint receipient
        let mintTx = await testSemiFungibleTokenContract.mint(mintReceipient, mintIndex, mintAmount);
        await mintTx.wait();

        testSemiFungibleTokenAddress = await testSemiFungibleTokenContract.getAddress();
        console.log("%s deployed on %s at %s", testSemiFungibleTokenName, CHAIN_NAME, testSemiFungibleTokenAddress);
    } else {
        testSemiFungibleTokenAddress = expectedTestSemiFungibleTokenAddress;
        console.log("%s already found on %s at %s", testSemiFungibleTokenName, CHAIN_NAME, testSemiFungibleTokenAddress);
    }

    // return
    return testSemiFungibleTokenAddress;
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
        throw(err)
      }
}

/**
 * Function for reading expected magiclane mock App data from a file.
 * @param {string} file_path - string representing the path for the file holding the expected magiclane mock app data
 * @returns {Map<String, String>} - map containing all the expected magiclane mock app data
 */
async function readExpectedMagiclaneMockAppData(file_path) {
    try {
        data = fs.readFileSync(file_path);
        return JSON.parse(data);
      } catch (err) {
        return {
            "magiclaneMockApp": ethers.ZeroAddress,
        };
      }
}

deployMagiclaneMockApp();