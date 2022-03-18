const { network } = require('hardhat');

const oec  = require('./oec')
const bsc = require('./bsc')
const kovan = require('./bsc')
const eth = require('./eth')

let config

console.log('current network.name: ', network.name)

if (network.name === 'oec') {
    config = oec
} else if (network.name === 'bsc') {
    config = bsc
} else if (network.name === 'kovan') {
    config = kovan
} else if (network.name === 'eth') {
    config = eth
}

module.exports = config
