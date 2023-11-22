############################################### SETTING ENVIRONMENT VARIABLES ##############################################

if [ "$ENVIRONMENT" == "mainnet" ]
then
    export MNEMONICS=`gcloud secrets versions access latest --secret=activity-runner-mnemonics`

elif [ "$ENVIRONMENT" == "testnet" ]
then
    export MNEMONICS=`gcloud secrets versions access latest --secret=activity-runner-mnemonics`
elif [ "$ENVIRONMENT" == "local" ]
then
    export MNEMONICS="test test test test test test test test test test test junk"
else
    echo "invalid environment" && exit 1
fi

### set env vars if unset
: "${ENVIRONMENT:=local}" 
: "${CHAINS_DIRECTORY:=environmentVariables/$ENVIRONMENT}"
: "${KEY_INDEX:=0}"
: "${ORACLE_MNEMONICS:=$MNEMONICS}"
: "${ORACLE_KEY_INDEX:=0}"
: "${RELAYER_MNEMONICS:=$MNEMONICS}"
: "${RELAYER_KEY_INDEX:=1}"
: "${DISPUTE_RESOLVER_MNEMONICS:=$MNEMONICS}"
: "${DISPUTE_RESOLVER_KEY_INDEX:=10}"

export ENVIRONMENT KEY_INDEX MNEMONICS ORACLE_MNEMONICS ORACLE_KEY_INDEX RELAYER_MNEMONICS RELAYER_KEY_INDEX DISPUTE_RESOLVER_MNEMONICS DISPUTE_RESOLVER_KEY_INDEX

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

for entry in "$CHAINS_DIRECTORY"/*
do
    . "$entry"

    ########################################## GET EXISTING ADDRESSES ######################################################
    existing_addresses_path="../addresses/"$ENVIRONMENT"/"$CHAIN_NAME""
    export EXPECTED_MOCK_THUNDERBIRD_APP_ADDRESS=`address_from_filepath "$existing_addresses_path/thunderbird/app.txt"`
    export EXPECTED_THUNDERBIRD_RECS_CONTRACT_ADDRESS=`address_from_filepath "$existing_addresses_path/thunderbird/recs_contract.txt"`
    export EXPECTED_MOCK_RUKH_APP_ADDRESS=`address_from_filepath "$existing_addresses_path/rukh/app.txt"`
    export EXPECTED_RUKH_RECS_CONTRACT_ADDRESS=`address_from_filepath "$existing_addresses_path/rukh/recs_contract.txt"`
    export EXPECTED_RUKH_DISPUTER_CONTRACT_ADDRESS=`address_from_filepath "$existing_addresses_path/rukh/disputer_contract.txt"`

    export EARLYBIRD_ENDPOINT_ADDRESS=$(<${existing_addresses_path}/earlybird-evm/endpoint.txt)
    export ORACLE_FEE_COLLECTOR_ADDRESS=$(<${existing_addresses_path}/fee-collectors/oracleFeeCollector.txt)
    export RELAYER_FEE_COLLECTOR_ADDRESS=$(<${existing_addresses_path}/fee-collectors/relayerFeeCollector.txt)
    export ORACLE_ADDRESS=$(<${existing_addresses_path}/periphery-contracts/oracle.txt)
    export RELAYER_ADDRESS=$(<${existing_addresses_path}/periphery-contracts/relayer.txt)
    

    if [[ -z $EARLYBIRD_ENDPOINT_ADDRESS ]]; then echo "endpoint not set" && exit 2; fi
    if [[ -z $ORACLE_ADDRESS || -z $RELAYER_ADDRESS ]]; then echo "oracle and relayer not set" && exit 2; fi
    if [[ -z $ORACLE_FEE_COLLECTOR_ADDRESS || -z $RELAYER_FEE_COLLECTOR_ADDRESS ]]; then echo "fee collectors not set" && exit 2; fi

    ########################################## DEPLOY THUNDERBIRD VERSION ##################################################
    forge script --legacy deploymentScripts/thunderbird/ThunderbirdRecsContract.s.sol:ThunderbirdRecsContractDeployment --rpc-url $RPC_URL --broadcast
    export THUNDERBIRD_RECS_CONTRACT_ADDRESS=$(<$existing_addresses_path/thunderbird/recs_contract.txt)
    
    forge script --legacy deploymentScripts/thunderbird/mockThunderbirdApp.s.sol:MockThunderbirdAppDeployment --rpc-url $RPC_URL --broadcast

    
    ########################################## DEPLOY RUKH VERSION #########################################################
    forge script --legacy deploymentScripts/rukh/RukhRecsContract.s.sol:RukhRecsContractDeployment --rpc-url $RPC_URL --broadcast
    export RUKH_RECS_CONTRACT_ADDRESS=$(<$existing_addresses_path/rukh/recs_contract.txt)
    
    forge script --legacy deploymentScripts/rukh/RukhDisputerContract.s.sol:RukhDisputerContractDeployment --rpc-url $RPC_URL --broadcast
    export RUKH_DISPUTER_CONTRACT_ADDRESS=$(<$existing_addresses_path/rukh/disputer_contract.txt)

    forge script --legacy deploymentScripts/rukh/mockRukhApp.s.sol:MockRukhAppDeployment --rpc-url $RPC_URL --broadcast
done
