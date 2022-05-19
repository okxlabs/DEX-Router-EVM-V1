const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth")
const { initDexRouter, direction, FOREVER, packRawData} = require("./utils")
const {assert} = require("chai");

const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
const BancorNetwork = "0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0";
const balancerVault = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";
const pmmReq = []

const initToken = async () => {
    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )
    RND = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.RND.baseTokenAddress
    )
    BNT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.BNT.baseTokenAddress
    )
    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )
    AAVE = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.AAVE.baseTokenAddress
    )
    return { WETH, RND, BNT, USDC, AAVE }
}

async function initAdapter() {
    UniV2Adapter = await ethers.getContractFactory("UniAdapter");
    univ2Adapter = await UniV2Adapter.deploy();
    await univ2Adapter.deployed();
    UniV3Adapter = await ethers.getContractFactory("UniV3Adapter");
    univ3Adapter = await UniV3Adapter.deploy(WETH.address);
    await univ3Adapter.deployed();
    BancorAdapter = await ethers.getContractFactory("BancorAdapter");
    bancorAdapter = await BancorAdapter.deploy(BancorNetwork, WETH.address);
    await bancorAdapter.deployed();
    balancerAdapter = await ethers.getContractFactory("BalancerAdapter");
    balancerAdapter = await balancerAdapter.deploy();
    await balancerAdapter.deployed();
    BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
    balancerV2Adapter = await BalancerV2Adapter.deploy(balancerVault, WETH.address);
    await balancerV2Adapter.deployed();
}

async function initWETHRNDParams(fromTokenAmount) {
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const uniV2PoolAddr = "0x5449bd1a97296125252db2d9cf23d5d6e30ca3c1"; // RND-WETH Pool
    const uniV3PoolAddr = "0x96b0837489d046A4f5aA9ac2FC9e086bD14Bac1E"; // RND-WETH V3 Pool
    // node1
    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [0]
    // ];
    const mixAdapter1 = [
        univ2Adapter.address,
        univ3Adapter.address
    ];
    const assertTo1 = [
        uniV2PoolAddr,
        univ3Adapter.address
    ];


    const weight1 = 2000;
    const weight2 = 8000;

    const rawData1 = [
        packRawData(tokenConfig.tokens.WETH.baseTokenAddress,tokenConfig.tokens.RND.baseTokenAddress,weight1,uniV2PoolAddr),
        packRawData(tokenConfig.tokens.WETH.baseTokenAddress,tokenConfig.tokens.RND.baseTokenAddress,weight2,uniV3PoolAddr)
    ];

    const moreInfo1 = "0x"
    const moreInfo2 = ethers.utils.defaultAbiCoder.encode(
        ["uint160", "bytes"],
        [
            // "888971540474059905480051",
            0,
            ethers.utils.defaultAbiCoder.encode(
                ["address", "address", "uint24"],
                [
                    WETH.address,
                    RND.address,
                    10000
                ]
            )
        ]
    )
    const extraData1 = [moreInfo1,moreInfo2];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1, WETH.address];

    // layer1
    // const request1 = [requestParam1];
    const layer1 = [router1];

    const baseRequest = [
        WETH.address,
        RND.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    // reqs = [request1]
    layers = [layer1]
    return {baseRequest, layers}
}

// weth ->  rnd  (univ2)
//      ->  rnd  (uniV3)
async function executeWEth2RND() {

    await setForkBlockNumber(14446603);
    const accountAddress = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    const { WETH, RND, BNT, USDC, AAVE } = await initToken();
    const { dexRouter, tokenApprove } = await initDexRouter(WETH.address);

    await initAdapter()

    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before RND Balance: " + await RND.balanceOf(account.address));

    const fromTokenAmount = ethers.utils.parseEther("1");
    const {baseRequest,layers} = await initWETHRNDParams(fromTokenAmount)

    await WETH.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        layers,
        pmmReq
    );

    let rndBalance = await RND.balanceOf(account.address);
    let adapterBalance1 = await WETH.balanceOf(univ2Adapter.address);
    let adapterBalance2 = await WETH.balanceOf(univ3Adapter.address);
    console.log("after univ2 WETH Balance: " + adapterBalance1);
    console.log("after univ3 WETH Balance: " + adapterBalance2);
    console.log("after RND Balance: " + rndBalance);
    let dexRouterBalance = await ethers.provider.getBalance(dexRouter.address)
    assert.equal(adapterBalance1+adapterBalance2, 0,"adapter has eth left");
    assert.equal(dexRouterBalance, 0,"dexRouter has eth left");
    assert.equal(rndBalance,7554274398053476814039960140,"rnd balance error")
}

async function initWETHUSDCParams(fromTokenAmount) {
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const uniV2PoolAddr = "0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc"; // USDC-WETH Pool
    const uniV3PoolAddr = "0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8"; // USDC-WETH V3 0.3% Pool
    const bntusdcPoolAddr = "0x23d1b2755d6C243DFa9Dd06624f1686b9c9E13EB";
    const ethbntPoolAddr = "0x4c9a2bd661d640da3634a4988a9bd2bc0f18e5a9";

    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [0]
    // ];
    // const requestParam2 = [
    //     tokenConfig.tokens.BNT.baseTokenAddress,
    //     [0]
    // ];
    const mixAdapter1 = [
        univ2Adapter.address,
        univ3Adapter.address,
        bancorAdapter.address
    ];
    const mixAdapter2 = [
        bancorAdapter.address
    ];
    const assertTo1 = [
        uniV2PoolAddr,
        univ3Adapter.address,
        bancorAdapter.address
    ];
    const assertTo2 = [
        bancorAdapter.address
    ];

    const weight1 = 1000;
    const weight2 = 8000;
    const weight3 = 1000;
    const weight4 = 10000;

    const rawData1 = [
        packRawData(tokenConfig.tokens.WETH.baseTokenAddress,tokenConfig.tokens.USDC.baseTokenAddress,weight1,uniV2PoolAddr),
        packRawData(tokenConfig.tokens.WETH.baseTokenAddress,tokenConfig.tokens.USDC.baseTokenAddress,weight2,uniV3PoolAddr),
        packRawData(tokenConfig.tokens.WETH.baseTokenAddress,tokenConfig.tokens.BNT.baseTokenAddress,weight3,ethbntPoolAddr),
    ];

    const rawData2 = [packRawData(tokenConfig.tokens.BNT.baseTokenAddress,tokenConfig.tokens.USDC.baseTokenAddress,weight4,bntusdcPoolAddr)];

    const moreInfo1 = "0x"
    const moreInfo2 = ethers.utils.defaultAbiCoder.encode(
        ["uint160", "bytes"],
        [
            "1353119835187591902566005712305392",
            ethers.utils.defaultAbiCoder.encode(
                ["address", "address", "uint24"],
                [
                    WETH.address,
                    USDC.address,
                    3000
                ]
            )
        ]
    )
    const moreInfo3 = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            ETH.address,                               // from token address
            BNT.address                                // to token address
        ]
    )
    const moreInfo4 = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            BNT.address,                               // from token address
            USDC.address                                // to token address
        ]
    )

    const extraData1 = [moreInfo1,moreInfo2,moreInfo3];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1,WETH.address];

    const extraData2 = [moreInfo4];
    const router2 = [mixAdapter2, assertTo2, rawData2, extraData2,BNT.address];

    // layer1
    // const request1 = [requestParam1,requestParam2];
    const layer1 = [router1,router2];

    const baseRequest = [
        WETH.address,
        USDC.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    // reqs = [request1]
    layers = [layer1]
    return {baseRequest, layers}
}

// weth ->  usdc  (univ2)
//      ->  usdc  (uniV3)
//      ->  bnt  -> usdc (bancor)
async function executeWEth2USDC() {

    await setForkBlockNumber(14480567);
    const accountAddress = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    const { WETH, RND, BNT, USDC, AAVE } = await initToken();
    const { dexRouter, tokenApprove } = await initDexRouter(WETH.address);

    await initAdapter()

    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before USDC Balance: " + await USDC.balanceOf(account.address));

    const fromTokenAmount = ethers.utils.parseEther("0.06325");
    const {baseRequest,layers} = await initWETHUSDCParams(fromTokenAmount)

    await WETH.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        layers,
        pmmReq
    );

    let udscBalance = await USDC.balanceOf(account.address);
    let adapterBalance1 = await ethers.provider.getBalance(univ2Adapter.address);
    let adapterBalance2 = await ethers.provider.getBalance(univ3Adapter.address);
    let adapterBalance3 = await ethers.provider.getBalance(univ3Adapter.address);
    console.log("after univ2 WETH Balance: " + adapterBalance1);
    console.log("after univ3 WETH Balance: " + adapterBalance2);
    console.log("after bancor BNT Balance: " + adapterBalance3);
    console.log("after USDC Balance: " + udscBalance);
    let dexRouterBalance = await ethers.provider.getBalance(dexRouter.address)
    assert.equal(adapterBalance1+adapterBalance2+adapterBalance3, 0,"adapter has eth left");
    assert.equal(dexRouterBalance, 0,"dexRouter has eth left");
    assert.equal(udscBalance,215997337,"usdc balance error")
}

