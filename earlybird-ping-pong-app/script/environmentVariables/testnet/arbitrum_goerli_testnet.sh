export CHAIN_NAME="Arbitrum Goerli Testnet"
export CHAIN_ID="421613"
export EARLYBIRD_ENDPOINT_ADDRESS="0x73dDC9B2dDa8117B5Be3be2831bBbDEaA3594173"

# RPC_URL from arbiscan
export RPC_URL=`gcloud secrets versions access latest --secret=arb-goerli-rpc`