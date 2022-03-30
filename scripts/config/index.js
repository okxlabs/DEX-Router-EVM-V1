const { network } = require('hardhat');

const okc  = require('./okc')
const bsc  = require('./bsc')
const eth  = require('./eth')

let config

if (network == "okc") {
  config = okc
} else if (network == "bsc") {
  config = bsc
} else if (network == "eth") {
  config = eth
}

const getConfig = function (network) {
  if (network == "okc") {
    return okc
  } else if (network == "bsc") {
    return bsc
  } else if (network == "eth") { 
    return eth
  } else {
    throw error("network not config")
  }
}

module.exports = {
  getConfig,
  config
}
