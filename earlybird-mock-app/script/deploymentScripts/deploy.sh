# export LOCAL_ADDRESSES_DIRECTORY="../addresses"
# export LOCAL_ADDRESSES_DIRECTORY_FOR_ENVIRONMENT="$LOCAL_ADDRESSES_DIRECTORY/${ENVIRONMENT}"
# ############################################## Helper Functions ############################################################

# address_from_filepath() {
#     path=$1
#     if [ -f $path ]
#     then
#         address=$(<$path)
#     else
#         address="0x0000000000000000000000000000000000000000"
#     fi
#     echo $address
# }

# ############################################################################################################################
# if [[ -z $GLOBAL_ADDRESSES_DIRECTORY || -z $CHAIN_CONFIGS_DIRECTORY || -z $ENVIRONMENT || -z $KEY_INDEX || -z $MNEMONICS ]]; then echo "env vars unset" && exit 1;fi

# # create local address directory
# if [[ ! -d $LOCAL_ADDRESSES_DIRECTORY ]]; then mkdir $LOCAL_ADDRESSES_DIRECTORY; fi

# # create local address directory for environment
# if [[ ! -d $LOCAL_ADDRESSES_DIRECTORY_FOR_ENVIRONMENT ]]; then mkdir $LOCAL_ADDRESSES_DIRECTORY_FOR_ENVIRONMENT; fi

# # create global address directory
# if [[ ! -d $GLOBAL_ADDRESSES_DIRECTORY ]]; then mkdir $GLOBAL_ADDRESSES_DIRECTORY; fi

# # create global address directory for environment
# if [[ ! -d $GLOBAL_ADDRESSES_DIRECTORY_FOR_ENVIRONMENT ]]; then mkdir $GLOBAL_ADDRESSES_DIRECTORY_FOR_ENVIRONMENT; fi

# # the deploy will run for each file in the chains directory, 
# # all of which should be shell scripts that set env vars specific to the chain
# # the filename should be the chain name
# for entry in "$CHAIN_CONFIGS_DIRECTORY/activeChains"/*
# do
#     # run script in environmentVariables/ to set env vars for the chain
#     . "$entry"
#     echo "\n============================ Deploying Earlybird Mock App on: $CHAIN_NAME ============================\n"

#     # chain-specific idiosyncracies
#     if [[ $CHAIN_NAME == "moonbeam_alpha_testnet" ]]; then SKIP_SIMULATION="--skip-simulation"; else SKIP_SIMULATION=""; fi

#     ########################################## GET EXISTING ADDRESSES ######################################################
#     # create local directory for chain
#     local_address_dir_path_for_chain="$LOCAL_ADDRESSES_DIRECTORY_FOR_ENVIRONMENT/${CHAIN_NAME}"
#     if [[ ! -d $local_address_dir_path_for_chain ]]; then mkdir $local_address_dir_path_for_chain; fi

#     # create global directory for chain
#     global_address_dir_path_for_chain="$GLOBAL_ADDRESSES_DIRECTORY_FOR_ENVIRONMENT/${CHAIN_NAME}"
#     if [[ ! -d $global_address_dir_path_for_chain ]]; then mkdir $global_address_dir_path_for_chain; fi
    
#     # get existing addresses of mock app if previously deployed to this chain
#     export EXPECTED_MOCK_THUNDERBIRD_V1_APP_ADDRESS=`address_from_filepath "$global_address_dir_path_for_chain/mockThunderbirdV1App.txt"`
#     export EXPECTED_MOCK_THUNDERBIRD_V1_RECS_CONTRACT_ADDRESS=`address_from_filepath "$global_address_dir_path_for_chain/mockThunderbirdV1RecsContract.txt"`
#     export EXPECTED_MOCK_RUKH_V1_APP_ADDRESS=`address_from_filepath "$global_address_dir_path_for_chain/mockRukhV1App.txt"`
#     export EXPECTED_MOCK_RUKH_V1_RECS_CONTRACT_ADDRESS=`address_from_filepath "$global_address_dir_path_for_chain/mockRukhV1RecsContract.txt"`
    
