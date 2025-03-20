#!/bin/bash

# Script to check DexRouter implementations for all chains
# Usage: ./check_impl_all.sh

echo "Checking DexRouter implementations for all chains..."
echo "=================================================="

# Ethereum
echo -e "\n🔍 Checking Ethereum..."
./sh/check_impl.sh eth

# Arbitrum
echo -e "\n🔍 Checking Arbitrum..."
./sh/check_impl.sh arb

# Binance Smart Chain
echo -e "\n🔍 Checking Binance Smart Chain..."
./sh/check_impl.sh bsc

# Base
echo -e "\n🔍 Checking Base..."
./sh/check_impl.sh base

# Optimism
echo -e "\n🔍 Checking Optimism..."
./sh/check_impl.sh op

# Tron
echo -e "\n🔍 Checking Tron..."
./sh/check_impl.sh tron

# Polygon
echo -e "\n🔍 Checking Polygon..."
./sh/check_impl.sh polygon

# Avalanche
echo -e "\n🔍 Checking Avalanche..."
./sh/check_impl.sh avax

# Fantom
echo -e "\n🔍 Checking Fantom..."
./sh/check_impl.sh ftm

# Cronos
echo -e "\n🔍 Checking Cronos..."
./sh/check_impl.sh cro

# OKX Chain
echo -e "\n🔍 Checking OKX Chain..."
./sh/check_impl.sh okc

# Flare
echo -e "\n🔍 Checking Flare..."
./sh/check_impl.sh flare

# zkSync Era
echo -e "\n🔍 Checking zkSync Era..."
./sh/check_impl.sh zksync

# Conflux
echo -e "\n🔍 Checking Conflux..."
./sh/check_impl.sh conflux

# Polygon zkEVM
echo -e "\n🔍 Checking Polygon zkEVM..."
./sh/check_impl.sh polyzkevm

# Linea
echo -e "\n🔍 Checking Linea..."
./sh/check_impl.sh linea

# Mantle
echo -e "\n🔍 Checking Mantle..."
./sh/check_impl.sh mantle

# Scroll
echo -e "\n🔍 Checking Scroll..."
./sh/check_impl.sh scroll

# Canto
echo -e "\n🔍 Checking Canto..."
./sh/check_impl.sh canto

# Manta
echo -e "\n🔍 Checking Manta..."
./sh/check_impl.sh manta

# Metis
echo -e "\n🔍 Checking Metis..."
./sh/check_impl.sh metis

# Zeta
echo -e "\n🔍 Checking Zeta..."
./sh/check_impl.sh zeta

# Merlin
echo -e "\n🔍 Checking Merlin..."
./sh/check_impl.sh merlin

# Blast
echo -e "\n🔍 Checking Blast..."
./sh/check_impl.sh blast

# Mode
echo -e "\n🔍 Checking Mode..."
./sh/check_impl.sh mode

# XLayer
echo -e "\n🔍 Checking XLayer..."
./sh/check_impl.sh xlayer

# Sei
echo -e "\n🔍 Checking Sei..."
./sh/check_impl.sh sei

# Ape Chain
echo -e "\n🔍 Checking Ape Chain..."
./sh/check_impl.sh apechain

# IoTeX
echo -e "\n🔍 Checking IoTeX..."
./sh/check_impl.sh iotex

# Sonic
echo -e "\n🔍 Checking Sonic..."
./sh/check_impl.sh sonic

echo -e "\n✅ All checks completed!"