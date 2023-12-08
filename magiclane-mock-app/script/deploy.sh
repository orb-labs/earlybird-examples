############################################### SETTING ENVIRONMENT VARIABLES ##############################################

### set env vars if unset
: ${ENVIRONMENT:="local"}
: ${CHAINS_DIRECTORY:="environmentVariables/${ENVIRONMENT}"}
: ${KEY_INDEX:="0"}
: ${MNEMONICS:="test test test test test test test test test test test junk"}
export ENVIRONMENT KEY_INDEX MNEMONICS

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

############################################################################################################################
if [[ -z $CHAINS_DIRECTORY || -z $ENVIRONMENT || -z $KEY_INDEX || -z $MNEMONICS  ]]; then echo "env vars unset" && exit 1;fi
for entry in "$CHAINS_DIRECTORY"/*
do
    . "$entry"

    address_dir="../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}""
    if [[ ! -d $address_dir ]]; then mkdir $address_dir; fi

    ########################################## GET EXISTING ADDRESSES ######################################################
    export EXPECTED_MAGICLANE_MOCK_APP_ADDRESS=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/MagiclaneMockApp.txt"`

    export EXPECTED_TEST_FT_ADDRESSES_1=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-1.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_2=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-2.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_3=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-3.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_4=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-4.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_5=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-5.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_6=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-6.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_7=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-7.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_8=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-8.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_9=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-9.txt"`
    export EXPECTED_TEST_FT_ADDRESSES_10=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-10.txt"`

    export EXPECTED_TEST_NFT_ADDRESSES_1=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-1.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_2=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-2.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_3=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-3.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_4=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-4.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_5=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-5.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_6=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-6.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_7=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-7.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_8=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-8.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_9=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-9.txt"`
    export EXPECTED_TEST_NFT_ADDRESSES_10=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-10.txt"`

    export EXPECTED_TEST_SFT_ADDRESSES_1=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-1.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_2=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-2.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_3=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-3.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_4=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-4.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_5=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-5.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_6=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-6.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_7=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-7.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_8=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-8.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_9=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-9.txt"`
    export EXPECTED_TEST_SFT_ADDRESSES_10=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-10.txt"`
    
    ########################################## DEPLOY ######################################################################
    forge script --legacy deploymentScripts/MagiclaneMockApp.s.sol:MagiclaneMockAppDeployment --rpc-url $RPC_URL --broadcast
    forge script --legacy deploymentScripts/TestFT.s.sol:TestFTDeployment --rpc-url $RPC_URL --broadcast
    forge script --legacy deploymentScripts/TestNFT.s.sol:TestNFTDeployment --rpc-url $RPC_URL --broadcast
    forge script --legacy deploymentScripts/TestSFT.s.sol:TestSFTDeployment --rpc-url $RPC_URL --broadcast

    export MAGICLANE_MOCK_APP_ADDRESS=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/magiclaneMockApp.txt"`
    export TEST_FT_ADDRESSES_1=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-1.txt"`
    export TEST_FT_ADDRESSES_2=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-2.txt"`
    export TEST_FT_ADDRESSES_3=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-3.txt"`
    export TEST_FT_ADDRESSES_4=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-4.txt"`
    export TEST_FT_ADDRESSES_5=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-5.txt"`
    export TEST_FT_ADDRESSES_6=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-6.txt"`
    export TEST_FT_ADDRESSES_7=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-7.txt"`
    export TEST_FT_ADDRESSES_8=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-8.txt"`
    export TEST_FT_ADDRESSES_9=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-9.txt"`
    export TEST_FT_ADDRESSES_10=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestFTs/TestFT-10.txt"`

    export TEST_NFT_ADDRESSES_1=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-1.txt"`
    export TEST_NFT_ADDRESSES_2=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-2.txt"`
    export TEST_NFT_ADDRESSES_3=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-3.txt"`
    export TEST_NFT_ADDRESSES_4=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-4.txt"`
    export TEST_NFT_ADDRESSES_5=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-5.txt"`
    export TEST_NFT_ADDRESSES_6=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-6.txt"`
    export TEST_NFT_ADDRESSES_7=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-7.txt"`
    export TEST_NFT_ADDRESSES_8=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-8.txt"`
    export TEST_NFT_ADDRESSES_9=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-9.txt"`
    export TEST_NFT_ADDRESSES_10=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestNFTs/TestNFT-10.txt"`

    export TEST_SFT_ADDRESSES_1=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-1.txt"`
    export TEST_SFT_ADDRESSES_2=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-2.txt"`
    export TEST_SFT_ADDRESSES_3=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-3.txt"`
    export TEST_SFT_ADDRESSES_4=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-4.txt"`
    export TEST_SFT_ADDRESSES_5=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-5.txt"`
    export TEST_SFT_ADDRESSES_6=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-6.txt"`
    export TEST_SFT_ADDRESSES_7=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-7.txt"`
    export TEST_SFT_ADDRESSES_8=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-8.txt"`
    export TEST_SFT_ADDRESSES_9=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-9.txt"`
    export TEST_SFT_ADDRESSES_10=`address_from_filepath "../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}"/TestSFTs/TestSFT-10.txt"`
    
    echo "
    deployed magiclane mock app and tokens on $CHAIN_NAME
    magiclane mock app = ${MAGICLANE_MOCK_APP_ADDRESS}

    TestFT_1 = ${TEST_FT_ADDRESSES_1}
    TestFT_2 = ${TEST_FT_ADDRESSES_2}
    TestFT_3 = ${TEST_FT_ADDRESSES_3}
    TestFT_4 = ${TEST_FT_ADDRESSES_4}
    TestFT_5 = ${TEST_FT_ADDRESSES_5}
    TestFT_6 = ${TEST_FT_ADDRESSES_6}
    TestFT_7 = ${TEST_FT_ADDRESSES_7}
    TestFT_8 = ${TEST_FT_ADDRESSES_8}
    TestFT_9 = ${TEST_FT_ADDRESSES_9}
    TestFT_10 = ${TEST_FT_ADDRESSES_10}

    TestNFT_1 = ${TEST_NFT_ADDRESSES_1}
    TestNFT_2 = ${TEST_NFT_ADDRESSES_2}
    TestNFT_3 = ${TEST_NFT_ADDRESSES_3}
    TestNFT_4 = ${TEST_NFT_ADDRESSES_4}
    TestNFT_5 = ${TEST_NFT_ADDRESSES_5}
    TestNFT_6 = ${TEST_NFT_ADDRESSES_6}
    TestNFT_7 = ${TEST_NFT_ADDRESSES_7}
    TestNFT_8 = ${TEST_NFT_ADDRESSES_8}
    TestNFT_9 = ${TEST_NFT_ADDRESSES_9}
    TestNFT_10 = ${TEST_NFT_ADDRESSES_10}

    TestSFT_1 = ${TEST_SFT_ADDRESSES_1}
    TestSFT_2 = ${TEST_SFT_ADDRESSES_2}
    TestSFT_3 = ${TEST_SFT_ADDRESSES_3}
    TestSFT_4 = ${TEST_SFT_ADDRESSES_4}
    TestSFT_5 = ${TEST_SFT_ADDRESSES_5}
    TestSFT_6 = ${TEST_SFT_ADDRESSES_6}
    TestSFT_7 = ${TEST_SFT_ADDRESSES_7}
    TestSFT_8 = ${TEST_SFT_ADDRESSES_8}
    TestSFT_9 = ${TEST_SFT_ADDRESSES_9}
    TestSFT_10 = ${TEST_SFT_ADDRESSES_10}
    "
done
