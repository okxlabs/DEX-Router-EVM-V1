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

async function upgradeContract(hashflowAdapterAddress) {
    HashflowAdapter = await ethers.getContractFactory("HashflowAdapter");
    r = await upgrades.upgradeProxy(
        hashflowAdapterAddress,
        HashflowAdapter
    );
  
    console.log("update finish");
}

async function main() {
    // HashFlowAdapter = await deployContract();
    
    hashflowAdapterAddress = "0xc6de6a35eC4fF403914272a024820F2aBC5Bded7"
    await upgradeContract(hashflowAdapterAddress)
    console.log(`HashFlowAdapter deployed: ${HashFlowAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
