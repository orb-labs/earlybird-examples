############################################### SETTING ENVIRONMENT VARIABLES ##############################################

# set env vars if unset
### default environment
: ${ENVIRONMENT:="local"}

case $ENVIRONMENT in
    mainnet)
        : ${MNEMONICS:=`gcloud secrets versions access latest --secret=activity-runner-mnemonics`}
        ;;
    testnet)
        : ${MNEMONICS:=`gcloud secrets versions access latest --secret=activity-runner-mnemonics`}
        : ${RUKH_DISPUTER_CONTRACT_ADDRESS:="0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f"}
        : ${RUKH_DISPUTE_RESOLVER_CONTRACT_ADDRESS:="0x5B18a2DdF5E71013DA70D5737EDe125f6d809fE9"}
        ;;
    local)
        : ${MNEMONICS:="test test test test test test test test test test test junk"}
        : ${RUKH_DISPUTER_CONTRACT_ADDRESS:="0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f"}
        : ${RUKH_DISPUTE_RESOLVER_CONTRACT_ADDRESS:="0x5B18a2DdF5E71013DA70D5737EDe125f6d809fE9"}
        ;;
    *)
        echo "invalid environment" && exit 1
        ;;
esac

### other env vars
: ${CHAINS_DIRECTORY:="environmentVariables/${ENVIRONMENT}"}
: ${KEY_INDEX:="0"}
: ${ORACLE_MNEMONICS:="$MNEMONICS"}
: ${ORACLE_KEY_INDEX:="0"}
: ${RELAYER_MNEMONICS:="$MNEMONICS"}
: ${RELAYER_KEY_INDEX:="1"}

# export env vars needed by the Solidity scripts
export ENVIRONMENT KEY_INDEX MNEMONICS ORACLE_MNEMONICS ORACLE_KEY_INDEX RELAYER_MNEMONICS RELAYER_KEY_INDEX RUKH_DISPUTER_CONTRACT_ADDRESS RUKH_DISPUTE_RESOLVER_CONTRACT_ADDRESS

############################################## Helper Functions ############################################################

address_from_filepath() {
    path=$1
    if [ -f $path ]
    then
        address=$(<$path)
    else
        address="0x0000000000000000000000000000000000000000"
    fi
    echo $address
}

############################################################################################################################
if [[ -z $CHAINS_DIRECTORY ]]; then echo "env vars unset" && exit 1;fi
for entry in "$CHAINS_DIRECTORY"/*
do
    # run script in environmentVariables/ to set env vars for the chain
    . "$entry"

    ########################################## GET EXISTING ADDRESSES ######################################################
    address_dir_path="../addresses/"${ENVIRONMENT}"/"${CHAIN_NAME}""
    if [[ ! -d $address_dir_path ]]; then echo "address directory not found at $address_dir_path" && exit 1; fi
    
    # get existing addresses of mock app if previously deployed to this chain
    export EXPECTED_MOCK_THUNDERBIRD_APP_ADDRESS=`address_from_filepath "$address_dir_path/thunderbird/app.txt"`
    export EXPECTED_THUNDERBIRD_RECS_CONTRACT_ADDRESS=`address_from_filepath "$address_dir_path/thunderbird/recs_contract.txt"`
    export EXPECTED_MOCK_RUKH_APP_ADDRESS=`address_from_filepath "$address_dir_path/rukh/app.txt"`
    export EXPECTED_RUKH_RECS_CONTRACT_ADDRESS=`address_from_filepath "$address_dir_path/rukh/recs_contract.txt"`
    
    # get existing addresses of earlybird, fee collectors, and periphery contracts
    # previously deployed to this chain (must exist)
    export EARLYBIRD_ENDPOINT_ADDRESS=$(<${address_dir_path}/earlybird-evm/endpoint.txt)
    export ORACLE_FEE_COLLECTOR_ADDRESS=$(<${address_dir_path}/fee-collectors/oracleFeeCollector.txt)
    export RELAYER_FEE_COLLECTOR_ADDRESS=$(<${address_dir_path}/fee-collectors/relayerFeeCollector.txt)
    export ORACLE_ADDRESS=$(<${address_dir_path}/periphery-contracts/oracle.txt)
    export RELAYER_ADDRESS=$(<${address_dir_path}/periphery-contracts/relayer.txt)
    
    # error and exit if missing any dependencies
    if [[ -z $EARLYBIRD_ENDPOINT_ADDRESS ]]; then echo "endpoint not set" && exit 2; fi
    if [[ -z $ORACLE_ADDRESS || -z $RELAYER_ADDRESS ]]; then echo "oracle and relayer not set" && exit 2; fi
    if [[ -z $ORACLE_FEE_COLLECTOR_ADDRESS || -z $RELAYER_FEE_COLLECTOR_ADDRESS ]]; then echo "fee collectors not set" && exit 2; fi

    ########################################## DEPLOY THUNDERBIRD VERSION ##################################################
    forge script --legacy --skip-simulation deploymentScripts/thunderbird/ThunderbirdRecsContract.s.sol:ThunderbirdRecsContractDeployment --rpc-url $RPC_URL --broadcast
    # assume the address has been written by the script and read from it
    export THUNDERBIRD_RECS_CONTRACT_ADDRESS=$(<$address_dir_path/thunderbird/recs_contract.txt)
    
    forge script --legacy --skip-simulation deploymentScripts/thunderbird/mockThunderbirdApp.s.sol:MockThunderbirdAppDeployment --rpc-url $RPC_URL --broadcast

    
    ########################################## DEPLOY RUKH VERSION ######################################################### 
    forge script --legacy --skip-simulation deploymentScripts/rukh/RukhRecsContract.s.sol:RukhRecsContractDeployment --rpc-url $RPC_URL --broadcast
    # assume the address has been written by the script and read from it
    export RUKH_RECS_CONTRACT_ADDRESS=$(<$address_dir_path/rukh/recs_contract.txt)
    
    forge script --legacy --skip-simulation deploymentScripts/rukh/mockRukhApp.s.sol:MockRukhAppDeployment --rpc-url $RPC_URL --broadcast
done