async function initWETHAAVEParams(fromTokenAmount) {
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const balancerPoolAddr = "0xc697051d1c6296c24ae3bcef39aca743861d9a81"; // AAVE-WETH Pool
    const balancerV2PoolId = "0x01abc00e86c7e258823b9a055fd62ca6cf61a16300010000000000000000003b";
    const uniV3PoolAddr = "0xdceaf5d0e5e0db9596a47c0c4120654e80b1d706" // AAVE-USDC

    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [0]
    // ];
    // const requestParam2 = [
    //     tokenConfig.tokens.AAVE.baseTokenAddress,
    //     [0]
    // ];
    const mixAdapter1 = [
        balancerAdapter.address,
        balancerV2Adapter.address
    ];
    const mixAdapter2 = [
        univ3Adapter.address
    ];
    const assertTo1 = [
        balancerAdapter.address,
        balancerV2Adapter.address
    ];
    const assertTo2 = [
        univ3Adapter.address
    ];
    const weight1 = Number(2000).toString(16).replace('0x', '');
    const weight2 = Number(8000).toString(16).replace('0x', '');
    const weight3 = Number(10000).toString(16).replace('0x', '');
    const rawData1 = [
        "0x" +
        direction(tokenConfig.tokens.WETH.baseTokenAddress, tokenConfig.tokens.AAVE.baseTokenAddress) +
        "0000000000000000000" +
        weight1 +
        balancerPoolAddr.replace("0x", ""),
        "0x" +
        direction(tokenConfig.tokens.WETH.baseTokenAddress, tokenConfig.tokens.AAVE.baseTokenAddress) +
        "0000000000000000000" +
        weight2 +
        balancerVault.replace("0x", "")
    ];
    const rawData2 = [
        "0x" +
        direction(tokenConfig.tokens.AAVE.baseTokenAddress, tokenConfig.tokens.USDC.baseTokenAddress) +
        "0000000000000000000" +
        weight1 +
        uniV3PoolAddr.replace("0x", "")
    ];
    const moreInfo1 = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            WETH.address,                               // from token address
            AAVE.address                                // to token address
        ]
    )
    const moreInfo2 = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bytes32"],
        [
            WETH.address,                               // from token address
            AAVE.address,                               // to token address
            balancerV2PoolId                            // pool id
        ]
    )
    const moreInfo3 = ethers.utils.defaultAbiCoder.encode(
        ["uint160", "bytes"],
        [
            0,
            ethers.utils.defaultAbiCoder.encode(
                ["address", "address", "uint24"],
                [
                    AAVE.address,
                    USDC.address,
                    3000
                ]
            )
        ]
    )

    const extraData1 = [moreInfo1,moreInfo2];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1,WETH.address];
    const extraData2 = [moreInfo3];
    const router2 = [mixAdapter2, assertTo2, rawData2, extraData2,AAVE.address];
    // layer1
    // const request1 = [requestParam1,requestParam2];
    const layer1 = [router1,router2];

    const baseRequest = [
        WETH.address,
        USDC.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    // reqs = [request1]
    layers = [layer1]
    return {baseRequest, layers}
}

// weth ->  aave  (balancer) -> usdc (univ3)
//      ->  aave  (balancerv2) -> usdc (univ3)
async function executeWEth2AAVE() {

    await setForkBlockNumber(14436483);

    const accountAddress = "0x260edfea92898a3c918a80212e937e6033f8489e";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    const { WETH, RND, BNT, USDC, AAVE } = await initToken();
    const { dexRouter, tokenApprove } = await initDexRouter(WETH.address);

    await initAdapter()

    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before USDC Balance: " + await USDC.balanceOf(account.address));

    const fromTokenAmount = ethers.utils.parseEther("0.1");
    const {baseRequest,layers} = await initWETHAAVEParams(fromTokenAmount)

    await WETH.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        layers,
        pmmReq
    );

    let udscBalance = await USDC.balanceOf(account.address);
    let adapterBalance1 = await ethers.provider.getBalance(balancerAdapter.address);
    let adapterBalance2 = await ethers.provider.getBalance(balancerV2Adapter.address);
    console.log("after USDC Balance: " + udscBalance);
    console.log("after balancer WETH Balance: " + adapterBalance1);
    console.log("after balancerV2 WETH Balance: " + adapterBalance2);
    let dexRouterBalance = await ethers.provider.getBalance(dexRouter.address)
    assert.equal(adapterBalance1+adapterBalance2, 0,"adapter has eth left");
    assert.equal(dexRouterBalance, 0,"dexRouter has eth left");
    assert.equal(udscBalance,4154142,"usdc balance error")

}


