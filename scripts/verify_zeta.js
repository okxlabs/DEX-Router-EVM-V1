const hre = require("hardhat");
const deployed = require('./deployed');
async function main() {


    console.log(`Verifying contract at address: ${deployed.base.newImpl}`);

    try {
        await hre.run("verify:zeta", {
            address: deployed.base.newImpl,
            constructorArguments: [],
        });
        console.log("Contract verified successfully!");
    } catch (error) {
        if (error.message.includes("Already Verified")) {
            console.log("Contract is already verified");
        } else {
            console.error("Verification failed:", error);
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
