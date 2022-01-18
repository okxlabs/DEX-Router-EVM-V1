const { network } = require('hardhat');

const oec  = require('./oec')

let config

if (network == "oec") {
  config = oec
} else if (network == "bsc") { 
  config = bsc
} else {
  throw error("network not config")
}

module.exports = {
  config
}
