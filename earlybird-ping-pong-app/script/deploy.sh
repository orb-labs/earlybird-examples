############################################## Helper Functions #########################################################################################

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


############################################## GET EXISTING ADDRESSES ############################################################

export EXPECTED_RUKH_VERSION_PINGPONG_DISPUTER_CONTRACT_ADDRESS=`address_from_filepath "addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/disputer_contract.txt"`
export EXPECTED_RUKH_VERSION_PINGPONG_APP_ADDRESS=`address_from_filepath "addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/app.txt"`
export EXPECTED_THUNDERBIRD_VERSION_PINGPONG_APP_ADDRESS=`address_from_filepath "addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/app.txt"`

############################################## DEPLOYING RukhVersion PingPong App TO CHAINS ############################################################
for entry in "$CHAIN_CONFIGS_DIRECTORY"/*
do
    # run scripts in environmentVariables/ to set env vars for the chain
    . "$entry"

    # # deploy rukh disputer contract
    export EXPECTED_RUKH_VERSION_PINGPONG_DISPUTER_CONTRACT_ADDRESS=`address_from_filepath "addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/disputer_contract.txt"`
    forge script deploymentScripts/rukh/DisputerContract.s.sol:DisputerContractDeployment --rpc-url $RPC_URL --broadcast
    export RUKH_VERSION_PINGPONG_DISPUTER_CONTRACT_ADDRESS=`address_from_filepath "addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/disputer_contract.txt"`
    
    # deploy rukh app
    export EXPECTED_RUKH_VERSION_PINGPONG_APP_ADDRESS=`address_from_filepath "addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/app.txt"`
    forge script deploymentScripts/rukh/PingPong.s.sol:PingPongRukhDeployment --rpc-url $RPC_URL --broadcast
    
    # deploy thunderbird app
    export EXPECTED_THUNDERBIRD_VERSION_PINGPONG_APP_ADDRESS=`address_from_filepath "addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/app.txt"`
    forge script deploymentScripts/thunderbird/PingPong.s.sol:PingPongThunderbirdDeployment --rpc-url $RPC_URL --broadcast
done
