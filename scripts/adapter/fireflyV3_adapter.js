const { ethers } = require("hardhat");

async function main() {
    FireFlyV3Adapter = await ethers.getContractFactory("FireFlyV3Adapter");
    fireflyV3Adapter = await FireFlyV3Adapter.deploy("0x0Dc808adcE2099A9F62AA87D9670745AbA741746");
    //fireflyV3Adapter = await FireFlyV3Adapter.deploy(deployed.base.wNativeToken);
    await fireflyV3Adapter.deployed();

    console.log(`fireflyV3Adapter deployed: ${fireflyV3Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });