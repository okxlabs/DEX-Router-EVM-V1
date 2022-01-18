const { network } = require('hardhat');

const oec  = require('./oec')
const bsc = require('./bsc')

let config

console.log('current network.name: ', network.name)

if (network.name === 'oec') {
    config = oec
} else if (network.name === 'bsc') {
    config = bsc
}

module.exports = config
