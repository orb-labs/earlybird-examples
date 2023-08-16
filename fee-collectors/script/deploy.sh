. ./setup.sh

export MNEMONICS=`gcloud secrets versions access latest --secret=activity-runner-mnemonics`
export KEY_INDEX=0

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
