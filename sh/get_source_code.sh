#!/bin/bash
set -e

# API keys for different networks
ETHERSCAN_API_KEY='VI1Q4M1M6XP2M5B648UIYR3JNVFE47KQW7'
BSCSCAN_API_KEY='GSWUVKIT9HZ28Y9TQEA1VZ6GH5S21MV812'
POLYGONSCAN_API_KEY='661P25T9WH169UD5VWIIG3SYX7E6XVJ2VK'
BASESCAN_API_KEY='A2XDTUCD1GXC1KC749NKQ3GD57QTJV6JR6'
LINEASCAN_API_KEY='B3GS3V4DV543W5GAG1VN1RT8626Z9JAAPU'
ARBITRUMSCAN_API_KEY='VD3HX86J6TITE1WVT9HEESQ7AIPE11MCI5'
SCROLLSCAN_API_KEY='29G1U3GQVYUHAB9HG98STRU3PB6PUXMD7U'
OPSCAN_API_KEY='CX9VVKT7G6CDM527KIXSDKQDZCUI5ZR9PU'
OPBNBSCAN_API_KEY='8417C2YNPY2V22R8SJY5EDMUDJ6MCXXTRF'
OPBNBSCAN_API_KEY_NODEREAL='6c9cda175e5a428d92682c4eac5069af'
TAIKOSCAN_API_KEY='NU11I5I1I36APW53D47RMMIT6WWCVEZY7E'
MANTLESCAN_API_KEY='IVP1X8CP1UN742D8WGSUU2XW9KXJQGMSBD'
MANTASCAN_API_KEY='IVP1X8CP1UN742D8WGSUU2XW9KXJQGMSBD'
MODESCAN_API_KEY=''  #null is ok
AVAXSCAN_API_KEY='' #null is ok
MNT_SCAN_API_KEY='' #null is ok
BITLAYER_SCAN_API_KEY='' #null is ok
FTM_SCAN_API_KEY='5VEVTEHGW7D17S4JNVCJZ2ZKTR5SFDQ3IB'
BLASTSCAN_API_KEY='4TNSUKDMZHYDKSZN63X8D2KKWPMTSGY7CN'
XLAYERSCAN_API_KEY='ad971a56-1334-40de-b341-530d841d38e5'
SONIC_SCAN_API_KEY=''  #null is ok

# Function to display usage information
usage() {
    echo "Usage: $0 CONTRACT_ADDRESS NETWORK"
    echo "Example: $0 0x1234abcd eth"
    echo "Supported networks: eth/mainnet, op/optimism, arb/arbitrum, poly/polygon, bsc, avax/avalanche, ftm/fantom, base, linea, scroll, opbnb, taiko, mantle, manta, mode, blast, xlayer/xchain, sonic"
    exit 1
}

