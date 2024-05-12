if [[ -z $DEPLOYMENT_CONFIGS_DIRECTORY || -z $KEY_INDEX || -z $MNEMONICS ]]; then echo "env vars unset" && exit 1; fi

# create deployment addresses directory
if [[ ! -d $DEPLOYMENT_ADDRESSES_DIRECTORY ]]; then mkdir $DEPLOYMENT_ADDRESSES_DIRECTORY; fi

# the deploy will run for each file in the chains directory, 
# all of which should be shell scripts that set env vars specific to the chain
# the filename should be the chain name
for entry in "$DEPLOYMENT_CONFIGS_DIRECTORY/activeChains"/*
do
    # run script to set env vars for the chain
    . "$entry"

    # create deployment directory for chain
    deployment_addresses_dir_for_chain="$DEPLOYMENT_ADDRESSES_DIRECTORY/${CHAIN_NAME}"
    if [[ ! -d $deployment_addresses_dir_for_chain ]]; then mkdir $deployment_addresses_dir_for_chain; fi
    
    # fetch file paths
    export EARLYBIRD_DATA_FILE_PATH="$deployment_addresses_dir_for_chain/earlybirdData.txt"
    export EARLYBIRD_PERIPHERY_CONTRACTS_DATA_FILE_PATH="$deployment_addresses_dir_for_chain/earlybirdPeripheryContractsData.txt"
    export EARLYBIRD_MOCK_APP_DATA_FILE_PATH="$deployment_addresses_dir_for_chain/earlybirdMockAppData.txt"

    # build and compile contracts
    forge build

    # deploy the earlybird mock app
    node deploymentScript.js
done