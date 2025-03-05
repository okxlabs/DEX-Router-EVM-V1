const { network } = require('hardhat');

const oec = require('./okc')
const bsc = require('./bsc')
const eth = require('./eth')
const polygon = require('./polygon')
const avax = require('./avax')
const ftm = require('./ftm')
const arb = require('./arb')
const op = require('./op')
const cro = require('./cro')
const ethw = require('./ethw')
const cfx = require('./conflux')
const polyzkevm = require('./polyzkevm')
const flare = require('./flare')
const linea = require('./linea')
const mantle = require('./mantle')
const base = require('./base')
const scroll = require('./scroll')
const canto = require('./canto')
const manta = require('./manta')
const metis = require('./metis')
const zeta = require('./zeta')
const merlin = require('./merlin')
const sepolia = require('./eth_sepolia')
const xlayer = require('./xlayer')
const blast = require('./blast')
const mode = require('./mode')
const zksync = require('./zkSyncEra')
const tron = require('./tron')
const sei = require('./sei')
const moonbeam = require('./moonbeam')
const apechain = require('./apechain')
const iotex = require('./iotex')
const taiko = require('./taiko')
const sonic = require('./sonic')
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
} else if (network.name === 'ethw') {
    config = ethw
} else if (network.name === 'conflux') {
    config = cfx
} else if (network.name == 'polyzkevm') {
    config = polyzkevm
} else if (network.name == 'flare') {
    config = flare
} else if (network.name == 'linea') {
    config = linea
} else if (network.name == 'mantle') {
    config = mantle
} else if (network.name == 'base') {
    config = base
} else if (network.name == 'scroll') {
    config = scroll
} else if (network.name == 'canto') {
    config = canto
} else if (network.name == 'manta') {
    config = manta
} else if (network.name == 'metis') {
    config = metis
} else if (network.name == 'zeta') {
    config = zeta
} else if (network.name == 'merlin') {
    config = merlin
} else if (network.name == 'sepolia') {
    config = sepolia
} else if (network.name == 'xlayer') {
    config = xlayer
} else if (network.name == 'blast') {
    config = blast
} else if (network.name == 'mode') {
    config = mode
} else if (network.name == 'zksync') {
    config = zksync
} else if (network.name == 'tron') {
    config = tron
} else if (network.name == 'sei') {
    config = sei
} else if (network.name == 'moonbeam') {
    config = moonbeam
} else if (network.name == 'apechain') {
    config = apechain
} else if (network.name == 'iotex') {
    config = iotex
} else if (network.name == 'taiko') {
    config = taiko
} else if (network.name == 'sonic') {
    config = sonic
}

module.exports = config
