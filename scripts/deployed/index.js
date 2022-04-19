const { network } = require('hardhat');

const oec  = require('./okc')
const bsc = require('./bsc')
const eth = require('./eth')

let config

console.log('current network.name: ', network.name)

if (network.name === 'okc') {
    config = oec
} else if (network.name === 'bsc') {
    config = bsc
} else if (network.name === 'eth') {
    config = eth
}

module.exports = config
