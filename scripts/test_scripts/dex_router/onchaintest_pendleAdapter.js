const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("./utils")

//Tx record: https://etherscan.io/tx/0xdf3d53d1debd83ae9e858fbf3f76251a2e45f2299ae9144ed93d1ff766927f1c
async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x3b3ae790Df4F312e745D270119c6052904FB6790");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0xDeEF773D61719a3181E35e9281600Db8bA063f71";
    let poolAddress = "0xF32e58F92e60f4b0A37A69b95d642A471365EAe8";  //weETH

    toToken = await ethers.getContractAt(
        "MockERC20",
        "0xc69Ad9baB1dEE23F4605a82b3354F8E40d1E5966"//PT-weETH
    )
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0xcd5fe23c85820f7b72d0926fc9b05b43e359b7ee"//weETH
    )
    const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }

    let fromTokenAmount = ethers.utils.parseEther('0.0001');
    let minReturnAmount = 0;
    let deadLine = FOREVER;
    let mixAdapter1 = [adapter];
    let assertTo1 = [adapter];
    let weight1 = Number(10000).toString(16).replace('0x', '');
    let rawData1 = [
        "0x" + 
        "0" + 
        "0000000000000000000" + 
        weight1 + 
        poolAddress.replace("0x", "")
    ];
    const data = ethers.utils.defaultAbiCoder.encode(
        ["uint256", "uint256", "uint256", "uint256", "uint256"],
        [
            0,
            ethers.constants.MaxUint256,
            0,
            256,
            1e14
        ]
    )
    const moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bool", "bool", "bytes"],
        [
            fromToken.address,
            toToken.address,
            true,
            true,
            data
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
    // await fromToken.approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq,
    );
}

main()
    .then(() => process.exit(0))
    .catch(error => {
    console.error(error);
    process.exit(1);
});