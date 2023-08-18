############################################### SETTING ENVIRONMENT VARIABLES ##############################################

# Uncomment for local chains
export ENVIRONMENT=${ENVIRONMENT:-testnet}

# Uncomment for public testnet
# export ENVIRONMENT="testnet"

# Uncomment for mainnet
# export ENVIRONMENT="mainnet"

chains_directory="environmentVariables/$ENVIRONMENT"

############################################## DEPLOY EARLYBIRD ############################################################
for entry in "$chains_directory"/*
do
    . "$entry"
    echo "\n\n\n\n ############ $CHAIN_NAME ###########"
    for d in `ls ../addresses/$ENVIRONMENT/$CHAIN_NAME`; do
        echo
        echo $d
        for f in `ls ../addresses/$ENVIRONMENT/$CHAIN_NAME/$d`; do echo "\n $f" && cat ../addresses/$ENVIRONMENT/$CHAIN_NAME/$d/$f && echo; done
    done
done
