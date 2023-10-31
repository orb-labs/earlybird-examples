############################################################# SETTING ENVIRONMENT VARIABLES ################################################################
if [ "$ENVIRONMENT" != "local" ]
then
    export SENDING_KEY_INDEX=0
    export MNEMONICS=`gcloud secrets versions access latest --secret=activity-runner-mnemonics`
fi

### set env vars if unset
: "${ENVIRONMENT:=local}" 
: "${CHAINS_DIRECTORY:=environmentVariables/$ENVIRONMENT}"
: "${KEY_INDEX:=0}"
: "${MNEMONICS:=test test test test test test test test test test test junk}"
: "${SENDING_MNEMONICS:=$MNEMONICS}"
: "${SENDING_KEY_INDEX:=5}"


export ENVIRONMENT KEY_INDEX MNEMONICS SENDING_MNEMONICS SENDING_KEY_INDEX

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
for entry in "$CHAINS_DIRECTORY"/*
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

    destinationChainConfigsPath="$CHAINS_DIRECTORY/"$destinationChain".sh" 
    destination_mock_rukh_app_address_path="../addresses/"$ENVIRONMENT"/"$destinationChain"/rukh/app.txt"
    . "$destinationChainConfigsPath"

    if [ -f "$destination_mock_rukh_app_address_path" ]
    then
        destination_mock_rukh_app_address=$(<$destination_mock_rukh_app_address_path)
        export RECEIVER_ADDRESS=$destination_mock_rukh_app_address
        export MESSAGE_STRING=$NEWMESSAGE
        export RECEIVER_CHAIN_ID=$CHAIN_ID
        export RECEIVER_EARLYBIRD_INSTANCE_ID=$(<"../addresses/"$ENVIRONMENT"/"$destinationChain"/earlybrird-evm/instanceId.txt")
    fi

    sourceChainConfigsPath="$CHAINS_DIRECTORY/""$sourceChain"".sh" 
    source_mock_rukh_app_address_path="../addresses/"$ENVIRONMENT"/"$sourceChain"/app.txt"
    . "$sourceChainConfigsPath"

    export MOCK_RUKH_APP_ADDRESS=$(<"../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/app.txt")

    forge script deploymentScripts/rukh/mockRukhApp.s.sol:MockRukhAppSendMessage --rpc-url $RPC_URL --broadcast
    echo "\n"
done