const { ethers } = require("hardhat");


async function main() {
    const router = "0x10f4A785F458Bc144e3706575924889954946639"
    MeshswapAdapter = await ethers.getContractFactory("MeshswapAdapter");
    meshswapAdapter = await MeshswapAdapter.deploy(router);

    await meshswapAdapter.deployed()

    console.log(`meshswapAdapter deployed: ${meshswapAdapter.address}`)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
