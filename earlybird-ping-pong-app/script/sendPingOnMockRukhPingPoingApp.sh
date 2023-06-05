############################################################# SETTING ENVIRONMENT VARIABLES ################################################################

# Uncomment for local_testnet
export ENVIRONMENT="Local_Testnet"
export MNEMONICS="<ADD YOUR MNEMONIC HERE>"

# Uncomment for public testnet
# export ENVIRONMENT="Public_Testnet"

# Uncomment for mainnet
# export ENVIRONMENT="Production"

############################################################# SETTING SEARCH DIRECTORY ####################################################################
if [ "$ENVIRONMENT" == "Production" ]
then
    search_directory=environmentVariables/production
    export ADDRESS_FOLDER=mainnet
    export SENDING_MNEMONICS=$(op read "op://Security/MockRukhPingPongApp/Sending_mnemonic_phrase")
    export SENDING_KEY_INDEX=0

elif [ "$ENVIRONMENT" == "Public_Testnet" ]
then
    search_directory=environmentVariables/publicTestnet
    export ADDRESS_FOLDER=public_testnet
    export SENDING_MNEMONICS=$(op read "op://Security/MockRukhPingPongApp/Sending_mnemonic_phrase")
    export SENDING_KEY_INDEX=0

elif [ "$ENVIRONMENT" == "Local_Testnet" ]
then
    search_directory=environmentVariables/localTestnet
    export ADDRESS_FOLDER=local_testnet
    export SENDING_MNEMONICS=$MNEMONICS
    export SENDING_KEY_INDEX=5
fi

############################################## SENDING MESSAGE TO MOCK APP ############################################################
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

    destinationChainConfigsPath="$search_directory/""$destinationChain"".sh" 
    destination_mock_rukh_ping_pong_app_address_path="deploymentScripts/RukhVersion/addresses/"$ADDRESS_FOLDER"/""$destinationChain""/app.txt"
    . "$destinationChainConfigsPath"

    if [ -f "$destination_mock_rukh_ping_pong_app_address_path" ]
    then
        destination_mock_rukh_ping_pong_app_address=$(<$destination_mock_rukh_ping_pong_app_address_path)
        export RECEIVER_ADDRESS=$destination_mock_rukh_ping_pong_app_address
        export PINGS=$PINGS
        export RECEIVER_CHAIN_ID=$CHAIN_ID
    fi

    sourceChainConfigsPath="$search_directory/""$sourceChain"".sh" 
    source_mock_rukh_ping_pong_app_address_path="deploymentScripts/RukhVersion/addresses/"$ADDRESS_FOLDER"/""$sourceChain""/app.txt"
    . "$sourceChainConfigsPath"

    if [ -f "$source_mock_rukh_ping_pong_app_address_path" ]
    then
        source_mock_rukh_ping_pong_app_address=$(<$source_mock_rukh_ping_pong_app_address_path)
        export MOCK_RUKH_PING_PONG_APP_ADDRESS=$source_mock_rukh_ping_pong_app_address
    fi

    echo $PINGS
    echo $RECEIVER_ADDRESS
    echo $RECEIVER_CHAIN_ID
    echo $MOCK_RUKH_PING_PONG_APP_ADDRESS
    echo $RPC_URL

    forge script deploymentScripts/RukhVersion/PingPongRukh.s.sol:MockRukhPingPongAppSendPing --rpc-url $RPC_URL --broadcast
    echo "\n"
done