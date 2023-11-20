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
: "${ORACLE_ADDRESS:=0xE728d9a67E11549Fed17A0D33618151008AFcc32}"
: "${RELAYER_ADDRESS:=0xfD18b8aeA6a1e18E4B7BaaB667A78C7c60DBc987}"

if [ $ENVIRONMENT == "local" ]; then
    export ORACLE_ADDRESS="0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
    export RELAYER_ADDRESS="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"
else
    export ORACLE_ADDRESS="0xE728d9a67E11549Fed17A0D33618151008AFcc32"
    export RELAYER_ADDRESS="0xfD18b8aeA6a1e18E4B7BaaB667A78C7c60DBc987"
fi

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

    export EARLYBIRD_ENDPOINT_ADDRESS=$(<../addresses/$ENVIRONMENT/$CHAIN_NAME/earlybird-evm/endpoint.txt)
    export ORACLE_FEE_COLLECTOR_ADDRESS=$(<../addresses/$ENVIRONMENT/$CHAIN_NAME/fee-collectors/oracleFeeCollector.txt)
    export RELAYER_FEE_COLLECTOR_ADDRESS=$(<../addresses/$ENVIRONMENT/$CHAIN_NAME/fee-collectors/relayerFeeCollector.txt)

    if [[ -z $EARLYBIRD_ENDPOINT_ADDRESS ]]; then echo "endpoint not set" && exit 2; fi
    if [[ -z $ORACLE_ADDRESS || -z $RELAYER_ADDRESS ]]; then echo "oracle and relayer not set" && exit 2; fi
    if [[ -z $ORACLE_FEE_COLLECTOR_ADDRESS || -z $RELAYER_FEE_COLLECTOR_ADDRESS ]]; then echo "fee collectors not set" && exit 2; fi

    ########################################## DEPLOY THUNDERBIRD VERSION ##################################################
    forge script deploymentScripts/thunderbird/ThunderbirdRecsContract.s.sol:ThunderbirdRecsContractDeployment --rpc-url $RPC_URL --broadcast
    export THUNDERBIRD_RECS_CONTRACT_ADDRESS=$(<../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/thunderbird/recs_contract.txt)
    
    forge script --legacy deploymentScripts/thunderbird/mockThunderbirdApp.s.sol:MockThunderbirdAppDeployment --rpc-url $RPC_URL --broadcast

    
    ########################################## DEPLOY RUKH VERSION #########################################################
    forge script deploymentScripts/rukh/RukhRecsContract.s.sol:RukhRecsContractDeployment --rpc-url $RPC_URL --broadcast
    export RUKH_RECS_CONTRACT_ADDRESS=$(<../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/recs_contract.txt)
    
    forge script deploymentScripts/rukh/RukhDisputerContract.s.sol:RukhDisputerContractDeployment --rpc-url $RPC_URL --broadcast
    export RUKH_DISPUTER_CONTRACT_ADDRESS=$(<../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/disputer_contract.txt)

    forge script --legacy deploymentScripts/rukh/mockRukhApp.s.sol:MockRukhAppDeployment --rpc-url $RPC_URL --broadcast
done
