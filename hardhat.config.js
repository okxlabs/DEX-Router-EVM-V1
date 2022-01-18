require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades")
require('hardhat-abi-exporter');
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
      gasPrice: 20000000000,
      accounts: [`${privateKey}`],
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      },
    }
  },
  paths: {
    sources: './contracts/8'
  },
  abiExporter: {
    path: './abi',
    clear: true,
    flat: true
  }
}

