const { assert } = require("chai");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER} = require("./utils")

async function executeDAI2USDC() {

    await setForkBlockNumber(16780761);

    const accountAddress = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);
    //mock a rich account
    //const richAccountAddress = "0x56178a0d5f301baf6cf3e1cd53d9863437345bf9";
    //await startMockAccount([richAccountAddress]);
    //const richAccount = await ethers.getSigner(richAccountAddress);

    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");


    DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    )
    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )
    GUSD = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.GUSD.baseTokenAddress
    )
    USDP = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDP.baseTokenAddress
    )
    

    console.log("before Account DAI Balance: " + await DAI.balanceOf(account.address));
    console.log("before Account USDC Balance: " + await USDC.balanceOf(account.address));
    //console.log("before Account GUSD Balance: " + await GUSD.balanceOf(account.address));
    //console.log("before Account USDP Balance: " + await USDP.balanceOf(account.address));
    
    let { dexRouter, tokenApprove } = await initDexRouter();
    
    const PSMUSDCNetwork = "0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A";
    const PSMGUSDNetwork = "0x204659B2Fd2aD5723975c362Ce2230Fba11d3900";
    const PSMUSDPNetwork = "0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf";

    PSMAdapter = await ethers.getContractFactory("PSMAdapter");
    psmAdapter = await PSMAdapter.deploy(PSMUSDCNetwork, PSMGUSDNetwork, PSMUSDPNetwork, tokenConfig.tokens.USDC.baseTokenAddress, tokenConfig.tokens.GUSD.baseTokenAddress, tokenConfig.tokens.USDP.baseTokenAddress, tokenConfig.tokens.DAI.baseTokenAddress);
    await psmAdapter.deployed();

    // Construct  parameters for baseRequest
    // transfer 1 DAI to PSMAdapter
    const fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.DAI.decimals);
    const minReturnAmount = 0;
    const deadLine = FOREVER;


    //construt router1
    const mixAdapter1 = [
        psmAdapter.address
    ];
    const assertTo1 = [
        psmAdapter.address
    ];
    const weight1 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        direction(tokenConfig.tokens.DAI.baseTokenAddress, tokenConfig.tokens.USDC.baseTokenAddress) +
        "0000000000000000000" +
        weight1 +
        "0000000000000000000000000000000000000000"  // 40
    ];
    moreInfo1 =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            tokenConfig.tokens.DAI.baseTokenAddress,
            tokenConfig.tokens.USDC.baseTokenAddress
            //tokenConfig.tokens.GUSD.baseTokenAddress
            //tokenConfig.tokens.USDP.baseTokenAddress
        ]
    )
    const extraData1 = [moreInfo1];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1, DAI.address];

    // Construct  parameters for smartSwapByOrderId
    const orderId = 0;
    const layer1 = [router1];
    const pmmReq = [];

    const baseRequest1 = [
        DAI.address,
        USDC.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    await DAI.connect(account).approve(tokenApprove.address, fromTokenAmount);
    
    //construct tx from DAI to USDC
    tx = await dexRouter.connect(account).smartSwapByOrderId(//dexrouter里面的函数
        orderId,
        baseRequest1,
        [fromTokenAmount],
        [layer1],
        pmmReq
    );

    console.log(tx);
    console.log("after DAI Balance: " + await DAI.balanceOf(account.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(account.address));
    //console.log("after Account GUSD Balance: " + await GUSD.balanceOf(account.address));
    //console.log("after Account USDP Balance: " + await USDP.balanceOf(account.address));


    //construct tx from USDC to DAI
    const rawData2 = [
        "0x" +
        direction(tokenConfig.tokens.USDC.baseTokenAddress, tokenConfig.tokens.DAI.baseTokenAddress) +
        "0000000000000000000" +
        weight1 +
        "0000000000000000000000000000000000000000"  // 40
    ];
    moreInfo2 =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            tokenConfig.tokens.USDC.baseTokenAddress,
            //tokenConfig.tokens.GUSD.baseTokenAddress,
            //tokenConfig.tokens.USDP.baseTokenAddress,
            tokenConfig.tokens.DAI.baseTokenAddress

        ]
    )
    const extraData2 = [moreInfo2];
    const router2 = [mixAdapter1, assertTo1, rawData2, extraData2, USDC.address];

    const layer2 = [router2];
    const fromTokenAmount2 = ethers.utils.parseUnits("1", tokenConfig.tokens.USDC.decimals);

    const baseRequest2 = [
        USDC.address,
        DAI.address,
        fromTokenAmount2,
        minReturnAmount,
        deadLine,
    ]
    await USDC.connect(account).approve(tokenApprove.address, fromTokenAmount2);
    
    //construct tx from DAI to USDC
    tx = await dexRouter.connect(account).smartSwapByOrderId(//dexrouter里面的函数
        orderId+1,
        baseRequest2,
        [fromTokenAmount2],
        [layer2],
        pmmReq
    );
    console.log(tx);
    console.log("after DAI Balance: " + await DAI.balanceOf(account.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(account.address));
    //console.log("after Account GUSD Balance: " + await GUSD.balanceOf(account.address));
    //console.log("after Account USDP Balance: " + await USDP.balanceOf(account.address));
}



async function main() {
    // await executeNative();
    await executeDAI2USDC();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
