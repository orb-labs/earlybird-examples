############################################################# SETTING ENVIRONMENT VARIABLES ################################################################
if [ "$ENVIRONMENT" != "local" ]
then
    export MNEMONICS=`gcloud secrets versions access latest --secret=activity-runner-mnemonics`
fi

### set env vars if unset
: "${ENVIRONMENT:=local}" 
: "${CHAINS_DIRECTORY:=environmentVariables/$ENVIRONMENT}"
: "${KEY_INDEX:=0}"
: "${MNEMONICS:=test test test test test test test test test test test junk}"

export ENVIRONMENT KEY_INDEX 

for entry in "$CHAINS_DIRECTORY"/*
do
    . "$entry"
    export MOCK_THUNDERBIRD_APP_ADDRESS=$(<"../addresses/"$ENVIRONMENT"/"$CHAIN_NAME"/rukh/app.txt")
    forge script deploymentScripts/rukh/mockRukhApp.s.sol:MockRukhAppGetAllMessages --rpc-url $RPC_URL --broadcast
done