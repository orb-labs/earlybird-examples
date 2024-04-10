############################################### SETTING ENVIRONMENT VARIABLES ##############################################

# set env vars if unset
: ${ENVIRONMENT:="local"}
export ENVIRONMENT

CHAIN_CONFIGS_DIRECTORY="environmentVariables/${ENVIRONMENT}"
############################################## DEPLOY MOCK APP #############################################################
script_dir=`pwd`

for entry in "$CHAIN_CONFIGS_DIRECTORY"/*
do
    . "$entry"
    echo "\n\n########### mock_app $CHAIN_NAME ###########"
    
    chain_addresses_dir="../addresses/${ENVIRONMENT}/${CHAIN_NAME}"
    cd $chain_addresses_dir

    for e in "rukh" "thunderbird"; do
        echo "#### $e\n"
        if [[ ! -d $e ]]; then echo "$e dir not found at `pwd`" && exit 1; fi
        for f in `ls $e`; do echo "$f -- `cat $e/$f` \n"; done
    done
    cd $script_dir
done
