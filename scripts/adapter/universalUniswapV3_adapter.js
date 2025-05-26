const { ethers } = require("hardhat");
const deployed = require("../deployed");

// Min and max sqrt ratio defined in libraries/TickMath.sol
const MIN_SQRT_RATIO = 4295128739;
const MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342n;

async function main() {

    const [signer] = await ethers.getSigners();
    console.log("signer address:", signer.address);

    UniversalUniswapV3Adaptor = await ethers.getContractFactory("UniversalUniswapV3Adaptor");
    universalAdapter = await UniversalUniswapV3Adaptor.deploy(deployed.base.wNativeToken, MIN_SQRT_RATIO, MAX_SQRT_RATIO);
    let tx = await universalAdapter.deployed();
    console.log("tx:", tx);

    console.log(`universalAdapter deployed: ${universalAdapter.address}`);

    // verify
    await hre.run("verify:verify", {
        address: universalAdapter.address,
        constructorArguments: [deployed.base.wNativeToken, MIN_SQRT_RATIO, MAX_SQRT_RATIO],
    });
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
