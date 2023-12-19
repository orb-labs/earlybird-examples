############################################################# SETTING ENVIRONMENT VARIABLES ################################################################

# set env vars if unset
### default environment
: ${ENVIRONMENT:="local"}

case $ENVIRONMENT in
    mainnet)
        : ${SENDING_KEY_INDEX:="0"}
        : ${MNEMONICS:=`gcloud secrets versions access latest --secret=activity-runner-mnemonics`}
        ;;
    testnet)
        : ${SENDING_KEY_INDEX:="0"}
        : ${MNEMONICS:=`gcloud secrets versions access latest --secret=activity-runner-mnemonics`}
        ;;
    local)
        : ${SENDING_KEY_INDEX:="0"}
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

### other env vars
: ${CHAINS_DIRECTORY:="environmentVariables/${ENVIRONMENT}"}

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

    echo "\n"
    echo "Enter the number of fungible tokens you will like to send:"
    select NEW_NUMBER_OF_FTS in {1..10}; do
        [[ -n $NEW_NUMBER_OF_FTS ]] || { echo "Invalid chain. Please try again." >&2; continue; }
        break # valid choice was made; exit prompt.
    done

    echo "\n"
    echo "Enter the number of nonfungible tokens you will like to send:"
     select NEW_NUMBER_OF_NFTS in {0..10}; do
        [[ $NEW_NUMBER_OF_NFTS -ge 0 && $NEW_NUMBER_OF_NFTS -le 9 ]] || { echo "Invalid chain. Please try again." >&2; continue; }
        break # valid choice was made; exit prompt.
    done

    echo "\n"
    echo "Enter the number of semifungible tokens you will like to send:"
     select NEW_NUMBER_OF_SFTS in {0..10}; do
        [[ $NEW_NUMBER_OF_NFTS -ge 0 && $NEW_NUMBER_OF_NFTS -le 9 ]] || { echo "Invalid chain. Please try again." >&2; continue; }
        break # valid choice was made; exit prompt.
    done

    destinationChainConfigsPath="$CHAINS_DIRECTORY/"$destinationChain".sh" 
    destination_magiclane_mock_app_address_path="../addresses/"${ENVIRONMENT}"/"$destinationChain"/magiclaneMockApp.txt"
    . ${destinationChainConfigsPath}

    if [ -f "$destination_magiclane_mock_app_address_path" ]
    then
        destination_magiclane_mock_app_address=$(<$destination_magiclane_mock_app_address_path)
        export RECEIVER_MAGICLANE_MOCK_APP_ADDRESS=$destination_magiclane_mock_app_address
        export RECEIVER_MAGICLANE_SPOKE_ID=$(<../addresses/"$ENVIRONMENT"/"$destinationChain"/magiclane-evm/spokeId.txt)
    else
        echo "$ENVIRONMENT destination mock thunderbird app address not found at $destination_magiclane_mock_app_address_path" && exit 10
    fi

    sourceChainConfigsPath="$CHAINS_DIRECTORY/""$sourceChain"".sh" 
    source_magiclane_mock_app_address_path="../addresses/"${ENVIRONMENT}"/"$sourceChain"/magiclaneMockApp.txt"

    sourceChainConfigsPath="$CHAINS_DIRECTORY/""$sourceChain"".sh" 
    source_magiclane_mock_app_address_path="../addresses/"${ENVIRONMENT}"/"$sourceChain"/magiclaneMockApp.txt"
    . "$sourceChainConfigsPath"

    export MAGICLANE_SPOKE_ENDPOINT_ADDRESS=$(<../addresses/"$ENVIRONMENT"/"$sourceChain"/magiclane-evm/spokeEndpoint.txt)
    export MESSAGE_STRING=$NEWMESSAGE
    export NUMBER_OF_FTS=$NEW_NUMBER_OF_FTS
    export NUMBER_OF_NFTS=$NEW_NUMBER_OF_NFTS
    export NUMBER_OF_SFTS=$NEW_NUMBER_OF_SFTS

    for i in $(seq 0 $NEW_NUMBER_OF_FTS)
    do
        export TEST_FT_ADDRESSES_$i=$(<../addresses/"$ENVIRONMENT"/"$sourceChain"/TestFTs/TestFT-"$i".txt)
    done

    for i in $(seq 0 $NEW_NUMBER_OF_NFTS)
    do
        export TEST_NFT_ADDRESSES_$i=$(<../addresses/"$ENVIRONMENT"/"$sourceChain"/TestNFTs/TestNFT-"$i".txt)
    done

    for i in $(seq 0 $NEW_NUMBER_OF_SFTS)
    do
        export TEST_SFT_ADDRESSES_$i=$(<../addresses/"$ENVIRONMENT"/"$sourceChain"/TestSFTs/TestSFT-"$i".txt)
    done

    forge script --legacy deploymentScripts/MagiclaneMockApp.s.sol:MagiclaneMockAppSendTokens --rpc-url $RPC_URL --broadcast
    echo "\n"
done