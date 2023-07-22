############################################### SETTING ENVIRONMENT VARIABLES ##############################################

# Uncomment for local chains
export ENVIRONMENT=${ENVIRONMENT:-local}

# Uncomment for public testnet
# export ENVIRONMENT="testnet"

# Uncomment for mainnet
# export ENVIRONMENT="mainnet"

chains_directory="environmentVariables/$ENVIRONMENT"

export KEY_INDEX=3

export MNEMONICS="test test test test test test test test test test test junk"
export ORACLE_MNEMONICS=$MNEMONICS
export ORACLE_KEY_INDEX=0
export RELAYER_MNEMONICS=$MNEMONICS
export RELAYER_KEY_INDEX=1
export DISPUTE_RESOLVER_KEY_INDEX=10

if [ "$ENVIRONMENT" != "local" ]
then
    export MNEMONICS=$(op read "op://Private/Deployment/Mnemonic_phrase/"$ENVIRONMENT"")
    export KEY_INDEX=0
fi

export DISPUTE_RESOLVER_MNEMONICS=$MNEMONICS

############################################## Helper Functions ############################################################

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

for entry in "$chains_directory"/*
do
    . "$entry"

    ########################################## GET EXISTING ADDRESSES ######################################################
    export EXPECTED_MOCK_SENDING_ORACLE_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/sending_oracle.txt"`
    export EXPECTED_MOCK_SENDING_RELAYER_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/sending_relayer.txt"`
    export EXPECTED_MOCK_THUNDERBIRD_APP_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/thunderbird/app.txt"`
    export EXPECTED_MOCK_THUNDERBIRD_RECS_CONTRACT_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/thunderbird/recs_contract.txt"`
    export EXPECTED_MOCK_RUKH_APP_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/app.txt"`
    export EXPECTED_MOCK_RUKH_RECS_CONTRACT_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/recs_contract.txt"`
    export EXPECTED_MOCK_RUKH_DISPUTER_CONTRACT_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/disputer_contract.txt"`

    ########################################## DEPLOY FEE COLLECTORS #######################################################
    
    forge script deploymentScripts/feeCollectors/MockSendingOracle.s.sol:MockSendingOracleDeployment --rpc-url $RPC_URL --broadcast
    export MOCK_SENDING_ORACLE_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/sending_oracle.txt"`
    
    forge script deploymentScripts/feeCollectors/MockSendingRelayer.s.sol:MockSendingRelayerDeployment --rpc-url $RPC_URL --broadcast
    export MOCK_SENDING_RELAYER_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/sending_relayer.txt"`

    ########################################## DEPLOY THUNDERBIRD VERSION ##################################################
    forge script deploymentScripts/thunderbird/MockThunderbirdRecsContract.s.sol:MockThunderbirdRecsContractDeployment --rpc-url $RPC_URL --broadcast
    export MOCK_THUNDERBIRD_RECS_CONTRACT_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/thunderbird/recs_contract.txt"`
    
    forge script deploymentScripts/thunderbird/MockThunderbirdApp.s.sol:MockThunderbirdAppDeployment --rpc-url $RPC_URL --broadcast

    
    ########################################## DEPLOY RUKH VERSION #########################################################
    forge script deploymentScripts/rukh/MockRukhRecsContract.s.sol:MockRukhRecsContractDeployment --rpc-url $RPC_URL --broadcast
    export MOCK_RUKH_RECS_CONTRACT_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/recs_contract.txt"`
    
    forge script deploymentScripts/rukh/MockRukhDisputerContract.s.sol:MockRukhDisputerContractDeployment --rpc-url $RPC_URL --broadcast
    export MOCK_RUKH_DISPUTER_CONTRACT_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/disputer_contract.txt"`

    forge script deploymentScripts/rukh/mockRukhApp.s.sol:MockRukhAppDeployment --rpc-url $RPC_URL --broadcast
done
