############################################### SETTING ENVIRONMENT VARIABLES ##############################################

# Uncomment for local chains
export ENVIRONMENT=${ENVIRONMENT:-local}

# Uncomment for public testnet
# export ENVIRONMENT="testnet"

# Uncomment for mainnet
# export ENVIRONMENT="mainnet"

chains_directory="environmentVariables/$ENVIRONMENT"

export KEY_INDEX=3

export MNEMONICS="test test test test test test test test test test test junk"

if [ "$ENVIRONMENT" != "local" ]
then
    export MNEMONICS=$(op read "op://Private/Deployment/Mnemonic_phrase/"$ENVIRONMENT"")
    export KEY_INDEX=0
fi

############################################## Helper Functions ############################################################

address_from_filepath() {
    existing_address_path=$1
    if [ -f $existing_address_path ]
    then
        address=$(<$existing_address_path)
    else
        address="0x0000000000000000000000000000000000000000"
    fi
    echo $address
}
