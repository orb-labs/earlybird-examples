############################################### SETTING ENVIRONMENT VARIABLES ##############################################

# set env vars if unset
: ${ENVIRONMENT:="local"}
export ENVIRONMENT

CHAIN_CONFIGS_DIRECTORY="environmentVariables/${ENVIRONMENT}"

for entry in "$CHAIN_CONFIGS_DIRECTORY"/*
do
    . "$entry"
    address_dir="../addresses/${ENVIRONMENT}/${CHAIN_NAME}"
    export MOCK_THUNDERBIRD_APP_ADDRESS=$(<"${address_dir}/thunderbird/app.txt")
    forge script deploymentScripts/thunderbird/mockThunderbirdApp.s.sol:MockThunderbirdAppGetAllMessages --rpc-url $RPC_URL --broadcast
done