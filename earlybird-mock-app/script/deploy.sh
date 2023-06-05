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
    export MNEMONICS=$(op read "op://Private/Deployment/Mnemonic_phrase/"$ENVIRONMENT"")
    export KEY_INDEX=0

    # To be decided
    # export ORACLE_MNEMONICS=$(op read "op://Security/MockApp/Sending_mnemonic_phrase")
    export ORACLE_KEY_INDEX=0

    # To be decided
    # export RELAYER_MNEMONICS=$(op read "op://Security/MockApp/Sending_mnemonic_phrase")
    export RELAYER_KEY_INDEX=1

elif [ "$ENVIRONMENT" == "Public_Testnet" ]
then
    search_directory=environmentVariables/publicTestnet
    export ADDRESS_FOLDER=public_testnet
    export MNEMONICS=$(op read "op://Private/Deployment/Mnemonic_phrase/"$ENVIRONMENT"")
    export KEY_INDEX=0

    export ORACLE_MNEMONICS=$(op read "op://Security/MockApp/Sending_mnemonic_phrase")
    export ORACLE_KEY_INDEX=0

    export RELAYER_MNEMONICS=$(op read "op://Security/MockApp/Sending_mnemonic_phrase")
    export RELAYER_KEY_INDEX=1

elif [ "$ENVIRONMENT" == "Local_Testnet" ]
then
    search_directory=environmentVariables/localTestnet
    export ADDRESS_FOLDER=local_testnet
    export KEY_INDEX=3

    export ORACLE_MNEMONICS=$MNEMONICS
    export ORACLE_KEY_INDEX=0

    export RELAYER_MNEMONICS=$MNEMONICS
    export RELAYER_KEY_INDEX=1
fi

