const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    UniV3Adapter = await ethers.getContractFactory("UniV3Adapter");
    uniV3Adapter = await UniV3Adapter.deploy(deployed.base.wNativeToken);
    let tx = await uniV3Adapter.deployed();
    console.log(tx);

    console.log(`uniV3Adapter deployed: ${uniV3Adapter.address}`);

    // verify
    await hre.run("verify:verify", {
        address: uniV3Adapter.address,
        constructorArguments: [deployed.base.wNativeToken],
    });
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
