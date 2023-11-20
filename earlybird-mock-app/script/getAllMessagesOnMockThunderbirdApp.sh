############################################################# SETTING ENVIRONMENT VARIABLES ################################################################
### set env vars if unset
: "${ENVIRONMENT:=local}" 
: "${CHAINS_DIRECTORY:=environmentVariables/$ENVIRONMENT}"
: "${KEY_INDEX:=0}"

export ENVIRONMENT KEY_INDEX 

for entry in "$CHAINS_DIRECTORY"/*
do
    . "$entry"
    export MOCK_THUNDERBIRD_APP_ADDRESS=$(<"../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/thunderbird/app.txt")
    forge script deploymentScripts/thunderbird/mockThunderbirdApp.s.sol:MockThunderbirdAppGetAllMessages --rpc-url $RPC_URL --broadcast
done