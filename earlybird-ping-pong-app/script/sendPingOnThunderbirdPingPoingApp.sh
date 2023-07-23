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
    export MNEMONICS=$(op read "op://Security/MockThunderbirdPingPongApp/Sending_mnemonic_phrase")
    export SENDING_KEY_INDEX=0
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

############################################## SENDING MESSAGE TO APP ############################################################
i=0
for entry in "$search_directory"/*
do
    . "$entry"
    chains[$i]=$CHAIN_NAME
    ((i++))
done

echo "\n"
while true; do
    echo "Please select the source chain you will like to send this ping from:"
    select sourceChain in "${chains[@]}"; do
        [[ -n $sourceChain ]] || { echo "Invalid chain. Please try again." >&2; continue; }
        break # valid choice was made; exit prompt.
    done

    echo "\n"
    echo "Please select the destination chain you will like to send this ping to:"
    select destinationChain in "${chains[@]}"; do
        [[ -n $destinationChain ]] || { echo "Invalid chain. Please try again." >&2; continue; }
        break # valid choice was made; exit prompt.
    done

    echo "\n"
    echo "Enter the number of pings you will like to send:"
    read PINGS

    destinationChainConfigsPath="$search_directory/"$destinationChain".sh" 
    destination_thunderbird_ping_pong_app_address_path="../addresses/"$ENVIRONMENT"/"$destinationChain"/thunderbird/app.txt"
    . "$destinationChainConfigsPath"

    if [ -f "$destination_thunderbird_ping_pong_app_address_path" ]
    then
        destination_thunderbird_ping_pong_app_address=$(<$destination_thunderbird_ping_pong_app_address_path)
        export RECEIVER_ADDRESS=$destination_rukh_ping_pong_app_address
        export PINGS=$PINGS
        export RECEIVER_CHAIN_ID=$CHAIN_ID
    fi

    sourceChainConfigsPath="$search_directory/"$sourceChain".sh" 
    source_thunderbird_ping_pong_app_address_path="../addresses/"$ENVIRONMENT"/"$sourceChain"/app.txt"
    . "$sourceChainConfigsPath"

    export THUNDERBIRD_PING_PONG_APP_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/thunderbird/app.txt"`

    echo $PINGS
    echo $RECEIVER_ADDRESS
    echo $RECEIVER_CHAIN_ID
    echo $THUNDERBIRD_PING_PONG_APP_ADDRESS
    echo $RPC_URL

    forge script deploymentScripts/thunderbird/PingPong.s.sol:ThunderbirdPingPongAppSendPing --rpc-url $RPC_URL --broadcast
    echo "\n"
done