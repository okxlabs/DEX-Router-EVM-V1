const { ethers } = require("hardhat");
const deployed = require("../deployed");

// HashFlowRouterAddress
// https://docs.hashflow.com/hashflow/taker/getting-started#5.-execute-quote-on-chain

const _HashFlowRouter = "0xF6a94dfD0E6ea9ddFdFfE4762Ad4236576136613"
const _WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
async function deployContract() {
    HashFlowAdapter = await ethers.getContractFactory("HashflowAdapter");
    hashFlowAdapter = await upgrades.deployProxy(
      HashFlowAdapter, [_HashFlowRouter, _WETH]
    );
    await hashFlowAdapter.deployed();

    console.log("Owner: >>>> ", await hashFlowAdapter.owner());
    return hashFlowAdapter
}

async function main() {
    HashFlowAdapter = await deployContract();
    console.log(`HashFlowAdapter deployed: ${HashFlowAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
