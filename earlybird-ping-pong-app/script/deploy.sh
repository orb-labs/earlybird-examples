############################################################# SETTING ENVIRONMENT VARIABLES ################################################################

# Uncomment for local_testnet
export ENVIRONMENT="${ENVIRONMENT:-Local_Testnet}"

# Uncomment for public testnet
# export ENVIRONMENT="Public_Testnet"

# Uncomment for mainnet
# export ENVIRONMENT="Production"

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
    export MNEMONICS="<ADD YOUR MNEMONIC HERE>"
    export KEY_INDEX=3

    export ORACLE_MNEMONICS=$MNEMONICS
    export ORACLE_KEY_INDEX=0

    export RELAYER_MNEMONICS=$MNEMONICS
    export RELAYER_KEY_INDEX=1
fi

export EXPECTED_DISPUTERESOLVER_ADDRESS=0

############################################## DEPLOYING RukhVersion PingPong App TO CHAINS ############################################################
for entry in "$search_directory"/*
do
    # set env vars in environmentVariables/
    . "$entry"

    expected_endpoint_address_path="../../earlybird-evm/script/deploymentScripts/endpoint/endpointV1/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"   

    if [ -f "$expected_endpoint_address_path" ]
    then
        expected_endpoint_address=$(<$expected_endpoint_address_path)
        echo $expected_endpoint_address
        export EXPECTED_EARLYBIRD_ENDPOINT_ADDRESS=$expected_endpoint_address
    fi

    expected_rukh_version_pingpong_sending_relayer_address_path="deploymentScripts/RukhVersion/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME"/sending_relayer.txt"

    if [ -f "$expected_rukh_version_pingpong_sending_relayer_address_path" ]
    then
        expected_rukh_version_pingpong_sending_relayer_address=$(<$expected_rukh_version_pingpong_sending_relayer_address_path)
        export EXPECTED_RUKH_VERSION_PINGPONG_SENDING_RELAYER_ADDRESS=$expected_rukh_version_pingpong_sending_relayer_address
    else
        default_expected_rukh_version_pingpong_sending_relayer_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_RUKH_VERSION_PINGPONG_SENDING_RELAYER_ADDRESS=$default_expected_rukh_version_pingpong_sending_relayer_address
    fi

    expected_rukh_version_pingpong_sending_oracle_address_path="deploymentScripts/RukhVersion/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME"/sending_oracle.txt"

    if [ -f "$expected_rukh_version_pingpong_sending_oracle_address_path" ]
    then
        expected_rukh_version_pingpong_sending_oracle_address=$(<$expected_rukh_version_pingpong_sending_oracle_address_path)
        export EXPECTED_RUKH_VERSION_PINGPONG_SENDING_ORACLE_ADDRESS=$expected_rukh_version_pingpong_sending_oracle_address
    else
        default_expected_rukh_version_pingpong_sending_oracle_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_RUKH_VERSION_PINGPONG_SENDING_ORACLE_ADDRESS=$default_expected_rukh_version_pingpong_sending_oracle_address
    fi

    expected_rukh_version_pingpong_disputers_contract_address_path="deploymentScripts/RukhVersion/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME"/disputers_contract.txt"

    if [ -f "$expected_rukh_version_pingpong_disputers_contract_address_path" ]
    then
        expected_rukh_version_pingpong_disputers_contract_address=$(<$expected_rukh_version_pingpong_disputers_contract_address_path)
        export EXPECTED_RUKH_VERSION_PINGPONG_DISPUTERS_CONTRACT_ADDRESS=$expected_rukh_version_pingpong_disputers_contract_address
    else
        default_expected_rukh_version_pingpong_disputers_contract_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_RUKH_VERSION_PINGPONG_DISPUTERS_CONTRACT_ADDRESS=$default_expected_rukh_version_pingpong_disputers_contract_address
    fi

    expected_rukh_version_pingpong_address_path="deploymentScripts/RukhVersion/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"

    if [ -f "$expected_rukh_version_pingpong_address_path" ]
    then
        expected_rukh_version_pingpong_address=$(<$expected_rukh_version_pingpong_address_path)
        export EXPECTED_RUKH_VERSION_PINGPONG_ADDRESS=$expected_rukh_version_pingpong_address
    else
        default_expected_rukh_version_pingpong_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_RUKH_VERSION_PINGPONG_ADDRESS=$default_expected_rukh_version_pingpong_address
    fi

    export PING_ADDR=$EXPECTED_RUKH_VERSION_PINGPONG_ADDRESS
    forge script deploymentScripts/RukhVersion/SendingRelayer.sol:SendingRelayerDeployment --rpc-url $RPC_URL --broadcast
    forge script deploymentScripts/RukhVersion/SendingOracle.sol:SendingOracleDeployment --rpc-url $RPC_URL --broadcast
    forge script deploymentScripts/RukhVersion/DisputersContract.s.sol:DisputersContractDeployment --rpc-url $RPC_URL --broadcast
    forge script deploymentScripts/RukhVersion/PingPongRukh.s.sol:PingPongRukhDeployment --rpc-url $RPC_URL --broadcast
done


############################################## DEPLOYING ThunderbirdVersion PingPong App TO CHAINS ############################################################
for entry in "$search_directory"/*
do
    # set env vars in environmentVariables/
    . "$entry"

    expected_endpoint_address_path="../../earlybird-evm/script/deploymentScripts/endpoint/endpointV1/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME".txt"   

    if [ -f "$expected_endpoint_address_path" ]
    then
        expected_endpoint_address=$(<$expected_endpoint_address_path)
        echo $expected_endpoint_address
        export EXPECTED_EARLYBIRD_ENDPOINT_ADDRESS=$expected_endpoint_address
    fi

    expected_thunderbird_version_pingpong_sending_relayer_address_path="deploymentScripts/ThunderbirdVersion/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME"/sending_relayer.txt"

    if [ -f "$expected_thunderbird_version_pingpong_sending_relayer_address_path" ]
    then
        expected_thunderbird_version_pingpong_sending_relayer_address=$(<$expected_thunderbird_version_pingpong_sending_relayer_address_path)
        export EXPECTED_THUNDERBIRD_VERSION_PINGPONG_SENDING_RELAYER_ADDRESS=$expected_thunderbird_version_pingpong_sending_relayer_address
    else
        default_expected_thunderbird_version_pingpong_sending_relayer_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_THUNDERBIRD_VERSION_PINGPONG_SENDING_RELAYER_ADDRESS=$default_expected_thunderbird_version_pingpong_sending_relayer_address
    fi

    expected_thunderbird_version_pingpong_sending_oracle_address_path="deploymentScripts/ThunderbirdVersion/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME"/sending_oracle.txt"

    if [ -f "$expected_thunderbird_version_pingpong_sending_oracle_address_path" ]
    then
        expected_thunderbird_version_pingpong_sending_oracle_address=$(<$expected_thunderbird_version_pingpong_sending_oracle_address_path)
        export EXPECTED_THUNDERBIRD_VERSION_PINGPONG_SENDING_ORACLE_ADDRESS=$expected_thunderbird_version_pingpong_sending_oracle_address
    else
        default_expected_thunderbird_version_pingpong_sending_oracle_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_THUNDERBIRD_VERSION_PINGPONG_SENDING_ORACLE_ADDRESS=$default_expected_thunderbird_version_pingpong_sending_oracle_address
    fi

    expected_thunderbird_version_pingpong_address_path="deploymentScripts/ThunderbirdVersion/addresses/"$ADDRESS_FOLDER"/"$CHAIN_NAME"/app.txt"

    if [ -f "$expected_thunderbird_version_pingpong_address_path" ]
    then
        expected_thunderbird_version_pingpong_address=$(<$expected_thunderbird_version_pingpong_address_path)
        export EXPECTED_THUNDERBIRD_VERSION_PINGPONG_ADDRESS=$expected_thunderbird_version_pingpong_address
    else
        default_expected_thunderbird_version_pingpong_address="0x0000000000000000000000000000000000000000"
        export EXPECTED_THUNDERBIRD_VERSION_PINGPONG_ADDRESS=$default_expected_thunderbird_version_pingpong_address
    fi

    export PING_ADDR=$EXPECTED_THUNDERBIRD_VERSION_PINGPONG_ADDRESS
    forge script deploymentScripts/ThunderbirdVersion/SendingRelayer.sol:SendingRelayerDeployment --rpc-url $RPC_URL --broadcast
    forge script deploymentScripts/ThunderbirdVersion/SendingOracle.sol:SendingOracleDeployment --rpc-url $RPC_URL --broadcast
    forge script deploymentScripts/ThunderbirdVersion/PingPongThunderbird.s.sol:PingPongThunderbirdDeployment --rpc-url $RPC_URL --broadcast
done
