require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-solhint");
require('hardhat-abi-exporter');
require("hardhat-gas-reporter");
require("solidity-coverage");
require('hardhat-contract-sizer');
require('hardhat-log-remover');
require("@openzeppelin/hardhat-upgrades");
require('dotenv').config();
require("./scripts/multichain.js");

// Note: If no private key is configured in the project, the first test account of Hardhat is used by default
const PRIVATE_KEY = process.env.PRIVATE_KEY || 'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80';
const ALCHEMY_KEY = process.env.ALCHEMY_KEY || '';
const INFSTONES_KEY = process.env.INFSTONES_KEY || '';
const INFURA_KEY = process.env.INFURA_KEY || '';
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || '';

module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.8.17',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          },
        }
      },
    ]
  },
  networks: {
    hardhat: {
      chainId: 31337,
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      timeout: 1800000,
      // forking:
      // {
      //   url: "https://rpc.ankr.com/eth"
      // }
    },
    okc: {
      url: INFSTONES_KEY == '' ? "https://exchainrpc.okex.org" : `https://api.infstones.com/okc-archive/mainnet/${INFSTONES_KEY}`,
      chainId: 66,
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    tron: {
      url: "https://api.trongrid.io",
      chainId: 65,
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    tron: {
      url: "https://exchaintestrpc.okex.org",
      chainId: 65,
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    zeta: {
      url: 'https://zetachain-evm.blockpi.network/v1/rpc/public',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    flare: {
      url: "https://flare-api.flare.network/ext/C/rpc",
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    bsc: {
      url: "https://rpc.ankr.com/bsc",
      chainId: 56,
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    bsc_dev: {
      url: "https://rpc.ankr.com/bsc",
      chainId: 56,
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    bsc_test: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    eth: {
      url: ALCHEMY_KEY == '' ? "https://eth.llamarpc.com" : `https://eth-mainnet.g.alchemy.com/v2/${ALCHEMY_KEY}`,
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_KEY}`,
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    sepolia: {
      url: `https://rpc.sepolia.org`,
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    cro: {
      url: "https://evm-cronos.crypto.org",
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    crotest: {
      url: "https://cronos-testnet-3.crypto.org:8545",
      accounts: [`${PRIVATE_KEY}`],
      network_id: "*",
      skipDryRun: true,
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    avax: {
      url: "https://rpc.ankr.com/avalanche",
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    avaxtest: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      accounts: [`${PRIVATE_KEY}`],
      gas: 2100000,
      gasPrice: 25000000000,
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    polygon: {
      url: ALCHEMY_KEY == '' ? "https://1rpc.io/matic" : `https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_KEY}`,
      accounts: [`${PRIVATE_KEY}`],
      gasPrice: 250000000000,
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    polygontest: {
      url: "https://rpc-mumbai.maticvigil.com/",
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    arb: {
      url: "https://arb1.arbitrum.io/rpc",
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    op: {
      url: "https://optimism-mainnet.public.blastapi.io",
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    ftm: {
      url: "https://rpc.ankr.com/fantom",
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    ethw: {
      url: "https://mainnet.ethereumpow.org",
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    conflux: {
      url: "https://evm.confluxrpc.com",
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    polyzkevm: {
      url: "https://zkevm-rpc.com",
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    zksync: {
      url: "https://mainnet.era.zksync.io",
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    linea: {
      url: `https://1rpc.io/linea`,
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    mantle: {
      url: `https://rpc.mantle.xyz`,
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    base: {
      url: 'https://mainnet.base.org',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    scroll: {
      url: "https://rpc.scroll.io" || "",
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    basetest: {
      url: 'https://goerli.base.org',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    canto: {
      url: 'https://mainnode.plexnode.org:8545',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    manta: {
      url: 'https://pacific-rpc.manta.network/http',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    metis: {
      url: 'https://andromeda.metis.io/?owner=1088',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    merlin: {
      url: 'https://rpc.merlinchain.io',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    xlayer: {
      url: 'https://rpc.xlayer.tech',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    blast: {
      url: 'https://rpc.blast.io',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    mode: {
      url: 'https://mainnet.mode.network',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    sei: {
      url: 'https://evm-rpc.sei-apis.com',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    moonbeam: {
      url: 'https://rpc.ankr.com/moonbeam',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    iotex: {
      url: 'https://babel-api.fastblocks.io',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    apechain: {
      url: 'https://rpc.apechain.com/http',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    },
    taiko: {
      url: 'https://rpc.mainnet.taiko.xyz',
      accounts: [`${PRIVATE_KEY}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    }
  },
  paths: {
    sources: './contracts/8'
  },
  abiExporter: {
    path: './abi',
    clear: true,
    flat: false,
    runOnCompile: true,
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: false,
    strict: true,
  },
  gasReporter: {
    enabled: true
  },
  mocha: {
    timeout: 180000000
  },
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_API_KEY
    }
  }
}
