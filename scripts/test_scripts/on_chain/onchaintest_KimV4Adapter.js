const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0xD0f95FaFA06de1B21E79Db03C649919501e99Ea9");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0xbd0EBE49779E154E5042B34D5BcfBc498e4B3249");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0x8b773D83bc66Be128c60e07E17C8901f7a64F000"
    let poolAddress = "0xb3E3576aC813820021b1d1157Ec2285ab5C67D15"; 
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x6863fb62Ed27A9DdF458105B507C15b5d741d62e"//KIM
    )
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0xd988097fb8612cc24eeC14542bC03424c656005f"//USDC
    )
    let fromTokenAmount = ethers.utils.parseUnits("0.1", 6);
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [adapter];
    let assertTo1 = [adapter];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        direction(fromToken.address, toToken.address) + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")
    ];
    const moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["uint160", "bytes"],
        [
            0,
            ethers.utils.defaultAbiCoder.encode(
                ["address", "address"],
                [
                    fromToken.address,
                    toToken.address
                ]
            )
        ]
    )
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, fromToken.address];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        fromToken.address,
        toToken.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    let pmmReq = []
    await dexRouter.smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );
}

main()
    .then(() => process.exit(0))
    .catch(error => {
    console.error(error);
    process.exit(1);
});
