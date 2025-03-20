#!/bin/bash
set -e

# Create source_code directory if it doesn't exist
mkdir -p ./source_code

# Function to clean contract addresses (remove quotes and whitespace)
clean_address() {
    # Remove quotes, newlines, and trim whitespace
    echo "$1" | tr -d '"' | tr -d '\n' | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

# Array of network and contract address pairs
declare -a CONTRACT_PAIRS=(
    "ETH 0x9B2Bb833332F7b052e785bdBDD996058df9a6523"
    "ARB 0x254ba2726746134b890c3f504c57f1ee84ba5279"
    "BSC 0xd34c7d712d443f0b9ac93b3bc4f6fe053e3a2005"
    "BASE 0x571eacf92d6383c4b3371a3c01c6c480e3a736fe"
    "OP 0x2a575020086218f336baacc0c1094e23d69333bc"
    "POLYGON 0x6536b604eb20e457af8de8fde54d330c7c69e895"
    "AVAX 0x7b7D82c6a11F8cA724E5E0d3b003C5D3DB520706"
    "FTM 0x7b7D82c6a11F8cA724E5E0d3b003C5D3DB520706"
    "LINEA 0x4f06a83a803029b3f01c401f2d8b8e82f099f3d4"
    "MANTLE 0xa615De0E6e48257a3bfB6CAa995A66c7Cd4Fc048"
    "SCROLL 0x7b7d82c6a11f8ca724e5e0d3b003c5d3db520706"
    "MANTA 0x7b7d82c6a11f8ca724e5e0d3b003c5d3db520706"
    "METIS 0xa615De0E6e48257a3bfB6CAa995A66c7Cd4Fc048"
    "BLAST 0x7b7d82c6a11f8ca724e5e0d3b003c5d3db520706"
    "MODE 0x7b7D82c6a11F8cA724E5E0d3b003C5D3DB520706"
    "XLAYER 0x7b7d82c6a11f8ca724e5e0d3b003c5d3db520706"
    "SONIC 0x2FFb79c1d954c58a280ef3A7484263d747d9c737"
)

# Log file for results
LOG_FILE="./source_code/fetch_results.log"
echo "Starting contract fetching at $(date)" > "$LOG_FILE"
echo "----------------------------------------" >> "$LOG_FILE"

# Process each pair
for PAIR in "${CONTRACT_PAIRS[@]}"; do
    # Split the pair into network and address
    NETWORK=$(echo "$PAIR" | cut -d' ' -f1)
    ADDRESS=$(echo "$PAIR" | cut -d' ' -f2-)
    
    # Clean the address
    CLEAN_ADDRESS=$(clean_address "$ADDRESS")
    
    echo "Processing $NETWORK: $CLEAN_ADDRESS"
    echo "Processing $NETWORK: $CLEAN_ADDRESS" >> "$LOG_FILE"
    
    # Attempt to fetch the source code
    if sh ./sh/get_source_code.sh "$CLEAN_ADDRESS" "$NETWORK" >> "$LOG_FILE" 2>&1; then
        echo "✅ Success: $NETWORK"
        echo "✅ Success: $NETWORK" >> "$LOG_FILE"
    else
        echo "❌ Failed: $NETWORK"
        echo "❌ Failed: $NETWORK" >> "$LOG_FILE"
    fi
    
    echo "----------------------------------------" >> "$LOG_FILE"
    # Add a small delay between requests to avoid rate limiting
    sleep 2
done

echo "All contracts processed. See $LOG_FILE for details."
