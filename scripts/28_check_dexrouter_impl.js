const { ethers } = require("hardhat");
const deployed = require('./deployed');
const assert = require('assert');

async function main() {
    console.log(deployed);
    let dexRouter = deployed.base.newImpl
    dexRouter = await ethers.getContractAt("DexRouter", dexRouter)
    let weth = await dexRouter._WETH()
    let wnativeRelay = await dexRouter._WNATIVE_RELAY()
    let approveProxy = await dexRouter._APPROVE_PROXY()
    assert(weth == deployed.base.wNativeToken)
    assert(wnativeRelay == deployed.base.wNativeRelayer)
    assert(approveProxy == deployed.base.tokenApproveProxy)
    console.log("dexRouter", dexRouter.address);
    console.log("_WETH", weth, "==>", deployed.base.wNativeToken);
    console.log("_WNATIVE_RELAY", wnativeRelay, "==>", deployed.base.wNativeRelayer);
    console.log("_APPROVE_PROXY", approveProxy, "==>", deployed.base.tokenApproveProxy);
}

main();