async function initETHRNDParams(fromTokenAmount) {
    const minReturnAmount = 0;
    const deadLine = FOREVER;
    const uniV2PoolAddr = "0x5449bd1a97296125252db2d9cf23d5d6e30ca3c1"; // RND-WETH Pool
    const uniV3PoolAddr = "0x96b0837489d046A4f5aA9ac2FC9e086bD14Bac1E"; // RND-WETH V3 Pool
    // node1
    // const requestParam1 = [
    //     tokenConfig.tokens.WETH.baseTokenAddress,
    //     [0]
    // ];
    const mixAdapter1 = [
        univ2Adapter.address,
        univ3Adapter.address
    ];
    const assertTo1 = [
        uniV2PoolAddr,
        univ3Adapter.address
    ];


    const weight1 = 2000;
    const weight2 = 8000;

    const rawData1 = [
        packRawData(tokenConfig.tokens.WETH.baseTokenAddress,tokenConfig.tokens.RND.baseTokenAddress,weight1,uniV2PoolAddr),
        packRawData(tokenConfig.tokens.WETH.baseTokenAddress,tokenConfig.tokens.RND.baseTokenAddress,weight2,uniV3PoolAddr)
    ];

    const moreInfo1 = "0x"
    const moreInfo2 = ethers.utils.defaultAbiCoder.encode(
        ["uint160", "bytes"],
        [
            // "888971540474059905480051",
            0,
            ethers.utils.defaultAbiCoder.encode(
                ["address", "address", "uint24"],
                [
                    WETH.address,
                    RND.address,
                    10000
                ]
            )
        ]
    )
    const extraData1 = [moreInfo1,moreInfo2];
    const router1 = [mixAdapter1, assertTo1, rawData1, extraData1, WETH.address];

    // layer1
    // const request1 = [requestParam1];
    const layer1 = [router1];

    const baseRequest = [
        ETH.address,
        RND.address,
        fromTokenAmount,
        minReturnAmount,
        deadLine,
    ]
    // reqs = [request1]
    layers = [layer1]
    return {baseRequest, layers}
}

// eth ->  rnd  (univ2)
//      ->  rnd  (uniV3)
async function executeEth2RND() {

    await setForkBlockNumber(14446603);
    const accountAddress = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    const { WETH, RND, BNT, USDC, AAVE } = await initToken();
    const { dexRouter, tokenApprove } = await initDexRouter(WETH.address);

    await initAdapter()

    console.log("before ETH Balance: " + await account.getBalance());
    console.log("before RND Balance: " + await RND.balanceOf(account.address));

    const fromTokenAmount = ethers.utils.parseEther("1");
    const {baseRequest,layers} = await initETHRNDParams(fromTokenAmount)

    // await WETH.connect(account).approve(tokenApprove.address, fromTokenAmount);
    await dexRouter.connect(account).smartSwap(
        baseRequest,
        [fromTokenAmount],
        layers,
        pmmReq,
        {value: fromTokenAmount}
    );

    let rndBalance = await RND.balanceOf(account.address);
    let adapterBalance1 = await WETH.balanceOf(univ2Adapter.address);
    let adapterBalance2 = await WETH.balanceOf(univ3Adapter.address);
    console.log("after ETH Balance: " + await account.getBalance());
    console.log("after univ2 WETH Balance: " + adapterBalance1);
    console.log("after univ3 WETH Balance: " + adapterBalance2);
    console.log("after RND Balance: " + rndBalance);
    let dexRouterBalance = await ethers.provider.getBalance(dexRouter.address)
    assert.equal(adapterBalance1+adapterBalance2, 0,"adapter has eth left");
    assert.equal(dexRouterBalance, 0,"dexRouter has eth left");
    assert.equal(rndBalance,7554274398053476814039960140,"rnd balance error")
}

async function main() {
    await executeEth2RND();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
