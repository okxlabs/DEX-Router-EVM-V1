const { ethers } = require("hardhat");
const deployed = require('./deployed');
const assert = require('assert');

async function main() {
    // console.log(deployed);
    console.log(await ethers.provider.getNetwork())
    let dexRouter = deployed.base.newExactOutImpl
    dexRouter = await ethers.getContractAt("DexRouterExactOut", dexRouter)
    let weth = await dexRouter._WETH()
    console.log("dexRouter", dexRouter.address);
    console.log("_WETH", weth, "is match ", weth == deployed.base.wNativeToken);
    let wnativeRelay = await dexRouter._WNATIVE_RELAY()
    console.log("_WNATIVE_RELAY", wnativeRelay, "is match ", wnativeRelay == deployed.base.wNativeRelayer);
    let approveProxy = await dexRouter._APPROVE_PROXY()
    console.log("_APPROVE_PROXY", approveProxy, "is match ", approveProxy == deployed.base.tokenApproveProxy);
    assert(weth == deployed.base.wNativeToken)
    assert(wnativeRelay == deployed.base.wNativeRelayer)
    assert(approveProxy == deployed.base.tokenApproveProxy)
}

main();