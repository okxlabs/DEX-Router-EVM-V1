require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades")
require('hardhat-abi-exporter');
require("hardhat-gas-reporter");
require('hardhat-contract-sizer');
require("@nomiclabs/hardhat-solhint");
require('dotenv').config();

const privateKey = process.env.privateKey;

module.exports = {
  solidity: {
    compilers: [
			{
				version: '0.7.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
			},
      {
				version: '0.8.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
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
      forking: {
        url: "https://eth-mainnet.alchemyapi.io/v2/VHBzLDpGJ5_yS0fMJZ-APXoWBFJIONZh",
        // blockNumber: 14395835
      }
    },
    oec: {
      url: "https://exchainrpc.okex.org",
      chainId: 66,
      accounts: [`${privateKey}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    oec_test: {
      url: "https://exchaintestrpc.okex.org",
      chainId: 65,
      accounts: [`${privateKey}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    bsc: {
      url: "https://bsc-dataseed1.defibit.io",
      chainId: 56,
      accounts: [`${privateKey}`],
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
      accounts: [`${privateKey}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    },
    eth: {
      url: "https://mainnet.infura.io/v3/2e250de311a54d8da61d7e256fa1df4a",
      accounts: [`${privateKey}`],
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
    flat: true
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: false,
    strict: true,
  },
  gasReporter: {
    enabled: false
  }
}

