# 将需要检查的 network 列表复制于此(不区分大小写)
NETWORKS=(
eth
arb
avax
base
bsc
manta
mode
op
polygon
scroll
sonic
zeta
zksync
FTM
CRO
OKC
FLARE
CONFLUX
POLYZKEVM
LINEA
MANTLE
METIS
MERLIN
BLAST
XLAYER
SEI
APECHAIN
IOTEX
)

if [ $# -eq 1 ]; then
  echo "========================================"
  echo "Checking network: $1"
  echo "========================================"
  npx hardhat run scripts/43_check_status.js --network $1 --no-compile
else
  for NETWORK in "${NETWORKS[@]}"; do
  # 将network转换为小写
    NETWORK_LOWER=$(echo "$NETWORK" | tr '[:upper:]' '[:lower:]')
    echo "========================================"
    echo "Checking network: $NETWORK (using: $NETWORK_LOWER)"
    echo "========================================"
    npx hardhat run scripts/43_check_status.js --network $NETWORK_LOWER --no-compile
    echo ""
  done
fi