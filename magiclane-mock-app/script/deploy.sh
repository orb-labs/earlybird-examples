if [[ -z $DEPLOYMENT_CONFIGS_DIRECTORY || -z $MNEMONICS || -z $KEY_INDEX ]]; then echo "env vars unset" && exit 1; fi

export NUMBER_OF_TOKENS=3;

# build and compile contracts
forge build

# the deploy will run for each file in the chains directory, 
# all of which should be shell scripts that set env vars specific to the chain
# the filename should be the chain name
for entry in "$DEPLOYMENT_CONFIGS_DIRECTORY/chains/activeChains"/*
do
    # run script to set env vars for the chain
    . "$entry"

    # create deployment addresses directory for chain
    deployment_addresses_dir_for_chain="$DEPLOYMENT_ADDRESSES_DIRECTORY/${CHAIN_NAME}"

    # fetch file paths
    export MAGICLANE_MOCK_APP_DATA_FILE_PATH="$deployment_addresses_dir_for_chain/magiclaneMockApp.json"
    export MAGICLANE_SPOKE_DATA_FILE_PATH="$deployment_addresses_dir_for_chain/magiclaneSpokeData.json"

    # deploy the earlybird mock app
    node deploymentScript.js
done
