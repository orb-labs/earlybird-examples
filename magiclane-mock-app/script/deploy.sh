############################################### SETTING ENVIRONMENT VARIABLES ##############################################

# set env vars if unset
### default environment
: ${ENVIRONMENT:="local"}

case $ENVIRONMENT in
    prod)
        : ${MNEMONICS:=`gcloud secrets versions access latest --secret=activity-runner-mnemonics`}
        ;;
    dev)
        : ${MNEMONICS:=`gcloud secrets versions access latest --secret=activity-runner-mnemonics`}
        ;;
    local)
        : ${MNEMONICS:="test test test test test test test test test test test junk"}
        : ${NUMBER_OF_TOKENS:="3"}
        ;;
    *)
        echo "invalid environment" && exit 1
        ;;
esac

### other env vars
: ${CHAINS_DIRECTORY:="environmentVariables/${ENVIRONMENT}"}
: ${KEY_INDEX:="0"}
: ${SENDING_MNEMONICS:=$MNEMONICS}
: ${SENDING_KEY_INDEX:=$KEY_INDEX}

# export env vars needed by the Solidity scripts
export ENVIRONMENT KEY_INDEX MNEMONICS SENDING_MNEMONICS SENDING_KEY_INDEX NUMBER_OF_TOKENS

############################################## HELPER FUNCTIONS ############################################################

### get address from path arg or use placeholder
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

############################################################################################################################
if [[ -z $CHAINS_DIRECTORY || -z $ENVIRONMENT || -z $KEY_INDEX || -z $MNEMONICS  ]]; then echo "env vars unset" && exit 1;fi

# the deploy will run for each file in the chains directory, 
# all of which should be shell scripts that set env vars specific to the chain
# the filename should be the chain name
for entry in "$CHAINS_DIRECTORY"/*
do
    . "$entry"

    address_dir="../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}""
    if [[ ! -d $address_dir ]]; then mkdir $address_dir; fi

    ########################################## GET EXISTING ADDRESSES ######################################################
    address_dir="../addresses/${ENVIRONMENT}/${CHAIN_NAME}"
    export EXPECTED_MAGICLANE_MOCK_APP_ADDRESS=`address_from_filepath "${address_dir}/magiclaneMockApp.txt"`

    ft_address_dir_path="${address_dir}/TestFTs"
    nft_address_dir_path="${address_dir}/TestNFTs"
    sft_address_dir_path="${address_dir}/TestSFTs"

    # create directories if they don't exist
    if [ ! -d "$ft_address_dir_path" ]; then mkdir $ft_address_dir_path; fi
    if [ ! -d "$nft_address_dir_path" ]; then mkdir $nft_address_dir_path; fi
    if [ ! -d "$sft_address_dir_path" ]; then mkdir $sft_address_dir_path; fi

    limit=$NUMBER_OF_TOKENS
    i=0; while [ $i -le $limit ]; do
        export EXPECTED_TEST_FT_ADDRESSES_$i=`address_from_filepath "$ft_address_dir_path/testFT-$i.txt"`
        export EXPECTED_TEST_NFT_ADDRESSES_$i=`address_from_filepath "$nft_address_dir_path/testNFT-$i.txt"`
        export EXPECTED_TEST_SFT_ADDRESSES_$i=`address_from_filepath "$sft_address_dir_path/testSFT-$i.txt"`
        i=$((i + 1))
    done
    
    ########################################## DEPLOY ######################################################################
    export MAGICLANE_SPOKE_ENDPOINT_ADDRESS=$(<../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/magiclane-evm/spokeEndpoint.txt) || exit 1
    
    forge script --legacy deploymentScripts/MagiclaneMockApp.s.sol:MagiclaneMockAppDeployment --rpc-url $RPC_URL --broadcast
    forge script --legacy deploymentScripts/TestFT.s.sol:TestFTDeployment --rpc-url $RPC_URL --broadcast
    forge script --legacy deploymentScripts/TestNFT.s.sol:TestNFTDeployment --rpc-url $RPC_URL --broadcast
    forge script --legacy deploymentScripts/TestSFT.s.sol:TestSFTDeployment --rpc-url $RPC_URL --broadcast

    export MAGICLANE_MOCK_APP_ADDRESS=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/magiclaneMockApp.txt"`
    
    i=0; while [ $i -le $limit ]; do
        export TEST_FT_ADDRESSES_$i=`address_from_filepath "$ft_address_dir_path/testFT-$i.txt"`
        export TEST_NFT_ADDRESSES_$i=`address_from_filepath "$nft_address_dir_path/testNFT-$i.txt"`
        export TEST_SFT_ADDRESSES_$i=`address_from_filepath "$sft_address_dir_path/testSFT-$i.txt"`
        i=$((i + 1))
    done
    
    echo "deployed magiclane mock app and tokens on $CHAIN_NAME"
    echo "magiclane mock app = ${MAGICLANE_MOCK_APP_ADDRESS}"
    i=0; while [ $i -le $limit ]; do
        eval echo "TestFT_$i = \${TEST_FT_ADDRESSES_${i}}"
        i=$((i + 1))
    done
    echo
    i=0; while [ $i -le $limit ]; do
        eval echo "TestNFT_$i = \${TEST_NFT_ADDRESSES_$i}"
        i=$((i + 1))
    done
    echo
    i=0; while [ $i -le $limit ]; do
        eval echo "TestSFT_$i = \${TEST_SFT_ADDRESSES_$i}"
        i=$((i + 1))
    done
done
