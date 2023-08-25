############################################### SETTING ENVIRONMENT VARIABLES ##############################################

# Uncomment for local chains
export ENVIRONMENT=${ENVIRONMENT:-testnet}

chains_directory="environmentVariables/$ENVIRONMENT"

############################################## DEPLOY Mock APP #############################################################
for entry in "$chains_directory"/*
do
    . "$entry"
    
    echo "\n\n\n\n############ $CHAIN_NAME ###########"
    
    script_dir=`pwd`
    chain_dir="../addresses/$ENVIRONMENT/$CHAIN_NAME"

    cd $chain_dir
    for f in `ls`; do 
        if [[ $f == *"FeeCollector"* ]]; then
            echo "\n$f -- `cat $f`"; 
        fi
    done
    cd $script_dir
done
