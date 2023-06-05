############################################################# SETTING ENVIRONMENT VARIABLES ################################################################

# Uncomment for local_testnet
# export ENVIRONMENT="Local_Testnet"

# Uncomment for public testnet
export ENVIRONMENT="Public_Testnet"

# Uncomment for mainnet
# export ENVIRONMENT="Production"

############################################################# SETTING SEARCH DIRECTORY ####################################################################
if [ "$ENVIRONMENT" == "Production" ]
then
    search_directory=environmentVariables/production
    export ADDRESS_FOLDER=mainnet
    export SENDING_MNEMONICS=$(op read "op://Security/MockThunderbirdApp/Sending_mnemonic_phrase")
    export SENDING_KEY_INDEX=0

elif [ "$ENVIRONMENT" == "Public_Testnet" ]
then
    search_directory=environmentVariables/publicTestnet
    export ADDRESS_FOLDER=public_testnet
    export SENDING_MNEMONICS="<ADD YOUR MNEMONIC HERE>"
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

    destinationChainConfigsPath="$search_directory/""$destinationChain"".sh" 
    destination_mock_thunderbird_app_address_path="deploymentScripts/mockThunderbirdApp/addresses/"$ADDRESS_FOLDER"/""$destinationChain"".txt"
    . "$destinationChainConfigsPath"

    if [ -f "$destination_mock_thunderbird_app_address_path" ]
    then
        destination_mock_thunderbird_app_address=$(<$destination_mock_thunderbird_app_address_path)
        export RECEIVER_ADDRESS=$destination_mock_thunderbird_app_address
        export MESSAGE_STRING=$NEWMESSAGE
        export RECEIVER_CHAIN_ID=$CHAIN_ID
    fi

    sourceChainConfigsPath="$search_directory/""$sourceChain"".sh" 
    source_mock_thunderbird_app_address_path="deploymentScripts/mockThunderbirdApp/addresses/"$ADDRESS_FOLDER"/""$sourceChain"".txt"
    . "$sourceChainConfigsPath"

    if [ -f "$source_mock_thunderbird_app_address_path" ]
    then
        source_mock_thunderbird_app_address=$(<$source_mock_thunderbird_app_address_path)
        export MOCK_THUNDERBIRD_APP_ADDRESS=$source_mock_thunderbird_app_address
    fi

    echo $MESSAGE_STRING
    echo $RECEIVER_ADDRESS
    echo $RECEIVER_CHAIN_ID
    echo $MOCK_THUNDERBIRD_APP_ADDRESS
    echo $RPC_URL

    forge script deploymentScripts/mockThunderbirdApp/mockThunderbirdApp.s.sol:MockThunderbirdAppSendMessage --rpc-url $RPC_URL --broadcast
    echo "\n"
done