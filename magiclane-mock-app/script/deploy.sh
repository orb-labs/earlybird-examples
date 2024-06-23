if [[ -z $DEPLOYMENT_CONFIGS_DIRECTORY || -z $DEPLOYMENT_ADDRESSES_DIRECTORY || -z $MNEMONICS || -z $KEY_INDEX ]]; then echo "env vars unset" && exit 1; fi

export NUMBER_OF_TOKENS=3;

# additional addresses for minting tokens for the solver and activity runner
export ADDITIONAL_MINT_ADDRESSES_RECIPIENTS="0x15d34aaf54267db7d7c367839aaf71a00a2c6a65,0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266";

# build and compile contracts
forge build

# the deploy will run for each file in the chains directory, 
# all of which should be shell scripts that set env vars specific to the chain
# the filename should be the chain name
for entry in "$DEPLOYMENT_CONFIGS_DIRECTORY/chains/activeChains"/*
do
    # run script to set env vars for the chain
    . "$entry"

    # fetch deployment addresses for the chain
    export DEPLOYMENT_ADDRESSES_FILE_PATH="$DEPLOYMENT_ADDRESSES_DIRECTORY/${CHAIN_NAME}.json"

    # deploy the magiclane mock app
    node deploymentScript.js
done

# create earlybird examples abi directory
earlybird_examples_abi_directory="$CONTRACT_ABI_DIRECTORY/earlybird-examples-abi"
if [[ ! -d $earlybird_examples_abi_directory ]]; then mkdir $earlybird_examples_abi_directory; fi

# create magiclane mock app abi directory
magiclane_mock_app_abi_directory="$CONTRACT_ABI_DIRECTORY/earlybird-examples-abi/magiclane-mock-app-abi"
if [[ ! -d $magiclane_mock_app_abi_directory ]]; then mkdir $magiclane_mock_app_abi_directory; fi

# copy out file to magiclane mock app abi directory
cp -R ../out/. $magiclane_mock_app_abi_directory
