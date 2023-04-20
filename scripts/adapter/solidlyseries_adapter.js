const { ethers } = require("hardhat");

//this script is for spiritswapv2（ftm）、cone（bsc）、Dystopia（poly）、Velodrome（op）、Rames Exchanges（arb）、solidlizard（arb）
async function main() {
    SolidlyseriesAdapter = await ethers.getContractFactory("SolidlyseriesAdapter");
    solidlyseriesAdapter = await SolidlyseriesAdapter.deploy();
    await solidlyseriesAdapter.deployed();

    console.log(`solidlyseriesAdapter deployed: ${solidlyseriesAdapter.address}`);
}


main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
