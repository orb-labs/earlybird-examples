############################################### SETTING ENVIRONMENT VARIABLES ##############################################

### set env vars if unset
: "${ENVIRONMENT:=local}" 
: "${CHAINS_DIRECTORY:=environmentVariables/$ENVIRONMENT}"
: "${KEY_INDEX:=0}"
: "${MNEMONICS:=test test test test test test test test test test test junk}"
: "${ORACLE_MNEMONICS:=$MNEMONICS}"
: "${ORACLE_KEY_INDEX:=0}"
: "${RELAYER_MNEMONICS:=$MNEMONICS}"
: "${RELAYER_KEY_INDEX:=1}"
: "${DISPUTE_RESOLVER_MNEMONICS:=$MNEMONICS}"
: "${DISPUTE_RESOLVER_KEY_INDEX:=10}"

export ENVIRONMENT KEY_INDEX MNEMONICS ORACLE_MNEMONICS ORACLE_KEY_INDEX RELAYER_MNEMONICS RELAYER_KEY_INDEX DISPUTE_RESOLVER_MNEMONICS DISPUTE_RESOLVER_KEY_INDEX

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

for entry in "$CHAINS_DIRECTORY"/*
do
    . "$entry"

    ########################################## GET EXISTING ADDRESSES ######################################################
    export EXPECTED_MOCK_THUNDERBIRD_APP_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/thunderbird/app.txt"`
    export EXPECTED_THUNDERBIRD_RECS_CONTRACT_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/thunderbird/recs_contract.txt"`
    export EXPECTED_MOCK_RUKH_APP_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/app.txt"`
    export EXPECTED_RUKH_RECS_CONTRACT_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/recs_contract.txt"`
    export EXPECTED_RUKH_DISPUTER_CONTRACT_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/disputer_contract.txt"`

    export EARLYBIRD_ENDPOINT_ADDRESS=$(<../addresses/$ENVIRONMENT/$CHAIN_NAME/endpoint.txt)
    export ORACLE_FEE_COLLECTOR_ADDRESS=$(<../addresses/$ENVIRONMENT/$CHAIN_NAME/oracleFeeCollector.txt)
    export RELAYER_FEE_COLLECTOR_ADDRESS=$(<../addresses/$ENVIRONMENT/$CHAIN_NAME/relayerFeeCollector.txt)

    if [[ -z $EARLYBIRD_ENDPOINT_ADDRESS || -z $ORACLE_ADDRESS || -z $RELAYER_ADDRESS || -z $ORACLE_FEE_COLLECTOR_ADDRESS || -z $RELAYER_FEE_COLLECTOR_ADDRESS ]]; then
        echo "env vars not set" && exit 1
    fi


    ########################################## DEPLOY THUNDERBIRD VERSION ##################################################
    forge script deploymentScripts/thunderbird/ThunderbirdRecsContract.s.sol:ThunderbirdRecsContractDeployment --rpc-url $RPC_URL --broadcast
    export THUNDERBIRD_RECS_CONTRACT_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/thunderbird/recs_contract.txt"`
    
    forge script --legacy deploymentScripts/thunderbird/mockThunderbirdApp.s.sol:MockThunderbirdAppDeployment --rpc-url $RPC_URL --broadcast

    
    ########################################## DEPLOY RUKH VERSION #########################################################
    forge script deploymentScripts/rukh/RukhRecsContract.s.sol:RukhRecsContractDeployment --rpc-url $RPC_URL --broadcast
    export RUKH_RECS_CONTRACT_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/recs_contract.txt"`
    
    forge script deploymentScripts/rukh/RukhDisputerContract.s.sol:RukhDisputerContractDeployment --rpc-url $RPC_URL --broadcast
    export RUKH_DISPUTER_CONTRACT_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/disputer_contract.txt"`

    forge script --legacy deploymentScripts/rukh/mockRukhApp.s.sol:MockRukhAppDeployment --rpc-url $RPC_URL --broadcast
done
