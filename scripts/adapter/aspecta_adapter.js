const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    const DexRouter = [
        "0xF4858d71e5d7D27e3F7270390Cd57545DcA35aa9", // bsc pre
        "0x9b9efa5Efa731EA9Bbb0369E91fA17Abf249CFD4" // bsc online, v1.0.1-before_stop
    ];
    
    AspectaAdapter = await ethers.getContractFactory("AspectaAdapter");
    aspectaAdapter = await AspectaAdapter.deploy(deployed.base.wNativeToken);
    let tx = await aspectaAdapter.deployed();
    console.log(tx);

    console.log(`aspectaAdapter deployed: ${aspectaAdapter.address}`);

    // set dex router whitelist
    for (const dexRouter of DexRouter) {
        const tx = await aspectaAdapter.setDexRouter(dexRouter, true);
        await tx.wait();
        console.log(`DexRouter ${dexRouter} set:`, await aspectaAdapter.dexRouter(dexRouter));
    }

    // verify
    await hre.run("verify:verify", {
        address: aspectaAdapter.address,
        constructorArguments: [deployed.base.wNativeToken],
    });

    // transfer ownership
    // aspectaAdapter = await ethers.getContractAt("AspectaAdapter", "0xC8F6b8Ba0DC0f175B568B99440B0867F69A29265");
    tx = await aspectaAdapter.transferOwnership("0xAcE2B3E7c752d5deBca72210141d464371b3B9b1"); // dex owner address
    await tx.wait();
    console.log("new owner set:", await aspectaAdapter.owner());
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
