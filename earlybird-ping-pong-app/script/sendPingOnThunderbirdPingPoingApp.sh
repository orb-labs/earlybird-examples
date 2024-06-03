############################################################# SETTING ENVIRONMENT VARIABLES ################################################################

# set env vars if unset
### default environment
: ${ENVIRONMENT:="local"}

case $ENVIRONMENT in
    prod)
        : ${SENDING_KEY_INDEX:="0"}
        : ${MNEMONICS:=`gcloud secrets versions access latest --secret=activity-runner-mnemonics`}
        ;;
    dev)
        : ${SENDING_KEY_INDEX:="0"}
        : ${MNEMONICS:=`gcloud secrets versions access latest --secret=activity-runner-mnemonics`}
        ;;
    local)
        : ${SENDING_KEY_INDEX:="5"}
        : ${MNEMONICS:="test test test test test test test test test test test junk"}
        ;;
    *)
        echo "invalid environment" && exit 1
        ;;
esac
: ${KEY_INDEX:="0"}
: ${SENDING_MNEMONICS:="$MNEMONICS"}

# export env vars needed by the Solidity scripts
export ENVIRONMENT KEY_INDEX MNEMONICS SENDING_MNEMONICS SENDING_KEY_INDEX
export DEPLOYMENT_CONFIGS_DIRECTORY="`pwd`/../../../../deployment-configs/${ENVIRONMENT}"

############################################## SENDING MESSAGE TO APP ############################################################
i=0
for entry in "$DEPLOYMENT_CONFIGS_DIRECTORY/chains/activeChains"/*
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
    echo "Enter the number of pings you will like to send:"
    read PINGS

    . "$DEPLOYMENT_CONFIGS_DIRECTORY/chains/activeChains/$sourceChain.sh"

    export SOURCE_CHAIN_FILE_PATH="`pwd`/../../../../deployment-addresses/${ENVIRONMENT}/${sourceChain}.json"
    export DESTINATION_CHAIN_FILE_PATH="`pwd`/../../../../deployment-addresses/${ENVIRONMENT}/${destinationChain}.json"
    export SOURCE_CHAIN=$sourceChain
    export DESTINATION_CHAIN=$destinationChain
    export PINGS=$PINGS
    export LIBRARY="Thunderbird"

    # send message
    node sendPingOnMockApp.js
    echo "\n"
done