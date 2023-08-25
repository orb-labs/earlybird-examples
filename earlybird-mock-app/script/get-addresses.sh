############################################### SETTING ENVIRONMENT VARIABLES ##############################################

# Uncomment for local chains
export ENVIRONMENT=${ENVIRONMENT:-testnet}

chains_directory="environmentVariables/$ENVIRONMENT"

############################################## DEPLOY MOCK APP #############################################################
for entry in "$chains_directory"/*
do
    . "$entry"
    echo "\n\n\n\n############ $CHAIN_NAME ###########"
    
    script_dir=`pwd`
    chain_dir="../addresses/$ENVIRONMENT/$CHAIN_NAME"
    cd $chain_dir

    for e in "rukh" "thunderbird"; do
        echo "\n#### $e"
        for f in `ls $e`; do echo "\n$f -- `cat $e/$f`"; done
    done
    cd $script_dir
done
