############################################################# SETTING ENVIRONMENT VARIABLES ################################################################

# Uncomment for local chains
export ENVIRONMENT=${ENVIRONMENT:-local}

# Uncomment for public testnet
# export ENVIRONMENT="testnet"

# Uncomment for mainnet
# export ENVIRONMENT="mainnet"

chains_directory="environmentVariables/$ENVIRONMENT"

export MNEMONICS="test test test test test test test test test test test junk"
export SENDING_KEY_INDEX=5

if [ "$ENVIRONMENT" != "local" ]
then
    export MNEMONICS=$(op read "op://Private/Deployment/Mnemonic_phrase/"$ENVIRONMENT"")
    export SENDING_KEY_INDEX=0
    export SENDING_MNEMONICS=$(op read "op://Security/MockRukhApp/Sending_mnemonic_phrase")
fi

############################################## HELPER FUNCTIONS ############################################################

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

############################################## SENDING MESSAGE TO MOCK APP ############################################################
i=0
for entry in "$chains_directory"/*
do
    . "$entry"
    chains[$i]=$CHAIN_NAME
    ((i++))
done

echo "\n"
while true; do
    echo "Please select the source chain you will like to send this message from:"
    select sourceChain in "${chains[@]}"; do
        [[ -n $sourceChain ]] || { echo "Invalid chain. Please try again." >&2; continue; }
        break # valid choice was made; exit prompt.
    done

    echo "\n"
    echo "Please select the destination chain you will like to send this message to:"
    select destinationChain in "${chains[@]}"; do
        [[ -n $destinationChain ]] || { echo "Invalid chain. Please try again." >&2; continue; }
        break # valid choice was made; exit prompt.
    done

    echo "\n"
    echo "Enter message you will like to send:"
    read NEWMESSAGE

    destinationChainConfigsPath="$chains_directory/"$destinationChain".sh" 
    destination_mock_rukh_app_address_path="../addresses/"$ENVIRONMENT"/"$destinationChain"/rukh/app.txt"
    . "$destinationChainConfigsPath"

    if [ -f "$destination_mock_rukh_app_address_path" ]
    then
        destination_mock_rukh_app_address=$(<$destination_mock_rukh_app_address_path)
        export RECEIVER_ADDRESS=$destination_mock_rukh_app_address
        export MESSAGE_STRING=$NEWMESSAGE
        export RECEIVER_CHAIN_ID=$CHAIN_ID
    fi

    sourceChainConfigsPath="$search_directory/"$sourceChain".sh" 
    source_mock_rukh_app_address_path="../addresses/"$ENVIRONMENT"/"$sourceChain"/rukh/app.txt"
    . "$sourceChainConfigsPath"

    export MOCK_RUKH_APP_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/app.txt"`

    echo $MESSAGE_STRING
    echo $RECEIVER_ADDRESS
    echo $RECEIVER_CHAIN_ID
    echo $MOCK_RUKH_APP_ADDRESS
    echo $RPC_URL

    forge script deploymentScripts/rukh/mockRukhApp.s.sol:MockRukhAppSendMessage --rpc-url $RPC_URL --broadcast
    echo "\n"
done