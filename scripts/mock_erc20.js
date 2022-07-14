const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed);

    MockERC20 = await ethers.getContractFactory("MockERC20");
    mockERC20 = await MockERC20.deploy("FLY", "FLY", ethers.utils.parseEther('10000000000'));
    await mockERC20.deployed();

    console.log("mockERC20: " + mockERC20.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