#     # get existing addresses of earlybird endpoint
#     export EARLYBIRD_ENDPOINT_ADDRESS=$(<${global_address_dir_path_for_chain}/earlybirdEndpoint.txt)
#     if [[ -z $EARLYBIRD_ENDPOINT_ADDRESS ]]; then echo "endpoint not set" && exit 2; fi

#     # get existing addresses of oracle and relayer
#     # previously deployed to this chain (must exist)
#     export ORACLE_ADDRESS=$(<${global_address_dir_path_for_chain}/oracle.txt)
#     export RELAYER_ADDRESS=$(<${global_address_dir_path_for_chain}/relayer.txt)
#     export RUKH_DISPUTER_CONTRACT_ADDRESS=$(<${global_address_dir_path_for_chain}/disputerContract.txt)
#     export RUKH_DISPUTE_RESOLVER_CONTRACT_ADDRESS=$(<${global_address_dir_path_for_chain}/disputeResolverContract.txt)
#     if [[ -z $ORACLE_ADDRESS || -z $RELAYER_ADDRESS || -z $RUKH_DISPUTER_CONTRACT_ADDRESS || -z $RUKH_DISPUTE_RESOLVER_CONTRACT_ADDRESS ]]; then echo "periphery contracts are not set" && exit 2; fi

#     ########################################## DEPLOY THUNDERBIRD VERSION ##################################################
    
#     # deploy recs contract
#     forge script --legacy $SKIP_SIMULATION deploymentScripts/mockThunderbirdV1RecsContract.s.sol:MockThunderbirdV1RecsContractDeployment --rpc-url $RPC_URL --broadcast
#     ### assume the address has been written by the script and read from it
#     export MOCK_THUNDERBIRD_V1_RECS_CONTRACT_ADDRESS=$(<$local_address_dir_path_for_chain/mockThunderbirdV1RecsContract.txt)
    
#     # deploy mock app
#     forge script --legacy --skip-simulation deploymentScripts/mockThunderbirdV1App.s.sol:MockThunderbirdV1AppDeployment --rpc-url $RPC_URL --broadcast
#     export MOCK_THUNDERBIRD_V1_APP_ADDRESS=$(<$local_address_dir_path_for_chain/mockThunderbirdV1App.txt)

#     # update configs for mock app
#     forge script --legacy --skip-simulation deploymentScripts/mockThunderbirdV1App.s.sol:MockThunderbirdV1AppConfigsUpdate --rpc-url $RPC_URL --broadcast
    
#     ########################################## DEPLOY RUKH VERSION ######################################################### 
    
#     # deploy recs contract
#     forge script --legacy $SKIP_SIMULATION deploymentScripts/mockRukhV1RecsContract.s.sol:MockRukhV1RecsContractDeployment --rpc-url $RPC_URL --broadcast
#     ### assume the address has been written by the script and read from it
#     export MOCK_RUKH_V1_RECS_CONTRACT_ADDRESS=$(<$local_address_dir_path_for_chain/mockRukhV1RecsContract.txt)
    
#     # deploy mock app
#     forge script --legacy --skip-simulation deploymentScripts/mockRukhV1App.s.sol:MockRukhV1AppDeployment --rpc-url $RPC_URL --broadcast
#     export MOCK_RUKH_V1_APP_ADDRESS=$(<$local_address_dir_path_for_chain/mockRukhV1App.txt)

#     # update configs for mock app
#     forge script --legacy --skip-simulation deploymentScripts/mockRukhV1App.s.sol:MockRukhV1AppConfigsUpdate --rpc-url $RPC_URL --broadcast
# done

# # migrate the written addresses from the local to the global addresses directory
# echo "migrating local address directory"
# cp -R $LOCAL_ADDRESSES_DIRECTORY_FOR_ENVIRONMENT/. $GLOBAL_ADDRESSES_DIRECTORY_FOR_ENVIRONMENT/
# rm -rf $LOCAL_ADDRESSES_DIRECTORY
# echo "local address directory migrated"