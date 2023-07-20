const { network } = require('hardhat');

const okc = require('./okc')
const bsc = require('./bsc')
const eth = require('./eth')
const avax = require('./avax')
const arbitrum = require('./arbitrum')
const op = require('./op')
const ftm = require('./ftm')
const polygon = require('./polygon')
const zksync = require('./zksync')
const linea = require('./linea')
const mantle = require('./mantle')

let config

if (network == "okc") {
  config = okc
} else if (network == "bsc") {
  config = bsc
} else if (network == "eth") {
  config = eth
} else if (network == 'avax') {
  config = avax
} else if (network == 'arb') {
  config = arbitrum
} else if (network == 'op') {
  config = op
} else if (network == 'ftm') {
  config = ftm
} else if (network == 'polygon') {
  config = polygon
} else if (network == 'zksync') {
  config = zksync
} else if (network == 'linea') {
  config = linea
} else if (network == 'mantle') {
  config = mantle
} else {
  // throw error("network not config")
}

const getConfig = function (network) {
  if (network == "okc") {
    return okc
  } else if (network == "bsc") {
    return bsc
  } else if (network == "eth") {
    return eth
  } else if (network == 'avax') {
    return avax
  } else if (network == 'arb') {
    return arbitrum
  } else if (network == 'op') {
    return op
  } else if (network == 'ftm') {
    return ftm
  } else if (network == 'polygon') {
    return polygon
  } else if (network == 'zksync') {
    return zksync
  } else if (network == 'linea') {
    config = linea
  } else {
    console.log("network not config!!!")
  }
}

module.exports = {
  getConfig,
  config
}
