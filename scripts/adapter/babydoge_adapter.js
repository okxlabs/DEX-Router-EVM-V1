const { ethers } = require("hardhat");
const deployed = require("../deployed");

async function main() {
    const router = "0xC9a0F685F39d05D835c369036251ee3aEaaF3c47";
    BabyDogeAdapter = await ethers.getContractFactory("BabyDogeAdapter");
    BabyDogeAdapter = await BabyDogeAdapter.deploy(router);
    await BabyDogeAdapter.deployed();

    console.log(`BabyDogeAdapter deployed: ${BabyDogeAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });