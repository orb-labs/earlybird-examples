############################################### SETTING ENVIRONMENT VARIABLES ##############################################

### set env vars if unset
: "${ENVIRONMENT:=local}" 

chains_directory="environmentVariables/$ENVIRONMENT"

############################################## DEPLOY MOCK APP #############################################################
for entry in "$chains_directory"/*
do
    . "$entry"
    echo "\n\n########### mock_app $CHAIN_NAME ###########"
    
    script_dir=`pwd`
    chain_addresses_dir="../addresses/$ENVIRONMENT/$CHAIN_NAME"
    cd $chain_addresses_dir

    for e in "rukh" "thunderbird"; do
        echo "#### $e\n"
        for f in `ls $e`; do echo "$f -- `cat $e/$f` \n"; done
    done
    cd $script_dir
done
