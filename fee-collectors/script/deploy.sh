############################################### SETTING ENVIRONMENT VARIABLES ##############################################

### set env vars if unset
: "${ENVIRONMENT:=testnet}" 
: "${CHAINS_DIRECTORY:=environmentVariables/$ENVIRONMENT}"
: "${KEY_INDEX:=0}"
: "${MNEMONICS:=test test test test test test test test test test test junk}"
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

    ########################################## GET EXISTING ADDRESSES ######################################################
    export EXPECTED_ORACLE_FEE_COLLECTOR_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/oracleFeeCollector.txt"`
    export EXPECTED_RELAYER_FEE_COLLECTOR_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/relayerFeeCollector.txt"`
    
    ########################################## DEPLOY ######################################################################
    forge script --legacy deploymentScripts/FeeCollectorsDeployment.s.sol:FeeCollectorsDeployment --rpc-url $RPC_URL --broadcast
    export ORACLE_FEE_COLLECTOR_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/oracleFeeCollector.txt"`
    export RELAYER_FEE_COLLECTOR_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/relayerFeeCollector.txt"`
    
    echo "
    deployed fee collectors on $CHAIN_NAME
    oracle fee collector = ${ORACLE_FEE_COLLECTOR_ADDRESS}
    relayer fee collector = ${RELAYER_FEE_COLLECTOR_ADDRESS}
    "
done
