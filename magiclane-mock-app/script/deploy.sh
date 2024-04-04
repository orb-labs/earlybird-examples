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
export ENVIRONMENT KEY_INDEX MNEMONICS SENDING_MNEMONICS SENDING_KEY_INDEX

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

    export EXPECTED_TEST_FT_ADDRESSES_0=`address_from_filepath "$ft_address_dir_path/testFT-0.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_1=`address_from_filepath "$ft_address_dir_path/testFT-1.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_2=`address_from_filepath "$ft_address_dir_path/testFT-2.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_3=`address_from_filepath "$ft_address_dir_path/testFT-3.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_4=`address_from_filepath "$ft_address_dir_path/testFT-4.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_5=`address_from_filepath "$ft_address_dir_path/testFT-5.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_6=`address_from_filepath "$ft_address_dir_path/testFT-6.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_7=`address_from_filepath "$ft_address_dir_path/testFT-7.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_8=`address_from_filepath "$ft_address_dir_path/testFT-8.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_9=`address_from_filepath "$ft_address_dir_path/testFT-9.txt"`

    export EXPECTED_TEST_NFT_ADDRESSES_0=`address_from_filepath "$nft_address_dir_path/testNFT-0.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_1=`address_from_filepath "$nft_address_dir_path/testNFT-1.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_2=`address_from_filepath "$nft_address_dir_path/testNFT-2.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_3=`address_from_filepath "$nft_address_dir_path/testNFT-3.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_4=`address_from_filepath "$nft_address_dir_path/testNFT-4.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_5=`address_from_filepath "$nft_address_dir_path/testNFT-5.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_6=`address_from_filepath "$nft_address_dir_path/testNFT-6.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_7=`address_from_filepath "$nft_address_dir_path/testNFT-7.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_8=`address_from_filepath "$nft_address_dir_path/testNFT-8.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_9=`address_from_filepath "$nft_address_dir_path/testNFT-9.txt"`

    export EXPECTED_TEST_SFT_ADDRESSES_0=`address_from_filepath "$sft_address_dir_path/testSFT-0.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_1=`address_from_filepath "$sft_address_dir_path/testSFT-1.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_2=`address_from_filepath "$sft_address_dir_path/testSFT-2.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_3=`address_from_filepath "$sft_address_dir_path/testSFT-3.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_4=`address_from_filepath "$sft_address_dir_path/testSFT-4.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_5=`address_from_filepath "$sft_address_dir_path/testSFT-5.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_6=`address_from_filepath "$sft_address_dir_path/testSFT-6.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_7=`address_from_filepath "$sft_address_dir_path/testSFT-7.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_8=`address_from_filepath "$sft_address_dir_path/testSFT-8.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_9=`address_from_filepath "$sft_address_dir_path/testSFT-9.txt"`
    
    ########################################## DEPLOY ######################################################################
    magiclane_dir_path="../../../magiclane-evm/addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}""
    export MAGICLANE_SPOKE_ENDPOINT_ADDRESS=$(<${magiclane_dir_path}/spokeEndpoint.txt)
    
    forge script --legacy deploymentScripts/MagiclaneMockApp.s.sol:MagiclaneMockAppDeployment --rpc-url $RPC_URL --broadcast
    forge script --legacy deploymentScripts/TestFT.s.sol:TestFTDeployment --rpc-url $RPC_URL --broadcast
    forge script --legacy deploymentScripts/TestNFT.s.sol:TestNFTDeployment --rpc-url $RPC_URL --broadcast
    forge script --legacy deploymentScripts/TestSFT.s.sol:TestSFTDeployment --rpc-url $RPC_URL --broadcast

    export MAGICLANE_MOCK_APP_ADDRESS=`address_from_filepath "${address_dir}/magiclaneMockApp.txt"`
    
    export TEST_FT_ADDRESSES_0=`address_from_filepath "$ft_address_dir_path/testFT-0.txt"`
    export TEST_FT_ADDRESSES_1=`address_from_filepath "$ft_address_dir_path/testFT-1.txt"`
    export TEST_FT_ADDRESSES_2=`address_from_filepath "$ft_address_dir_path/testFT-2.txt"`
    export TEST_FT_ADDRESSES_3=`address_from_filepath "$ft_address_dir_path/testFT-3.txt"`
    export TEST_FT_ADDRESSES_4=`address_from_filepath "$ft_address_dir_path/testFT-4.txt"`
    export TEST_FT_ADDRESSES_5=`address_from_filepath "$ft_address_dir_path/testFT-5.txt"`
    export TEST_FT_ADDRESSES_6=`address_from_filepath "$ft_address_dir_path/testFT-6.txt"`
    export TEST_FT_ADDRESSES_7=`address_from_filepath "$ft_address_dir_path/testFT-7.txt"`
    export TEST_FT_ADDRESSES_8=`address_from_filepath "$ft_address_dir_path/testFT-8.txt"`
    export TEST_FT_ADDRESSES_9=`address_from_filepath "$ft_address_dir_path/testFT-9.txt"`

    export TEST_NFT_ADDRESSES_0=`address_from_filepath "$nft_address_dir_path/testNFT-0.txt"`
    export TEST_NFT_ADDRESSES_1=`address_from_filepath "$nft_address_dir_path/testNFT-1.txt"`
    export TEST_NFT_ADDRESSES_2=`address_from_filepath "$nft_address_dir_path/testNFT-2.txt"`
    export TEST_NFT_ADDRESSES_3=`address_from_filepath "$nft_address_dir_path/testNFT-3.txt"`
    export TEST_NFT_ADDRESSES_4=`address_from_filepath "$nft_address_dir_path/testNFT-4.txt"`
    export TEST_NFT_ADDRESSES_5=`address_from_filepath "$nft_address_dir_path/testNFT-5.txt"`
    export TEST_NFT_ADDRESSES_6=`address_from_filepath "$nft_address_dir_path/testNFT-6.txt"`
    export TEST_NFT_ADDRESSES_7=`address_from_filepath "$nft_address_dir_path/testNFT-7.txt"`
    export TEST_NFT_ADDRESSES_8=`address_from_filepath "$nft_address_dir_path/testNFT-8.txt"`
    export TEST_NFT_ADDRESSES_9=`address_from_filepath "$nft_address_dir_path/testNFT-9.txt"`

    export TEST_SFT_ADDRESSES_0=`address_from_filepath "$sft_address_dir_path/testSFT-0.txt"`
    export TEST_SFT_ADDRESSES_1=`address_from_filepath "$sft_address_dir_path/testSFT-1.txt"`
    export TEST_SFT_ADDRESSES_2=`address_from_filepath "$sft_address_dir_path/testSFT-2.txt"`
    export TEST_SFT_ADDRESSES_3=`address_from_filepath "$sft_address_dir_path/testSFT-3.txt"`
    export TEST_SFT_ADDRESSES_4=`address_from_filepath "$sft_address_dir_path/testSFT-4.txt"`
    export TEST_SFT_ADDRESSES_5=`address_from_filepath "$sft_address_dir_path/testSFT-5.txt"`
    export TEST_SFT_ADDRESSES_6=`address_from_filepath "$sft_address_dir_path/testSFT-6.txt"`
    export TEST_SFT_ADDRESSES_7=`address_from_filepath "$sft_address_dir_path/testSFT-7.txt"`
    export TEST_SFT_ADDRESSES_8=`address_from_filepath "$sft_address_dir_path/testSFT-8.txt"`
    export TEST_SFT_ADDRESSES_9=`address_from_filepath "$sft_address_dir_path/testSFT-9.txt"`
    
    echo "
    deployed magiclane mock app and tokens on $CHAIN_NAME
    magiclane mock app = ${MAGICLANE_MOCK_APP_ADDRESS}

    TestFT_0 = ${TEST_FT_ADDRESSES_0}
    TestFT_1 = ${TEST_FT_ADDRESSES_1}
    TestFT_2 = ${TEST_FT_ADDRESSES_2}
    TestFT_3 = ${TEST_FT_ADDRESSES_3}
    TestFT_4 = ${TEST_FT_ADDRESSES_4}
    TestFT_5 = ${TEST_FT_ADDRESSES_5}
    TestFT_6 = ${TEST_FT_ADDRESSES_6}
    TestFT_7 = ${TEST_FT_ADDRESSES_7}
    TestFT_8 = ${TEST_FT_ADDRESSES_8}
    TestFT_9 = ${TEST_FT_ADDRESSES_9}

    TestNFT_0 = ${TEST_NFT_ADDRESSES_0}
    TestNFT_1 = ${TEST_NFT_ADDRESSES_1}
    TestNFT_2 = ${TEST_NFT_ADDRESSES_2}
    TestNFT_3 = ${TEST_NFT_ADDRESSES_3}
    TestNFT_4 = ${TEST_NFT_ADDRESSES_4}
    TestNFT_5 = ${TEST_NFT_ADDRESSES_5}
    TestNFT_6 = ${TEST_NFT_ADDRESSES_6}
    TestNFT_7 = ${TEST_NFT_ADDRESSES_7}
    TestNFT_8 = ${TEST_NFT_ADDRESSES_8}
    TestNFT_9 = ${TEST_NFT_ADDRESSES_9}

    TestSFT_0 = ${TEST_SFT_ADDRESSES_0}
    TestSFT_1 = ${TEST_SFT_ADDRESSES_1}
    TestSFT_2 = ${TEST_SFT_ADDRESSES_2}
    TestSFT_3 = ${TEST_SFT_ADDRESSES_3}
    TestSFT_4 = ${TEST_SFT_ADDRESSES_4}
    TestSFT_5 = ${TEST_SFT_ADDRESSES_5}
    TestSFT_6 = ${TEST_SFT_ADDRESSES_6}
    TestSFT_7 = ${TEST_SFT_ADDRESSES_7}
    TestSFT_8 = ${TEST_SFT_ADDRESSES_8}
    TestSFT_9 = ${TEST_SFT_ADDRESSES_9}
    "
done
