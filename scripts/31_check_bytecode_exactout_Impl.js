const { ethers, network } = require("hardhat");
const deployed = require('./deployed/index.js');
require('colors');
const Diff = require('diff');

// For the zeta network specifically, the configuration is in the zeta/base.js file
const zetaConfig = require('./deployed/zeta/base.js');

async function main() {

    // Get the new implementation code
    let newImpl = deployed.base.newExactOutImpl;
    if (!newImpl) {
        console.error("Error: newImpl is not defined in the deployed configuration");
        process.exit(1);
    }

    let code = await ethers.provider.getCode(newImpl);
    code = code.toLowerCase();

    // Get the compiled contract bytecode for comparison
    let codeCompare = require("../artifacts/contracts/8/DexRouterExactOut.sol/DexRouterExactOut.json")['deployedBytecode'].toLowerCase();


    // Compare the bytecodes with nullified addresses
    const diff = Diff.diffChars(code, codeCompare);

    console.log("Differences between implementations:");

    let hasDifference = false;
    diff.forEach((part) => {
        // Check if the part is an addition or removal (indicating a difference)
        if (part.added || part.removed) {
            hasDifference = true;
        }

        // green for additions, red for deletions
        let text = part.added ? part.value.bgGreen :
            part.removed ? part.value.bgRed : part.value;
        process.stderr.write(text);
    });

    if (!hasDifference) {
        console.log("\nchain: " + network.name);
        console.log("\nNo differences found after nullifying the addresses.".green);
    } else {
        console.log("\nchain: " + network.name);
        console.log("\nDifferences found in the implementations even after nullifying addresses.".yellow);
    }

    console.log();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
