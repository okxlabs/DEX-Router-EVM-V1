const { ethers } = require("hardhat");
require("../../tools");
let { direction, FOREVER } = require("../dex_router/utils")

//sei
async function main() {
    const dexRouter = await ethers.getContractAt("DexRouter", "0xdB3af8dF1cab8ae4159ED6a9b33dF5f8C3aD1485");
    const tokenApprove = await ethers.getContractAt("TokenApprove", "0x801D8ED849039007a7170830623180396492c7ED");

    console.log("DexRouter: " + dexRouter.address);
    const gasPirce = await ethers.provider.getGasPrice();
    console.log("gasPrice: " + gasPirce);
    const adapter = "0x9Ac7b1FFEE0f58c0a3c89AA54Afb62efD25DC9fd"

    // weighted pool
    // let pool = "0x78fb4d5184718be1dd9eb87422ec57a8f987c116"
    // fromToken = await ethers.getContractAt(
    //     "MockERC20",
    //     "0xE30feDd158A2e3b13e9badaeABaFc5516e95e8C7"
    // ) //WSEI
    // toToken = await ethers.getContractAt(
    //     "MockERC20",
    //     "0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1"
    // ) //USDC

    // stable pool
    let pool = "0x4f376b208e2b3186d5499de68839fa2a90453d11" 
    fromToken = await ethers.getContractAt(
        "MockERC20",
        "0x3894085Ef7Ff0f0aeDf52E2A2704928d1Ec074F1"
    ) //USDC
    toToken = await ethers.getContractAt(
        "MockERC20",
        "0x37a4dD9CED2b19Cfe8FAC251cd727b5787E45269"
    ) //fastUSD
    
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
        pool.replace("0x", "")
    ]; 

    // weighted pool
    // let moreInfo =  ethers.utils.defaultAbiCoder.encode(
    //     ["address", "address", "bytes32"],
    //     [
    //         fromToken.address,
    //         toToken.address,
    //         "0x78fb4d5184718be1dd9eb87422ec57a8f987c116000200000000000000000004"
    //     ]
    // ) 

    // stable pool
    let moreInfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bytes32"],
        [
            fromToken.address,
            toToken.address,
            "0x4f376b208e2b3186d5499de68839fa2a90453d110000000000000000000000a5"
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
    await fromToken.approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.smartSwapByOrderId(
        orderId,
        baseRequest,
        [fromTokenAmount],
        [layer1],
        pmmReq, {
            "gasLimit": 317360
        }
    );
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });