const { ethers, network, upgrades} = require("hardhat");

require ('../scripts/tools');
const {FOREVER, direction} = require("../scripts/test_scripts/dex_router/utils");

const { BigNumber } = require('ethers');
let { WUST } = require("../scripts/config/eth/tokens");
let { getConfig } = require("../scripts/config");
const {startMockAccount} = require("../scripts/tools/chain");
const pmm_params = require("./pmm/pmm_params");
const {expect} = require("chai");
const ethDeployed = require("../scripts/deployed/eth");
tokenConfig = getConfig("eth");

describe("curve router", function(){
    this.timeout(300000000);

    let accountAddress = "0xf0226d453a665B8f41a5280C020c8FE939cCeD5b"; // mainnet rich address
    let account;
    let toAddress = "0x5012113e8B095a01a5A461Aa865C92cB049eEDae"; // mainnet random address
    let to;

    let tokenApprove, dexRouter, xBridge, WNativeRelayer, OneInchRouter;
    let WETH, stETH, rETH, SETH, DAI, USDT, USDC, WBTC, BADGER, AAVE;

    const setForkBlockNumber = async (targetBlockNumber) => {
        const INFURA_KEY = process.env.INFURA_KEY || '';
        await network.provider.request({
            method: "hardhat_reset",
            params: [
                {
                    forking: {
                        // jsonRpcUrl: `https://eth-mainnet.alchemyapi.io/v2/4Gs3eLxFQj6r-YYp2gYDn1e2Vzru0Le9`,
                        // jsonRpcUrl: `http://35.75.165.133:8545 `,
                        jsonRpcUrl: `https://rpc.ankr.com/eth`,
                        // jsonRpcUrl: `https://mainnet.infura.io/v3/${INFURA_KEY}`,
                        blockNumber: targetBlockNumber,
                    },
                },
            ],
        });
    }

    beforeEach(async function() {
        await setForkBlockNumber(16117820);
        await startMockAccount([accountAddress]);
        account = await ethers.getSigner(accountAddress);
        await startMockAccount([toAddress]);
        to = await ethers.getSigner(toAddress);

        await initTokens();
        await initTokenApproveProxy();
        await initDexRouter();
        await initMockXBridge();
        await initWNativeRelayer();
    });

    it("1. swapBalancerV1Pools()", async () => {
        console.log("before Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("before Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));

        // set 1 WETH
        let fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.WETH.decimals);
        let pool1 = "0x1eff8af5d577060ba4ac8a29a13525bb0ee2a3d5";
        let exchangeInfo1 =  ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [pool1, WBTC.address]
        )

        // [WETH -> WBTC] 1st swap
        await WETH.connect(account).deposit({value: fromTokenAmount});
        await WETH.connect(account).approve(tokenApprove.address, fromTokenAmount);
        let tx = await dexRouter.connect(account).swapBalancerV1Pools(
            false,
            accountAddress,
            WETH.address,
            fromTokenAmount,
            0,
            [exchangeInfo1]
        );
        // console.log("tx", tx);
        console.log("[1 WETH -> WBTC] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 WETH -> WBTC] 1st swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));

        // [ETH -> WBTC] 2nd swap
        await dexRouter.connect(account).swapBalancerV1Pools(
            false,
            accountAddress,
            WETH.address,
            fromTokenAmount,
            0,
            [exchangeInfo1],
            { value: fromTokenAmount}
        );
        console.log("[1 ETH -> WBTC] 2nd swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 ETH -> WBTC] 2nd swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));


        // [ETH -> WBTC -> WETH] 1st swap
        console.log("before toAddress WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(to.address), tokenConfig.tokens.WETH.decimals));
        let pool2 = "0xa751A143f8fe0a108800Bfb915585E4255C2FE80";
        let exchangeInfo2 =  ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [pool2, WETH.address]
        )
        await dexRouter.connect(account).swapBalancerV1Pools(
            false,
            toAddress,
            WETH.address,
            fromTokenAmount,
            0,
            [exchangeInfo1, exchangeInfo2],
            { value: fromTokenAmount}
        );
        console.log("[1 WETH -> WBTC] 1st swap: toAddress WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(to.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 WETH -> WBTC] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 WETH -> WBTC] 1st swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));

        // [ETH -> WBTC -> ETH] 1st swap
        console.log("before toAddress ETH Balance: " + ethers.utils.formatUnits(await to.getBalance(), tokenConfig.tokens.WETH.decimals));
        await dexRouter.connect(account).swapBalancerV1Pools(
            true,
            toAddress,
            WETH.address,
            fromTokenAmount,
            0,
            [exchangeInfo1, exchangeInfo2],
            { value: fromTokenAmount}
        );
        console.log("[1 WETH -> WBTC] 1st swap: toAddress ETH Balance: " + ethers.utils.formatUnits(await to.getBalance(), tokenConfig.tokens.WETH.decimals));
        console.log("[1 WETH -> WBTC] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 WETH -> WBTC] 1st swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));
    });

    it("2. swapBalancerV2Pools()", async () => {
        console.log("before Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("before Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));

        // set 1 WETH
        let fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.WETH.decimals);
        let poolId1 = "0xa6f548df93de924d73be7d25dc02554c6bd66db500020000000000000000000e";
        let exchangeInfo1 =  ethers.utils.defaultAbiCoder.encode(
            ["bytes32", "address"],
            [poolId1, WBTC.address]
        )

        // [WETH -> WBTC] 1st swap
        await WETH.connect(account).deposit({value: fromTokenAmount});
        await WETH.connect(account).approve(tokenApprove.address, fromTokenAmount);
        let tx = await dexRouter.connect(account).swapBalancerV2Pools(
            false,
            accountAddress,
            WETH.address,
            fromTokenAmount,
            0,
            [exchangeInfo1]
        );
        // console.log("tx", tx);
        console.log("[1 WETH -> WBTC] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 WETH -> WBTC] 1st swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));

        // [ETH -> WBTC] 2nd swap
        await dexRouter.connect(account).swapBalancerV2Pools(
            false,
            accountAddress,
            WETH.address,
            fromTokenAmount,
            0,
            [exchangeInfo1],
            { value: fromTokenAmount}
        );
        console.log("[1 ETH -> WBTC] 2nd swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 ETH -> WBTC] 2nd swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));


        // [ETH -> WBTC -> WETH] 1st swap
        console.log("before toAddress WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(to.address), tokenConfig.tokens.WETH.decimals));
        let poolId2 = "0xd4e2af4507b6b89333441c0c398edffb40f86f4d0001000000000000000002ab";
        let exchangeInfo2 =  ethers.utils.defaultAbiCoder.encode(
            ["bytes32", "address"],
            [poolId2, WETH.address]
        )
        await dexRouter.connect(account).swapBalancerV2Pools(
            false,
            toAddress,
            WETH.address,
            fromTokenAmount,
            0,
            [exchangeInfo1, exchangeInfo2],
            { value: fromTokenAmount}
        );
        console.log("[1 WETH -> WBTC] 1st swap: toAddress WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(to.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 WETH -> WBTC] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 WETH -> WBTC] 1st swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));

        // [ETH -> WBTC -> ETH] 1st swap
        console.log("before toAddress ETH Balance: " + ethers.utils.formatUnits(await to.getBalance(), tokenConfig.tokens.WETH.decimals));
        await dexRouter.connect(account).swapBalancerV2Pools(
            true,
            toAddress,
            WETH.address,
            fromTokenAmount,
            0,
            [exchangeInfo1, exchangeInfo2],
            { value: fromTokenAmount}
        );
        console.log("[1 WETH -> WBTC] 1st swap: toAddress ETH Balance: " + ethers.utils.formatUnits(await to.getBalance(), tokenConfig.tokens.WETH.decimals));
        console.log("[1 WETH -> WBTC] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 WETH -> WBTC] 1st swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));
    });

    const initTokens = async () => {
        WETH = await ethers.getContractAt("WETH9", ethDeployed.tokens.weth);
        stETH = await ethers.getContractAt("MockERC20", tokenConfig.tokens.stETH.baseTokenAddress)
        rETH = await ethers.getContractAt("MockERC20", tokenConfig.tokens.rETH.baseTokenAddress)
        SETH = await ethers.getContractAt("MockERC20", tokenConfig.tokens.SETH.baseTokenAddress)

        DAI = await ethers.getContractAt("MockERC20", tokenConfig.tokens.DAI.baseTokenAddress)
        USDT = await ethers.getContractAt("MockERC20", tokenConfig.tokens.USDT.baseTokenAddress)
        USDC = await ethers.getContractAt("MockERC20", tokenConfig.tokens.USDC.baseTokenAddress)

        WBTC = await ethers.getContractAt("MockERC20", tokenConfig.tokens.WBTC.baseTokenAddress)
        BADGER = await ethers.getContractAt("MockERC20", tokenConfig.tokens.BADGER.baseTokenAddress)

        AAVE = await ethers.getContractAt("MockERC20", tokenConfig.tokens.AAVE.baseTokenAddress)
    }

    const initTokenApproveProxy = async () => {
        tokenApproveProxy = await ethers.getContractAt(
            "TokenApproveProxy",
            ethDeployed.base.tokenApproveProxy

        );
        tokenApprove = await ethers.getContractAt(
            "TokenApprove",
            ethDeployed.base.tokenApprove
        );
    }

    const initDexRouter = async () => {
        let _feeRateAndReceiver = "0x000000000000000000000000" + pmm_params.feeTo.slice(2);
        DexRouter = await ethers.getContractFactory("DexRouterV2");
        dexRouter = await upgrades.deployProxy(
            DexRouter,[
                _feeRateAndReceiver
            ]
        )


        await dexRouter.deployed();

        // await dexRouter.setApproveProxy(tokenApproveProxy.address);
        expect(await dexRouter._WETH()).to.be.equal(WETH.address);
        expect(await dexRouter._APPROVE_PROXY()).to.be.equal(tokenApproveProxy.address);

        let accountAddress = await tokenApproveProxy.owner();
        startMockAccount([accountAddress]);
        tokenApproveProxyOwner = await ethers.getSigner(accountAddress);
        setBalance(tokenApproveProxyOwner.address, '0x56bc75e2d63100000');

        await tokenApproveProxy.connect(tokenApproveProxyOwner).addProxy(dexRouter.address);
        await tokenApproveProxy.connect(tokenApproveProxyOwner).setTokenApprove(tokenApprove.address);
    }

    const initWNativeRelayer = async () => {
        wNativeRelayer = await ethers.getContractAt(
            "WNativeRelayer",
            ethDeployed.base.wNativeRelayer

        );
        let accountAddress = await wNativeRelayer.owner();
        startMockAccount([accountAddress]);
        wNativeRelayerOwner = await ethers.getSigner(accountAddress);
        setBalance(wNativeRelayerOwner.address, '0x56bc75e2d63100000');
        await wNativeRelayer.connect(wNativeRelayerOwner).setCallerOk([dexRouter.address], [true]);
        expect(await dexRouter._WNATIVE_RELAY()).to.be.equal(wNativeRelayer.address);
    }

    const initMockXBridge = async () => {
        xBridge = await ethers.getContractAt(
            "MockXBridge",
            ethDeployed.base.xbridge
        );
        let accountAddress = await xBridge.admin();

        startMockAccount([accountAddress]);
        XBridgeOwner = await ethers.getSigner(accountAddress);
        setBalance(XBridgeOwner.address, '0x56bc75e2d63100000');

        await xBridge.connect(XBridgeOwner).setDexRouter(dexRouter.address);

        //await xBridge.connect(XBridgeOwner).setMpc([alice.address],[true]);
        await xBridge.connect(XBridgeOwner).setApproveProxy(tokenApproveProxy.address);

        await dexRouter.setXBridge(xBridge.address);
    }
})