const { network } = require('hardhat');

const oec  = require('./oec')
const bsc = require('./bsc')
const kovan = require('./bsc')

let config

console.log('current network.name: ', network.name)

if (network.name === 'oec') {
    config = oec
} else if (network.name === 'bsc') {
    config = bsc
} else if (network.name === 'kovan') {
    config = kovan
}

module.exports = config
