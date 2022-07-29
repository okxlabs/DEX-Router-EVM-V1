const { ethers, upgrades } = require("hardhat");
require("../../scripts/tools");
const deployed = require('../../scripts/deployed');
// const { marketMaker } = require("../../scripts/deployed/okc_dev/base");
const pmm_params = require("../pmm/pmm_params");

console.log(deployed);
console.log(pmm_params);

async function main() {
    await init();

    // 1. deploy marketMaker without initialization
    MarketMaker = await ethers.getContractFactory("MarketMaker");
    marketMaker = await upgrades.deployProxy(
        MarketMaker,[
            deployed.base.wNativeToken, 
            pmm_params.feeTo, 
            pmm_params.feeRate, 
            pmm_params.backEnd,
            pmm_params.cancelerGuardian
        ]
    );

    await marketMaker.deployed();
    console.log("marketMaker: ", marketMaker.address);

    // 2. deploy pmmAdapter
    PMMAdapter = await ethers.getContractFactory("PMMAdapter");
    pmmAdapter = await PMMAdapter.deploy(marketMaker.address, deployed.base.dexRouter);
    await pmmAdapter.deployed();
    console.log("pmmAdapter: ", pmmAdapter.address);

    // 3. setup marketMaker and approveProxy
    await marketMaker.setApproveProxy(deployed.base.tokenApproveProxy);
    await tokenApproveProxy.addProxy(marketMaker.address);
    await marketMaker.addPmmAdapter(pmmAdapter.address);
    await marketMaker.setUniV2Factory(deployed.base.factory);

}

const init = async function () {

    dexRouter = await ethers.getContractAt(
        "DexRouter",
        deployed.base.dexRouter
    );
    console.log("dexRouter.address", dexRouter.address)

    tokenApproveProxy = await ethers.getContractAt(
        "TokenApproveProxy",
        deployed.base.tokenApproveProxy
    );
    console.log("tokenApproveProxy.address", tokenApproveProxy.address);


}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });