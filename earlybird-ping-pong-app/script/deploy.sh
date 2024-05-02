if [[ -z $GLOBAL_ADDRESSES_DIRECTORY || -z $CHAIN_CONFIGS_DIRECTORY || -z $ENVIRONMENT || -z $KEY_INDEX || -z $MNEMONICS ]]; then echo "env vars unset" && exit 1;fi

# create global address directory
if [[ ! -d $GLOBAL_ADDRESSES_DIRECTORY ]]; then mkdir $GLOBAL_ADDRESSES_DIRECTORY; fi

# create global address directory for environment
if [[ ! -d $GLOBAL_ADDRESSES_DIRECTORY_FOR_ENVIRONMENT ]]; then mkdir $GLOBAL_ADDRESSES_DIRECTORY_FOR_ENVIRONMENT; fi

# the deploy will run for each file in the chains directory, 
# all of which should be shell scripts that set env vars specific to the chain
# the filename should be the chain name
for entry in "$CHAIN_CONFIGS_DIRECTORY/activeChains"/*
do
    # run script in environmentVariables/ to set env vars for the chain
    . "$entry"

    # create global directory for chain
    global_address_dir_path_for_chain="$GLOBAL_ADDRESSES_DIRECTORY_FOR_ENVIRONMENT/${CHAIN_NAME}"
    if [[ ! -d $global_address_dir_path_for_chain ]]; then mkdir $global_address_dir_path_for_chain; fi
    
    # fetch file paths
    export EARLYBIRD_DATA_FILE_PATH="$global_address_dir_path_for_chain/earlybirdData.txt"
    export EARLYBIRD_PERIPHERY_CONTRACTS_DATA_FILE_PATH="$global_address_dir_path_for_chain/earlybirdPeripheryContractsData.txt"
    export EARLYBIRD_PING_PONG_APP_DATA_FILE_PATH="$global_address_dir_path_for_chain/earlybirdPingPongAppData.txt"

    # build and compile contracts
    forge build

    # deploy the earlybird mock app
    node deploymentScript.js
done