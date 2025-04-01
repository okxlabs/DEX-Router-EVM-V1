const hre = require("hardhat");
const deployed = require('./deployed');
async function main() {
    console.log("Starting contract verification...");

    try {

        console.log("Verifying on etherscan...", deployed.base.newImpl);
        await hre.run("verify:verify", {
            address: deployed.base.newImpl,
            constructorArguments: [], // Adjust if your contract has constructor arguments
            contract: "contracts/8/DexRouter.sol:DexRouter"
        });
        console.log("Verification on etherscan completed!");
    } catch (error) {
        console.error("Verification failed:", error);
    }
    try {
        // Verify on Oklink
        console.log("Verifying on Oklink...");
        await hre.run("okverify", {
            address: deployed.base.newImpl,
            constructorArguments: [], // Adjust if your contract has constructor arguments
            contract: "contracts/8/DexRouter.sol:DexRouter"
        });
        console.log("Verification on Oklink completed!");

    } catch (error) {
        console.error("Verification failed:", error);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 