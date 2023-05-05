const { ethers } = require("hardhat");


async function main() {
    console.log("beethoven adapter only needs to deploy adapter on fantom network, since the op network can reuse the balancer adapter");
    const WFTM = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83"
    const vault = "0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce"
    BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
    BalancerV2Adapter = await BalancerV2Adapter.deploy(vault, WFTM);
    await BalancerV2Adapter.deployed();

    console.log(`beethovenAdapter for Beethoven deployed: ${BalancerV2Adapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
