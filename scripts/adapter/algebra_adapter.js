const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {

    const [signer] = await ethers.getSigners();
    console.log("signer address:", signer.address);

    AlgebraAdapter = await ethers.getContractFactory("AlgebraAdapter");
    algebraAdapter = await AlgebraAdapter.deploy(deployed.base.wNativeToken);
    let tx = await algebraAdapter.deployed();
    console.log("tx:", tx);

    console.log(`algebraAdapter deployed: ${algebraAdapter.address}`);

    // verify
    await hre.run("verify:verify", {
        address: algebraAdapter.address,
        constructorArguments: [deployed.base.wNativeToken],
    });
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
