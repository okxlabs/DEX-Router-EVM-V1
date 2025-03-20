#!/bin/bash
set -e

# Function to display usage information
usage() {
    echo "Usage: $0 CONTRACT_ADDRESS NETWORK"
    echo "Example: $0 0x1234abcd eth"
    echo "Supported networks: eth/ethereum, bsc/binance, polygon, arbitrum, optimism, avalanche, fantom, base, linea, zksync, scroll, opbnb, mantle, zora"
    echo ""
    echo "Note: You must have an OKLINK_API_KEY in your .env file. See scripts/README_oklink_setup.md for instructions."
    exit 1
}

# Check for correct number of arguments
if [ $# -ne 2 ]; then
    echo "Error: Incorrect number of arguments"
    usage
fi

# Parse command line arguments
CONTRACT_ADDRESS=$1
NETWORK=$2

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if .env file exists
ENV_FILE="$PROJECT_ROOT/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    echo "Please create a .env file with your OKLINK_API_KEY. See scripts/README_oklink_setup.md for instructions."
    exit 1
fi

# Check if OKLINK_API_KEY is set in .env
if ! grep -q "OKLINK_API_KEY" "$ENV_FILE" || ! grep -q "OKLINK_API_KEY=.*[^[:space:]]" "$ENV_FILE"; then
    echo "Error: OKLINK_API_KEY not found or empty in .env file"
    echo "Please set your OKLINK_API_KEY in the .env file. See scripts/README_oklink_setup.md for instructions."
    exit 1
fi

# Run the JavaScript script
cd "$PROJECT_ROOT"
node ./scripts/oklink_get_source_code.js "$CONTRACT_ADDRESS" "$NETWORK"

# Check the result
if [ $? -eq 0 ]; then
    echo "Success! Source code for $CONTRACT_ADDRESS on $NETWORK network has been retrieved."
    ls -la "./source_code/${NETWORK}_${CONTRACT_ADDRESS}.sol"
else
    echo "Failed to retrieve source code for $CONTRACT_ADDRESS on $NETWORK network."
    echo "Please check your API key and contract address."
    exit 1
fi
