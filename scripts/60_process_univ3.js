const { ethers } = require("hardhat");
const deployed = require('./deployed');
const { assert } = require("chai");
const fs = require('fs')
const path = require('path')
const hre = require("hardhat");

async function main() {
    const data = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'output.json')))
    const network_name = hre.network.name;
    console.log(network_name)
    for (let i = 0; i < data.length; i++) {
        let item = data[i]
        console.log(item)
        if (item.chainName != network_name) continue
        await process(item)
    }
}

async function process(item) {
    console.log(`process `, item["chainName"], " ", item["moduleName"], " ", item['contractAddress'])
    let code = await ethers.provider.getCode(item['contractAddress'])

    // Check for specific bytecode pattern
    if (code.includes('128acb08')) {
        console.log('Found 0x128acb08 in contract:', item['contractAddress'])
    }

    // Ensure data directory exists
    const dataDir = path.join(__dirname, 'data', item['chainName'])
    if (!fs.existsSync(dataDir)) {
        fs.mkdirSync(dataDir, { recursive: true })
    }

    fs.writeFileSync(path.join(dataDir, item['contractAddress']), code)
}

main()