const { network } = require('hardhat');

const oec = require('./oec')
const bsc = require('./bsc')

let config

if (network == "oec") {
  config = oec
} else {
  throw error("network not config")
}

module.exports = {
  config
}