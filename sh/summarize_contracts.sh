#!/bin/bash
set -e

# Function to count lines in a file
count_lines() {
    wc -l "$1" | awk '{print $1}'
}

# Function to calculate MD5 hash of a file
get_md5() {
    md5 -q "$1"
}

# Path to source code directory
SOURCE_DIR="./source_code"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source code directory not found"
    exit 1
fi

# Output files
SUMMARY_FILE="$SOURCE_DIR/contract_summary.md"
COMPARISON_FILE="$SOURCE_DIR/contract_comparison.md"

# Create summary file header
echo "# Contract Source Code Summary" > "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "Generated on: $(date)" >> "$SUMMARY_FILE"
echo "" >> "$SUMMARY_FILE"
echo "| Network | Contract Address | File Size | Line Count | MD5 Hash |" >> "$SUMMARY_FILE"
echo "|---------|-----------------|-----------|------------|----------|" >> "$SUMMARY_FILE"

# Create comparison file header
echo "# Contract Comparison Analysis" > "$COMPARISON_FILE"
echo "" >> "$COMPARISON_FILE"
echo "Generated on: $(date)" >> "$COMPARISON_FILE"
echo "" >> "$COMPARISON_FILE"
echo "This file identifies contracts that are identical or very similar across different networks." >> "$COMPARISON_FILE"
echo "" >> "$COMPARISON_FILE"
echo "## Identical Contracts (Same MD5 Hash)" >> "$COMPARISON_FILE"
echo "" >> "$COMPARISON_FILE"

# Store MD5 hashes for comparison
declare -A md5_map
declare -A md5_networks

# Process each contract file
for CONTRACT_FILE in "$SOURCE_DIR"/*_dexrouter.sol; do
    if [ -f "$CONTRACT_FILE" ]; then
        # Extract network name from filename
        NETWORK=$(basename "$CONTRACT_FILE" | sed 's/_dexrouter.sol//')
        
        # Get file size
        FILE_SIZE=$(du -h "$CONTRACT_FILE" | awk '{print $1}')
        
        # Count lines
        LINE_COUNT=$(count_lines "$CONTRACT_FILE")
        
        # Calculate MD5 hash
        MD5_HASH=$(get_md5 "$CONTRACT_FILE")
        
        # Add to summary file
        echo "| $NETWORK | - | $FILE_SIZE | $LINE_COUNT | $MD5_HASH |" >> "$SUMMARY_FILE"
        
        # Store MD5 hash for comparison
        if [ -n "${md5_networks[$MD5_HASH]}" ]; then
            md5_networks[$MD5_HASH]="${md5_networks[$MD5_HASH]}, $NETWORK"
        else
            md5_networks[$MD5_HASH]="$NETWORK"
        fi
        
        md5_map[$NETWORK]=$MD5_HASH
    fi
done

# Add identical contracts to comparison file
echo "The following groups of contracts have identical source code:" >> "$COMPARISON_FILE"
echo "" >> "$COMPARISON_FILE"

for md5 in "${!md5_networks[@]}"; do
    networks="${md5_networks[$md5]}"
    # Only include hashes that appear more than once
    if [[ "$networks" == *","* ]]; then
        echo "- **$networks**: MD5 hash \`$md5\`" >> "$COMPARISON_FILE"
    fi
done

echo "" >> "$COMPARISON_FILE"
echo "## Contract Size Comparison" >> "$COMPARISON_FILE"
echo "" >> "$COMPARISON_FILE"
echo "| Network | Line Count |" >> "$COMPARISON_FILE"
echo "|---------|------------|" >> "$COMPARISON_FILE"

# Sort files by line count and add to comparison
for CONTRACT_FILE in "$SOURCE_DIR"/*_dexrouter.sol; do
    if [ -f "$CONTRACT_FILE" ]; then
        NETWORK=$(basename "$CONTRACT_FILE" | sed 's/_dexrouter.sol//')
        LINE_COUNT=$(count_lines "$CONTRACT_FILE")
        echo "$NETWORK $LINE_COUNT"
    fi
done | sort -k2 -nr | while read -r NETWORK COUNT; do
    echo "| $NETWORK | $COUNT |" >> "$COMPARISON_FILE"
done

echo "" >> "$COMPARISON_FILE"
echo "## Next Steps" >> "$COMPARISON_FILE"
echo "" >> "$COMPARISON_FILE"
echo "Consider using a tool like 'diff' to compare the most interesting contracts in detail:" >> "$COMPARISON_FILE"
echo "" >> "$COMPARISON_FILE"
echo '```bash' >> "$COMPARISON_FILE"
echo "diff -u $SOURCE_DIR/ethereum_dexrouter.sol $SOURCE_DIR/optimism_dexrouter.sol" >> "$COMPARISON_FILE"
echo '```' >> "$COMPARISON_FILE"

echo "Summary created at $SUMMARY_FILE"
echo "Comparison created at $COMPARISON_FILE"
