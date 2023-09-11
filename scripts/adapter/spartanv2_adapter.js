const { ethers } = require("hardhat");

async function main() {
    //BSC network
    SpartanV2Adapter = await ethers.getContractFactory("SpartanV2Adapter");
    SpartanV2Adapter = await SpartanV2Adapter.deploy('0xf73d255d1E2b184cDb7ee0a8A064500eB3f6b352');
    await SpartanV2Adapter.deployed();

    console.log(`SpartanV2Adapter deployed: ${SpartanV2Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
