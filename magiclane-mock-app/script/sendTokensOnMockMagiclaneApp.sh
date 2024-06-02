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
    echo "Enter message you will like to send:"
    read NEWMESSAGE

    echo "\n"
    echo "Enter the number of fungible tokens you will like to send:"
    select NEW_NUMBER_OF_FTS in {1..3}; do
        [[ -n $NEW_NUMBER_OF_FTS ]] || { echo "Invalid chain. Please try again." >&2; continue; }
        break # valid choice was made; exit prompt.
    done

    echo "\n"
    echo "Enter the number of nonfungible tokens you will like to send:"
     select NEW_NUMBER_OF_NFTS in {0..3}; do
        [[ $NEW_NUMBER_OF_NFTS -ge 0 && $NEW_NUMBER_OF_NFTS -le 9 ]] || { echo "Invalid chain. Please try again." >&2; continue; }
        break # valid choice was made; exit prompt.
    done

    echo "\n"
    echo "Enter the number of semifungible tokens you will like to send:"
     select NEW_NUMBER_OF_SFTS in {0..3}; do
        [[ $NEW_NUMBER_OF_NFTS -ge 0 && $NEW_NUMBER_OF_NFTS -le 9 ]] || { echo "Invalid chain. Please try again." >&2; continue; }
        break # valid choice was made; exit prompt.
    done

    . "$DEPLOYMENT_CONFIGS_DIRECTORY/chains/activeChains/$sourceChain.sh"

    export SOURCE_CHAIN_FILE_PATH="`pwd`/../../../../deployment-addresses/${ENVIRONMENT}/${sourceChain}.json"
    export DESTINATION_CHAIN_FILE_PATH="`pwd`/../../../../deployment-addresses/${ENVIRONMENT}/${destinationChain}.json"
    export SOURCE_CHAIN=$sourceChain
    export DESTINATION_CHAIN=$destinationChain
    export MESSAGE_STRING=$NEWMESSAGE
    export NUMBER_OF_FTS=$NEW_NUMBER_OF_FTS
    export NUMBER_OF_NFTS=$NEW_NUMBER_OF_NFTS
    export NUMBER_OF_SFTS=$NEW_NUMBER_OF_SFTS

    # send message
    node magiclaneMockAppSendTokensScript.js
    echo "\n"
done