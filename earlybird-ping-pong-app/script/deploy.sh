if [[ -z $DEPLOYMENT_CONFIGS_DIRECTORY || -z $DEPLOYMENT_ADDRESSES_DIRECTORY || -z $MNEMONICS || -z $KEY_INDEX ]]; then echo "env vars unset" && exit 1; fi

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

    # deploy the earlybird mock app
    node deploymentScript.js
done

# create earlybird examples abi directory
earlybird_examples_abi_directory="$CONTRACT_ABI_DIRECTORY/earlybird-examples-abi"
if [[ ! -d $earlybird_examples_abi_directory ]]; then mkdir $earlybird_examples_abi_directory; fi

# create earlybird ping pong app abi directory
earlybird_ping_pong_app_abi_directory="$CONTRACT_ABI_DIRECTORY/earlybird-examples-abi/earlybird-ping-pong-app-abi"
if [[ ! -d $earlybird_ping_pong_app_abi_directory ]]; then mkdir $earlybird_ping_pong_app_abi_directory; fi

# copy out file to earlybird ping pong app abi directory
cp -R ../out/. $earlybird_ping_pong_app_abi_directory