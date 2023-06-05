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
elif [ "$ENVIRONMENT" == "Public_Testnet" ]
then
    search_directory=environmentVariables/publicTestnet
    export ADDRESS_FOLDER=public_testnet
elif [ "$ENVIRONMENT" == "Local_Testnet" ]
then
    search_directory=environmentVariables/localTestnet
    export ADDRESS_FOLDER=local_testnet
fi

############################################## GETTING ALL MESSAGES SENT TO MOCK APP ############################################################
for entry in "$search_directory"/*
do
    . "$entry"
    expected_mock_rukh_app_address_path="deploymentScripts/mockRukhApp/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"
    echo $expected_mock_rukh_app_address_path

    if [ -f "$expected_mock_rukh_app_address_path" ]
    then
        expected_mock_rukh_app_address=$(<$expected_mock_rukh_app_address_path)
        export MOCK_RUKH_APP_ADDRESS=$expected_mock_rukh_app_address
    fi

    forge script deploymentScripts/mockRukhApp/mockRukhApp.s.sol:MockRukhAppGetAllMessages --rpc-url $RPC_URL --broadcast
done