############################################## DEPLOYING MOCK THUNDERBIRD ORACLE TO CHAINS IN SEARCH DIRECTORY ##############################################
for entry in "$search_directory"/*
do
    . "$entry"
    expected_mock_thunderbird_oracle_address_path="deploymentScripts/mockThunderbirdOracle/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_thunderbird_oracle_address_path" ]
    then
        expected_mock_thunderbird_oracle_address=$(<$expected_mock_thunderbird_oracle_address_path)
        export EXPECTED_MOCK_THUNDERBIRD_ORACLE_ADDRESS=$expected_mock_thunderbird_oracle_address
    else
        default_expected_mock_thunderbird_oracle_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_THUNDERBIRD_ORACLE_ADDRESS=$default_expected_mock_thunderbird_oracle_address
    fi

    forge script deploymentScripts/mockThunderbirdOracle/mockThunderbirdOracle.s.sol:MockThunderbirdOracleDeployment --rpc-url $RPC_URL --broadcast
done

############################################## DEPLOYING MOCK THUNDERBIRD RELAYER TO CHAINS IN SEARCH DIRECTORY ##############################################
for entry in "$search_directory"/*
do
    . "$entry"
    expected_mock_thunderbird_relayer_address_path="deploymentScripts/mockThunderbirdRelayer/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_thunderbird_relayer_address_path" ]
    then
        expected_mock_thunderbird_relayer_address=$(<$expected_mock_thunderbird_relayer_address_path)
        export EXPECTED_MOCK_THUNDERBIRD_RELAYER_ADDRESS=$expected_mock_thunderbird_relayer_address
    else
        default_expected_mock_thunderbird_relayer_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_THUNDERBIRD_RELAYER_ADDRESS=$default_expected_mock_thunderbird_relayer_address
    fi

    forge script deploymentScripts/mockThunderbirdRelayer/mockThunderbirdRelayer.s.sol:MockThunderbirdRelayerDeployment --rpc-url $RPC_URL --broadcast
done

########################################## DEPLOYING MOCK THUNDERBIRD RECS CONTRACT TO CHAINS IN SEARCH DIRECTORY ##############################################
for entry in "$search_directory"/*
do
    . "$entry"
    expected_mock_thunderbird_recs_contract_address_path="deploymentScripts/mockThunderbirdRecsContract/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_thunderbird_recs_contract_address_path" ]
    then
        expected_mock_thunderbird_recs_contract_address=$(<$expected_mock_thunderbird_recs_contract_address_path)
        export EXPECTED_MOCK_THUNDERBIRD_RECS_CONTRACT_ADDRESS=$expected_mock_thunderbird_recs_contract_address
    else
        default_expected_mock_thunderbird_recs_contract_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_THUNDERBIRD_RECS_CONTRACT_ADDRESS=$default_expected_mock_thunderbird_recs_contract_address
    fi

    forge script deploymentScripts/mockThunderbirdRecsContract/mockThunderbirdRecsContract.s.sol:MockThunderbirdRecsContractDeployment --rpc-url $RPC_URL --broadcast
done

########################################## DEPLOYING MOCK RUKH ORACLE TO CHAINS IN SEARCH DIRECTORY ##############################################
for entry in "$search_directory"/*
do
    . "$entry"
    expected_mock_rukh_oracle_address_path="deploymentScripts/mockRukhOracle/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_rukh_oracle_address_path" ]
    then
        expected_mock_rukh_oracle_address=$(<$expected_mock_rukh_oracle_address_path)
        export EXPECTED_MOCK_RUKH_ORACLE_ADDRESS=$expected_mock_rukh_oracle_address
    else
        default_expected_mock_rukh_oracle_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_RUKH_ORACLE_ADDRESS=$default_expected_mock_rukh_oracle_address
    fi

    forge script deploymentScripts/mockRukhOracle/mockRukhOracle.s.sol:MockRukhOracleDeployment --rpc-url $RPC_URL --broadcast
done
    
########################################## DEPLOYING MOCK RUKH RELAYER TO CHAINS IN SEARCH DIRECTORY ##############################################
for entry in "$search_directory"/*
do
    . "$entry"
    expected_mock_rukh_relayer_address_path="deploymentScripts/mockRukhRelayer/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_rukh_relayer_address_path" ]
    then
        expected_mock_rukh_relayer_address=$(<$expected_mock_rukh_relayer_address_path)
        export EXPECTED_MOCK_RUKH_RELAYER_ADDRESS=$expected_mock_rukh_relayer_address
    else
        default_expected_mock_rukh_relayer_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_RUKH_RELAYER_ADDRESS=$default_expected_mock_rukh_relayer_address
    fi

    forge script deploymentScripts/mockRukhRelayer/mockRukhRelayer.s.sol:MockRukhRelayerDeployment --rpc-url $RPC_URL --broadcast
done

########################################## DEPLOYING MOCK RUKH RECS CONTRACT TO CHAINS IN SEARCH DIRECTORY ##############################################
for entry in "$search_directory"/*
do
    . "$entry"
    expected_mock_rukh_recs_contract_address_path="deploymentScripts/mockRukhRecsContract/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_rukh_recs_contract_address_path" ]
    then
        expected_mock_rukh_recs_contract_address=$(<$expected_mock_rukh_recs_contract_address_path)
        export EXPECTED_MOCK_RUKH_RECS_CONTRACT_ADDRESS=$expected_mock_rukh_recs_contract_address
    else
        default_expected_mock_rukh_recs_contract_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_RUKH_RECS_CONTRACT_ADDRESS=$default_expected_mock_rukh_recs_contract_address
    fi

    forge script deploymentScripts/mockRukhRecsContract/mockRukhRecsContract.s.sol:MockRukhRecsContractDeployment --rpc-url $RPC_URL --broadcast
done

########################################## DEPLOYING MOCK RUKH DISPUTER CONTRACT TO CHAINS IN SEARCH DIRECTORY ##############################################
for entry in "$search_directory"/*
do
    . "$entry"
    expected_mock_rukh_disputer_contract_address_path="deploymentScripts/mockRukhDisputerContract/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_rukh_disputer_contract_address_path" ]
    then
        expected_mock_rukh_disputer_contract_address=$(<$expected_mock_rukh_disputer_contract_address_path)
        export EXPECTED_MOCK_RUKH_DISPUTER_CONTRACT_ADDRESS=$expected_mock_rukh_disputer_contract_address
    else
        default_expected_mock_rukh_disputer_contract_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_RUKH_DISPUTER_CONTRACT_ADDRESS=$default_expected_mock_rukh_disputer_contract_address
    fi

    forge script deploymentScripts/mockRukhDisputerContract/mockRukhDisputerContract.s.sol:MockRukhDisputerContractDeployment --rpc-url $RPC_URL --broadcast
done

########################################## DEPLOYING MOCK THUNDERBIRD APP TO CHAINS IN SEARCH DIRECTORY ##############################################
for entry in "$search_directory"/*
do
    . "$entry"

    expected_endpoint_address_path="../../earlybird-evm/script/deploymentScripts/endpoint/endpointV1/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_endpoint_address_path" ]
    then
        expected_endpoint_address=$(<$expected_endpoint_address_path)
        export EXPECTED_EARLYBIRD_ENDPOINT_ADDRESS=$expected_endpoint_address
    fi

    expected_mock_thunderbird_app_address_path="deploymentScripts/mockThunderbirdApp/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"
    
    if [ -f "$expected_mock_thunderbird_app_address_path" ]
    then
        expected_mock_thunderbird_app_address=$(<$expected_mock_thunderbird_app_address_path)
        export EXPECTED_MOCK_THUNDERBIRD_APP_ADDRESS=$expected_mock_thunderbird_app_address
    else
        default_expected_mock_thunderbird_app_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_THUNDERBIRD_APP_ADDRESS=$default_expected_mock_thunderbird_app_address
    fi

    expected_mock_thunderbird_oracle_address_path="deploymentScripts/mockThunderbirdOracle/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_thunderbird_oracle_address_path" ]
    then
        expected_mock_thunderbird_oracle_address=$(<$expected_mock_thunderbird_oracle_address_path)
        export EXPECTED_MOCK_THUNDERBIRD_ORACLE_ADDRESS=$expected_mock_thunderbird_oracle_address
    else
        default_expected_mock_thunderbird_oracle_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_THUNDERBIRD_ORACLE_ADDRESS=$default_expected_mock_thunderbird_oracle_address
    fi

    expected_mock_thunderbird_relayer_address_path="deploymentScripts/mockThunderbirdRelayer/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_thunderbird_relayer_address_path" ]
    then
        expected_mock_thunderbird_relayer_address=$(<$expected_mock_thunderbird_relayer_address_path)
        export EXPECTED_MOCK_THUNDERBIRD_RELAYER_ADDRESS=$expected_mock_thunderbird_relayer_address
    else
        default_expected_mock_thunderbird_relayer_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_THUNDERBIRD_RELAYER_ADDRESS=$default_expected_mock_thunderbird_relayer_address
    fi

    expected_mock_thunderbird_recs_contract_address_path="deploymentScripts/mockThunderbirdRecsContract/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_thunderbird_recs_contract_address_path" ]
    then
        expected_mock_thunderbird_recs_contract_address=$(<$expected_mock_thunderbird_recs_contract_address_path)
        export EXPECTED_MOCK_THUNDERBIRD_RECS_CONTRACT_ADDRESS=$expected_mock_thunderbird_recs_contract_address
    else
        default_expected_mock_thunderbird_recs_contract_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_THUNDERBIRD_RECS_CONTRACT_ADDRESS=$default_expected_mock_thunderbird_recs_contract_address
    fi

    forge script deploymentScripts/mockThunderbirdApp/mockThunderbirdApp.s.sol:MockThunderbirdAppDeployment --rpc-url $RPC_URL --broadcast
done

########################################## DEPLOYING MOCK RUKH APP TO CHAINS IN SEARCH DIRECTORY ##############################################
for entry in "$search_directory"/*
do
    . "$entry"

    expected_endpoint_address_path="../../earlybird-evm/script/deploymentScripts/endpoint/endpointV1/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_endpoint_address_path" ]
    then
        expected_endpoint_address=$(<$expected_endpoint_address_path)
        export EXPECTED_EARLYBIRD_ENDPOINT_ADDRESS=$expected_endpoint_address
    fi

    expected_mock_rukh_app_address_path="deploymentScripts/mockRukhApp/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"
    
    if [ -f "$expected_mock_rukh_app_address_path" ]
    then
        expected_mock_rukh_app_address=$(<$expected_mock_rukh_app_address_path)
        export EXPECTED_MOCK_RUKH_APP_ADDRESS=$expected_mock_rukh_app_address
    else
        default_expected_mock_rukh_app_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_RUKH_APP_ADDRESS=$default_expected_mock_rukh_app_address
    fi

    expected_mock_rukh_oracle_address_path="deploymentScripts/mockRukhOracle/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_rukh_oracle_address_path" ]
    then
        expected_mock_rukh_oracle_address=$(<$expected_mock_rukh_oracle_address_path)
        export EXPECTED_MOCK_RUKH_ORACLE_ADDRESS=$expected_mock_rukh_oracle_address
    else
        default_expected_mock_rukh_oracle_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_RUKH_ORACLE_ADDRESS=$default_expected_mock_rukh_oracle_address
    fi

    expected_mock_rukh_relayer_address_path="deploymentScripts/mockRukhRelayer/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_rukh_relayer_address_path" ]
    then
        expected_mock_rukh_relayer_address=$(<$expected_mock_rukh_relayer_address_path)
        export EXPECTED_MOCK_RUKH_RELAYER_ADDRESS=$expected_mock_rukh_relayer_address
    else
        default_expected_mock_rukh_relayer_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_RUKH_RELAYER_ADDRESS=$default_expected_mock_rukh_relayer_address
    fi

    expected_mock_rukh_recs_contract_address_path="deploymentScripts/mockRukhRecsContract/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_rukh_recs_contract_address_path" ]
    then
        expected_mock_rukh_recs_contract_address=$(<$expected_mock_rukh_recs_contract_address_path)
        export EXPECTED_MOCK_RUKH_RECS_CONTRACT_ADDRESS=$expected_mock_rukh_recs_contract_address
    else
        default_expected_mock_rukh_recs_contract_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_RUKH_RECS_CONTRACT_ADDRESS=$default_expected_mock_rukh_recs_contract_address
    fi

    expected_mock_rukh_disputer_contract_address_path="deploymentScripts/mockRukhDisputerContract/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_mock_rukh_disputer_contract_address_path" ]
    then
        expected_mock_rukh_disputer_contract_address=$(<$expected_mock_rukh_disputer_contract_address_path)
        export EXPECTED_MOCK_RUKH_DISPUTER_CONTRACT_ADDRESS=$expected_mock_rukh_disputer_contract_address
    else
        default_expected_mock_rukh_disputer_contract_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_MOCK_RUKH_DISPUTER_CONTRACT_ADDRESS=$default_expected_mock_rukh_disputer_contract_address
    fi

    export DISPUTE_RESOLVER_MNEMONICS=$MNEMONICS
    export DISPUTE_RESOLVER_KEY_INDEX=10

    forge script deploymentScripts/mockRukhApp/mockRukhApp.s.sol:MockRukhAppDeployment --rpc-url $RPC_URL --broadcast
done