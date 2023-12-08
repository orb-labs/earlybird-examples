############################################### SETTING ENVIRONMENT VARIABLES ##############################################

: ${ENVIRONMENT:="local"}
: ${CHAINS_DIRECTORY:="environmentVariables/${ENVIRONMENT}"}

############################################## Get Addresses ###############################################################
script_dir=`pwd`

for entry in "$CHAINS_DIRECTORY"/*
do
    . "$entry"
    
    echo "\n\n\n\n############ magiclane-mockapp $CHAIN_NAME ###########"
    
    chain_addresses_dir="../addresses/$ENVIRONMENT/$CHAIN_NAME"
    cd $chain_addresses_dir

    for f in `ls`; do 
        if [[ $f == *"MagiclaneMockApp"* ]]; then
            echo "\n$f -- `cat $f`"; 
        fi
    done
    cd $script_dir
done
