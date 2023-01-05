const { ethers, upgrades} = require("hardhat");

const pmm_params = require("./pmm/pmm_params");
const deployed = require('../scripts/deployed');

async function main() {
    // deploy DexRouterV2
    let _feeRateAndReceiver = "0x000000000000000000000000" + pmm_params.feeTo.slice(2);
    const DexRouterV2 = await ethers.getContractFactory("DexRouterV2");
    const dexRouterV2 = await upgrades.deployProxy(
        DexRouterV2, [
            _feeRateAndReceiver
        ]
    );
    await dexRouterV2.deployed();

    // deploy SmartRouter
    const SmartRouter = await ethers.getContractFactory("SmartRouter");
    const smartRouter = await SmartRouter.deploy(dexRouterV2.address);

    // set xBridge、SmartRouter
    await dexRouterV2.setSmartRouter(smartRouter.address);
    await dexRouterV2.setXBridge(deployed.base.xbridge);

    // addProxy
    const tokenApproveProxy = await ethers.getContractAt("TokenApproveProxy", deployed.base.tokenApproveProxy)
    await tokenApproveProxy.addProxy(smartRouter.address);
    await tokenApproveProxy.addProxy(dexRouterV2.address);

    console.log("xBridge: " + deployed.base.xbridge);
    console.log("smartRouter: " + smartRouter.address);
    console.log("dexRouter: " + dexRouterV2.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});