############################################################# SETTING ENVIRONMENT VARIABLES ################################################################

# Uncomment for local chains
export ENVIRONMENT=${ENVIRONMENT:-local}

# Uncomment for public testnet
# export ENVIRONMENT="testnet"

# Uncomment for mainnet
# export ENVIRONMENT="mainnet"

chains_directory="environmentVariables/$ENVIRONMENT"

export MNEMONICS="test test test test test test test test test test test junk"

if [ "$ENVIRONMENT" != "local" ]
then
    export MNEMONICS=$(op read "op://Private/Deployment/Mnemonic_phrase/"$ENVIRONMENT"")
    export KEY_INDEX=0
fi

############################################## Helper Functions ############################################################

address_from_filepath() {
    existing_address_path=$1
    if [ -f $existing_address_path ]
    then
        address=$(<$existing_address_path)
    else
        address="0x0000000000000000000000000000000000000000"
    fi
    echo $address
}

############################################## GETTING ALL MESSAGES SENT TO MOCK APP #######################################

for entry in "$chains_directory"/*
do
    . "$entry"
    export MOCK_THUNDERBIRD_APP_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/thunderbird/app.txt"`
    forge script deploymentScripts/thunderbird/mockThunderbirdApp.s.sol:MockThunderbirdAppGetAllMessages --rpc-url $RPC_URL --broadcast
done