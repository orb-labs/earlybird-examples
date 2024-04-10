############################################### SETTING ENVIRONMENT VARIABLES ##############################################

# set env vars if unset
: ${ENVIRONMENT:="local"}
export ENVIRONMENT

CHAIN_CONFIGS_DIRECTORY="environmentVariables/${ENVIRONMENT}"

for entry in "$CHAIN_CONFIGS_DIRECTORY"/*
do
    . "$entry"
    address_dir="../addresses/${ENVIRONMENT}/${CHAIN_NAME}"
    export MAGICLANE_MOCK_APP_ADDRESS=$(<"${address_dir}/magiclaneMockApp.txt")
    forge script deploymentScripts/MagiclaneMockApp.s.sol:MagiclaneMockAppGetAllMessages --rpc-url $RPC_URL --broadcast
done