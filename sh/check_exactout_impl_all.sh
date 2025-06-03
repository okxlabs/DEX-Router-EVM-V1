#!/bin/bash

# Script to check DexRouter implementations for all chains
# Usage: ./check_impl_all.sh

echo "Checking DexRouter implementations for all chains..."
echo "=================================================="

# Ethereum
echo -e "\n🔍 Checking Ethereum..."
./sh/check_exactout_impl.sh eth

# Arbitrum
echo -e "\n🔍 Checking Arbitrum..."
./sh/check_exactout_impl.sh arb

# Binance Smart Chain
echo -e "\n🔍 Checking Binance Smart Chain..."
./sh/check_exactout_impl.sh bsc

# Base
echo -e "\n🔍 Checking Base..."
./sh/check_exactout_impl.sh base

echo -e "\n✅ All checks completed!"