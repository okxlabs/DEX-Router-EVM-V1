#!/bin/bash

# Script to check DexRouter implementations for all chains
# Usage: ./check_impl_all.sh

echo "Checking DexRouter implementations for all chains..."
echo "=================================================="

# Ethereum
echo -e "\n🔍 Checking Ethereum..."
sh ./sh/check_impl_code.sh eth

# Arbitrum
echo -e "\n🔍 Checking Arbitrum..."
sh ./sh/check_impl_code.sh arb

# Binance Smart Chain
echo -e "\n🔍 Checking Binance Smart Chain..."
sh ./sh/check_impl_code.sh bsc

# Base
echo -e "\n🔍 Checking Base..."
sh ./sh/check_impl_code.sh base

echo -e "\n✅ All checks completed!"