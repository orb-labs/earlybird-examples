############################################### SETTING ENVIRONMENT VARIABLES ##############################################

# set env vars if unset
: ${ENVIRONMENT:="local"}
export ENVIRONMENT

CHAIN_CONFIGS_DIRECTORY="environmentVariables/${ENVIRONMENT}"

for entry in "$CHAIN_CONFIGS_DIRECTORY"/*
do
    . "$entry"
    address_dir="../addresses/${ENVIRONMENT}/${CHAIN_NAME}"
    export MOCK_RUKH_APP_ADDRESS=$(<"${address_dir}/rukh/app.txt")
    forge script deploymentScripts/rukh/mockRukhApp.s.sol:MockRukhAppGetAllMessages --rpc-url $RPC_URL --broadcast
done