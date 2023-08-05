. ./setup.sh

############################################################################################################################

for entry in "$chains_directory"/*
do
    . "$entry"

    ########################################## GET EXISTING ADDRESSES ######################################################
    export EXPECTED_ORACLE_FEE_COLLECTOR_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/oracleFeeCollector.txt"`
    export EXPECTED_RELAYER_FEE_COLLECTOR_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/relayerFeeCollector.txt"`
    
    ########################################## DEPLOY ######################################################################
    forge script deploymentScripts/feeCollectors/SendingOracle.s.sol:SendingOracleDeployment --rpc-url $RPC_URL --broadcast
    export ORACLE_FEE_COLLECTOR_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/oracleFeeCollector.txt"`
    export RELAYER_FEE_COLLECTOR_ADDRESS=`address_from_filepath "../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/relayerFeeCollector.txt"`
    
    echo "
    deployed fee collectors on $CHAIN_NAME
    oracle fee collector = ${ORACLE_FEE_COLLECTOR_ADDRESS}
    relayer fee collector = ${RELAYER_FEE_COLLECTOR_ADDRESS}
    "
done
