############################################### SETTING ENVIRONMENT VARIABLES ##############################################

# set env vars if unset
: ${ENVIRONMENT:="local"}
export ENVIRONMENT

export DEPLOYMENT_CONFIGS_DIRECTORY="`pwd`/../../../../deployment-configs/${ENVIRONMENT}"

for entry in "$DEPLOYMENT_CONFIGS_DIRECTORY/chains/activeChains"/*
do
    . "$entry"
    export CHAIN_FILE_PATH="`pwd`/../../../../deployment-addresses/${ENVIRONMENT}/${CHAIN_NAME}.json"
    export CHAIN_NAME=$CHAIN_NAME

    # read the messages
    node getAllMessagesOnMockMagiclaneApp.js
done