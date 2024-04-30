const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("./utils")

//Tx record: https://explorer.mantle.xyz/tx/0xf966e9c0a1d28eb9cb025804c4c9ec59a4a49d3a6b83e1e582c8e500203f51f3?tab=index
async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0x9333C74BDd1E118634fE5664ACA7a9710b108Bab");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x2c34A2Fb1d0b4f55de51E1d0bDEfaDDce6b7cDD6");
    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0xfb719654604f44Df1D5CbfeA736095444D5F6c88";
    let poolAddress = "0x0536c8b0c3685b6e3C62A7b5c4E8b83f938f12D1";  //WETH--Babydoge

    toToken = await ethers.getContractAt(
        "MockERC20",
        "0xc748673057861a797275CD8A068AbB95A902e8de"//Babydoge
    )
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"//WETH
    )
    const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }

    let fromTokenAmount = ethers.utils.parseEther('0.001');
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
        ["address", "address"],
        [
            fromToken.address,
            toToken.address
        ]
    )
    const moreInfo = data;
    let extraData1 = [moreInfo];
    let router1 = [mixAdapter1, assertTo1, rawData1, extraData1, fromToken.address];
    let layer1 = [router1];
    let orderId = 0;
    let baseRequest = [
        ETH.address,
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
        {value: fromTokenAmount}
    );
}

main()
    .then(() => process.exit(0))
    .catch(error => {
    console.error(error);
    process.exit(1);
});