# Check for correct number of arguments
if [ $# -ne 2 ]; then
    echo "Error: Incorrect number of arguments"
    usage
fi

# Parse command line arguments
IMPLEMENT=$1
NETWORK_INPUT=$2
NETWORK_REAL=$NETWORK_INPUT

# Convert network to lowercase for case-insensitive comparison
NETWORK_LOWER=$(echo "$NETWORK_INPUT" | tr '[:upper:]' '[:lower:]')

# Create source_code directory if it doesn't exist
mkdir -p ./source_code

# Map network aliases to standard names (foundry cast compatible names)
case "$NETWORK_LOWER" in
    "eth" | "ethereum")
        NETWORK_REAL="mainnet"
        NETWORK_FILE="ethereum"
        API_KEY=$ETHERSCAN_API_KEY
        ;;
    "op" | "optimism")
        NETWORK_REAL="optimism"
        NETWORK_FILE="optimism"
        API_KEY=$OPSCAN_API_KEY
        ;;
    "arb" | "arbitrum")
        NETWORK_REAL="arbitrum"
        NETWORK_FILE="arbitrum"
        API_KEY=$ARBITRUMSCAN_API_KEY
        ;;
    "poly" | "polygon")
        NETWORK_REAL="polygon"
        NETWORK_FILE="polygon"
        API_KEY=$POLYGONSCAN_API_KEY
        ;;
    "bsc" | "binance")
        NETWORK_REAL="bsc"
        NETWORK_FILE="bsc"
        API_KEY=$BSCSCAN_API_KEY
        ;;
    "avax" | "avalanche")
        NETWORK_REAL="avalanche"
        NETWORK_FILE="avalanche"
        API_KEY=$AVAXSCAN_API_KEY
        ;;
    "ftm" | "fantom")
        NETWORK_REAL="fantom"
        NETWORK_FILE="fantom"
        API_KEY=$FTM_SCAN_API_KEY
        ;;
    "base")
        NETWORK_REAL="base"
        NETWORK_FILE="base"
        API_KEY=$BASESCAN_API_KEY
        ;;
    "linea")
        NETWORK_REAL="linea"
        NETWORK_FILE="linea"
        API_KEY=$LINEASCAN_API_KEY
        ;;
    "scroll")
        NETWORK_REAL="scroll"
        NETWORK_FILE="scroll"
        API_KEY=$SCROLLSCAN_API_KEY
        ;;
    "opbnb")
        NETWORK_REAL="opbnb-mainnet"
        NETWORK_FILE="opbnb"
        API_KEY=$OPBNBSCAN_API_KEY
        ;;
    "taiko")
        NETWORK_REAL="taiko"
        NETWORK_FILE="taiko"
        API_KEY=$TAIKOSCAN_API_KEY
        ;;
    "mantle")
        NETWORK_REAL="mantle"
        NETWORK_FILE="mantle"
        API_KEY=$MANTLESCAN_API_KEY
        ;;
    "manta")
        NETWORK_FILE="manta"
        API_KEY=$MANTASCAN_API_KEY
        echo "Warning: 'manta' might not be directly supported by cast. Using API key but network might fail."
        ;;
    "mode")
        NETWORK_REAL="mode"
        NETWORK_FILE="mode"
        API_KEY=$MODESCAN_API_KEY
        ;;
    "blast")
        NETWORK_REAL="blast"
        NETWORK_FILE="blast"
        API_KEY=$BLASTSCAN_API_KEY
        ;;
    "xlayer" | "xchain")
        NETWORK_FILE="xlayer"
        API_KEY=$XLAYERSCAN_API_KEY
        echo "Warning: 'xlayer/xchain' might not be directly supported by cast. Using API key but network might fail."
        ;;
    "sonic")
        NETWORK_REAL="sonic"
        NETWORK_FILE="sonic"
        API_KEY=$SONIC_SCAN_API_KEY
        echo "Warning: 'sonic' might not be directly supported by cast. Using API key but network might fail."
        ;;
    *)
        echo "Error: Unsupported network: $NETWORK_INPUT"
        usage
        ;;
esac

# # Check if the API key is set (except for networks where null is ok)
# if [ -z "$API_KEY" ] && [ "$NETWORK_LOWER" != "mode" ] && [ "$NETWORK_LOWER" != "avalanche" ] && [ "$NETWORK_LOWER" != "mnt" ] && [ "$NETWORK_LOWER" != "bitlayer" ] && [ "$NETWORK_LOWER" != "sonic" ]; then
#     echo "Error: API key for network $NETWORK_INPUT is not set"
#     exit 1
# fi

echo "Fetching source code for contract $IMPLEMENT on $NETWORK_REAL..."
# Try with the -c flag first
if cast source "$IMPLEMENT" -c "$NETWORK_REAL" --etherscan-api-key "$API_KEY" -f > "./source_code/${NETWORK_FILE}_dexrouter.sol" 2>/dev/null; then
    echo "Source code saved to ./source_code/${NETWORK_FILE}_dexrouter.sol"
    exit 0
fi

# If the first attempt fails, try without the -c flag as a fallback
echo "Retrying without specifying network..."
if cast source "$IMPLEMENT" -c "$NETWORK_REAL" --etherscan-api-key "$API_KEY" -f > "./source_code/${NETWORK_FILE}_dexrouter.sol" 2>/dev/null; then
    echo "Source code saved to ./source_code/${NETWORK_FILE}_dexrouter.sol"
    exit 0
else
    echo "Failed to fetch source code. Make sure the contract address and network are correct."
    exit 1
fi