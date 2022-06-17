const { network } = require('hardhat');

const oec  = require('./okc')
const bsc = require('./bsc')
const eth = require('./eth')
const polygon = require('./polygon')
const avax = require('./avax')
const ftm = require('./ftm')
const arb = require('./arb')
const op = require('./op')
const cro = require('./cro')

let config

console.log('current network.name: ', network.name)

if (network.name === 'okc') {
    config = oec
} else if (network.name === 'bsc') {
    config = bsc
} else if (network.name === 'eth') {
    config = eth
} else if (network.name === 'polygon') {
    config = polygon
} else if (network.name === 'avax') {
    config = avax
} else if (network.name === 'ftm') {
    config = ftm
} else if (network.name === 'arb') {
    config = arb
} else if (network.name === 'op') {
    config = op
} else if (network.name === 'cro') {
    config = cro
}

module.exports = config
