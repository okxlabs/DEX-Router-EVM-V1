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

# Optimism
echo -e "\n🔍 Checking Optimism..."
sh ./sh/check_impl_code.sh op


# Polygon
echo -e "\n🔍 Checking Polygon..."
sh ./sh/check_impl_code.sh polygon

# Avalanche
echo -e "\n🔍 Checking Avalanche..."
sh ./sh/check_impl_code.sh avax

# Fantom
echo -e "\n🔍 Checking Fantom..."
sh ./sh/check_impl_code.sh ftm

# Cronos
echo -e "\n🔍 Checking Cronos..."
sh ./sh/check_impl_code.sh cro

# OKX Chain
echo -e "\n🔍 Checking OKX Chain..."
sh ./sh/check_impl_code.sh okc

# Flare
echo -e "\n🔍 Checking Flare..."
sh ./sh/check_impl_code.sh flare

# zkSync Era
echo -e "\n🔍 Checking zkSync Era..."
sh ./sh/check_impl_code.sh zksync

# Conflux
echo -e "\n🔍 Checking Conflux..."
sh ./sh/check_impl_code.sh conflux

# Polygon zkEVM
echo -e "\n🔍 Checking Polygon zkEVM..."
sh ./sh/check_impl_code.sh polyzkevm

# Linea
echo -e "\n🔍 Checking Linea..."
sh ./sh/check_impl_code.sh linea

# Mantle
echo -e "\n🔍 Checking Mantle..."
sh ./sh/check_impl_code.sh mantle

# Scroll
echo -e "\n🔍 Checking Scroll..."
sh ./sh/check_impl_code.sh scroll

# Canto
echo -e "\n🔍 Checking Canto..."
sh ./sh/check_impl_code.sh canto

# Manta
echo -e "\n🔍 Checking Manta..."
sh ./sh/check_impl_code.sh manta

# Metis
echo -e "\n🔍 Checking Metis..."
sh ./sh/check_impl_code.sh metis

# Zeta
echo -e "\n🔍 Checking Zeta..."
sh ./sh/check_impl_code.sh zeta

# Merlin
echo -e "\n🔍 Checking Merlin..."
sh ./sh/check_impl_code.sh merlin

# Blast
echo -e "\n🔍 Checking Blast..."
sh ./sh/check_impl_code.sh blast

# Mode
echo -e "\n🔍 Checking Mode..."
sh ./sh/check_impl_code.sh mode

# XLayer
echo -e "\n🔍 Checking XLayer..."
sh ./sh/check_impl_code.sh xlayer

# Sei
echo -e "\n🔍 Checking Sei..."
sh ./sh/check_impl_code.sh sei

# Ape Chain
echo -e "\n🔍 Checking Ape Chain..."
sh ./sh/check_impl_code.sh apechain

# IoTeX
echo -e "\n🔍 Checking IoTeX..."
sh ./sh/check_impl_code.sh iotex

# Sonic
echo -e "\n🔍 Checking Sonic..."
sh ./sh/check_impl_code.sh sonic

# Tron
echo -e "\n🔍 Checking Tron..."
sh ./sh/check_impl_code.sh tron

echo -e "\n✅ All checks completed!"