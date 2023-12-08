############################################### SETTING ENVIRONMENT VARIABLES ##############################################

# set env vars if unset
: ${ENVIRONMENT:="local"}

export ENVIRONMENT

: ${CHAINS_DIRECTORY:="environmentVariables/${ENVIRONMENT}"}

for entry in "$CHAINS_DIRECTORY"/*
do
    . "$entry"
    address_dir="../addresses/${ENVIRONMENT}/${CHAIN_NAME}"
    export MAGICLANE_MOCK_APP_ADDRESS=$(<"${address_dir}/magiclaneMockApp.txt")
    forge script deploymentScripts/MagiclaneMockApp.s.sol:MagiclaneMockAppGetAllMessages --rpc-url $RPC_URL --broadcast
done