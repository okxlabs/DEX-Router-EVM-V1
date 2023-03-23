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
    let WETH, stETH, rETH, SETH, DAI, USDT, USDC, WBTC, BADGER;

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

    it("1.1 swapCurveV1Pools(ERC20)", async () => {
        console.log("before Account DAI Balance: " + ethers.utils.formatUnits(await DAI.balanceOf(account.address), tokenConfig.tokens.DAI.decimals));
        console.log("before Account USDT Balance: " + ethers.utils.formatUnits(await USDT.balanceOf(account.address), tokenConfig.tokens.USDT.decimals));
        console.log("before Account USDC Balance: " + ethers.utils.formatUnits(await USDC.balanceOf(account.address), tokenConfig.tokens.USDC.decimals));

        // set 100 DAI
        let fromTokenAmount = ethers.utils.parseUnits("100", tokenConfig.tokens.DAI.decimals);
        let pool1 = "0xDeBF20617708857ebe4F679508E7b7863a8A8EeE";
        let exchangeInfo1 =  ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "int128", "int128", "bool"],
            [pool1, USDC.address, 0, 1, true]
        )

        // [DAI -> USDC] 1st swap
        await DAI.connect(account).approve(tokenApprove.address, fromTokenAmount);
        await dexRouter.connect(account).swapCurveV1Pools(
            false,
            accountAddress,
            DAI.address,
            fromTokenAmount,
            0,
            [exchangeInfo1]
        );
        console.log("[100 DAI -> USDC] 1st swap: Account DAI Balance: " + ethers.utils.formatUnits(await DAI.balanceOf(account.address), tokenConfig.tokens.DAI.decimals));
        console.log("[100 DAI -> USDC] 1st swap: Account USDT Balance: " + ethers.utils.formatUnits(await USDT.balanceOf(account.address), tokenConfig.tokens.USDT.decimals));
        console.log("[100 DAI -> USDC] 1st swap: Account USDC Balance: " + ethers.utils.formatUnits(await USDC.balanceOf(account.address), tokenConfig.tokens.USDC.decimals));

        // [DAI -> USDC] 2nd swap
        await DAI.connect(account).approve(tokenApprove.address, fromTokenAmount);
        await dexRouter.connect(account).swapCurveV1Pools(
            false,
            accountAddress,
            DAI.address,
            fromTokenAmount,
            ethers.utils.parseUnits("99", tokenConfig.tokens.USDC.decimals),
            [exchangeInfo1]
        );
        console.log("[100 DAI -> USDC] 2nd swap: Account DAI Balance: " + ethers.utils.formatUnits(await DAI.balanceOf(account.address), tokenConfig.tokens.DAI.decimals));
        console.log("[100 DAI -> USDC] 2nd swap: Account USDT Balance: " + ethers.utils.formatUnits(await USDT.balanceOf(account.address), tokenConfig.tokens.USDT.decimals));
        console.log("[100 DAI -> USDC] 2nd swap: Account USDC Balance: " + ethers.utils.formatUnits(await USDC.balanceOf(account.address), tokenConfig.tokens.USDC.decimals));


        // [DAI -> USDT -> USDC] 1st swap
        let exchangeInfo2 =  ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "int128", "int128", "bool"],
            [pool1, USDT.address, 0, 2, true]
        )
        let pool2 = "0xDeBF20617708857ebe4F679508E7b7863a8A8EeE";
        let exchangeInfo3 =  ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "int128", "int128", "bool"],
            [pool2, USDC.address, 2, 1, true]
        )
        await DAI.connect(account).approve(tokenApprove.address, fromTokenAmount);
        await dexRouter.connect(account).swapCurveV1Pools(
            false,
            accountAddress,
            DAI.address,
            fromTokenAmount,
            ethers.utils.parseUnits("99", tokenConfig.tokens.USDC.decimals),
            [exchangeInfo2, exchangeInfo3]
        );
        console.log("[100 DAI -> USDT -> USDC] 1st swap: Account DAI Balance: " + ethers.utils.formatUnits(await DAI.balanceOf(account.address), tokenConfig.tokens.DAI.decimals));
        console.log("[100 DAI -> USDT -> USDC] 1st swap: Account USDT Balance: " + ethers.utils.formatUnits(await USDT.balanceOf(account.address), tokenConfig.tokens.USDT.decimals));
        console.log("[100 DAI -> USDT -> USDC] 1st swap: Account USDC Balance: " + ethers.utils.formatUnits(await USDC.balanceOf(account.address), tokenConfig.tokens.USDC.decimals));
    });

    it("1.2 swapCurveV1Pools(ETH/WETH)", async () => {
        console.log("before Account ETH Balance: " + ethers.utils.formatUnits(await account.getBalance(), tokenConfig.tokens.ETH.decimals));
        console.log("before Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("before Account stETH Balance: " + ethers.utils.formatUnits(await stETH.balanceOf(account.address), tokenConfig.tokens.stETH.decimals));

        // set 1eth
        let fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.ETH.decimals);
        let pool1 = "0x828b154032950C8ff7CF8085D841723Db2696056";
        let exchangeInfo1 =  ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "int128", "int128", "bool"],
            [pool1, stETH.address, 0, 1, false]
        )
        // [ETH -> stETH] 1st swap
        await dexRouter.connect(account).swapCurveV1Pools(
            false,
            accountAddress,
            WETH.address,
            fromTokenAmount,
            ethers.utils.parseUnits("0.9", tokenConfig.tokens.ETH.decimals),
            [exchangeInfo1],
            { value: fromTokenAmount },
        );
        console.log("[1 ETH -> stETH] 1st swap: Account ETH Balance: " + ethers.utils.formatUnits(await account.getBalance(), tokenConfig.tokens.ETH.decimals));
        console.log("[1 ETH -> stETH] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 ETH -> stETH] 1st swap: Account stETH Balance: " + ethers.utils.formatUnits(await stETH.balanceOf(account.address), tokenConfig.tokens.stETH.decimals));

        // [ETH -> stETH -> WETH] 1st swap
        let exchangeInfo2 =  ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "int128", "int128", "bool"],
            [pool1, WETH.address, 1, 0, false]
        )
        await dexRouter.connect(account).swapCurveV1Pools(
            false,
            accountAddress,
            WETH.address,
            fromTokenAmount,
            ethers.utils.parseUnits("0.9", tokenConfig.tokens.ETH.decimals),
            [exchangeInfo1, exchangeInfo2],
            { value: fromTokenAmount },
        );
        console.log("[1 ETH -> stETH -> WETH] 1st swap: Account ETH Balance: " + ethers.utils.formatUnits(await account.getBalance(), tokenConfig.tokens.ETH.decimals));
        console.log("[1 ETH -> stETH -> WETH] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 ETH -> stETH -> WETH] 1st swap: Account stETH Balance: " + ethers.utils.formatUnits(await stETH.balanceOf(account.address), tokenConfig.tokens.stETH.decimals));

        // [WETH -> stETH -> WETH] 1st swap
        console.log("before toAddress WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(to.address), tokenConfig.tokens.WETH.decimals));
        let wethAmount = ethers.utils.parseUnits("0.99", tokenConfig.tokens.WETH.decimals);
        await WETH.connect(account).approve(tokenApprove.address, wethAmount);
        await dexRouter.connect(account).swapCurveV1Pools(
            false,
            toAddress,
            WETH.address,
            wethAmount,
            ethers.utils.parseUnits("0.9", tokenConfig.tokens.ETH.decimals),
            [exchangeInfo1, exchangeInfo2],
        );
        console.log("[1 WETH -> stETH -> WETH] 1st swap: toAddress WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(to.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 WETH -> stETH -> WETH] 1st swap: Account ETH Balance: " + ethers.utils.formatUnits(await account.getBalance(), tokenConfig.tokens.ETH.decimals));
        console.log("[1 WETH -> stETH -> WETH] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 WETH -> stETH -> WETH] 1st swap: Account stETH Balance: " + ethers.utils.formatUnits(await stETH.balanceOf(account.address), tokenConfig.tokens.stETH.decimals));

        // [ETH -> stETH -> ETH] 1st swap
        console.log("before toAddress ETH Balance: " + ethers.utils.formatUnits(await to.getBalance(), tokenConfig.tokens.ETH.decimals));
        await dexRouter.connect(account).swapCurveV1Pools(
            true,
            toAddress,
            WETH.address,
            fromTokenAmount,
            ethers.utils.parseUnits("0.9", tokenConfig.tokens.ETH.decimals),
            [exchangeInfo1, exchangeInfo2],
            { value: fromTokenAmount },
        );
        console.log("[1 ETH -> stETH -> ETH] 1st swap: toAddress ETH Balance: " + ethers.utils.formatUnits(await to.getBalance(), tokenConfig.tokens.ETH.decimals));
        console.log("[1 ETH -> stETH -> ETH] 1st swap: Account ETH Balance: " + ethers.utils.formatUnits(await account.getBalance(), tokenConfig.tokens.ETH.decimals));
        console.log("[1 ETH -> stETH -> ETH] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 ETH -> stETH -> ETH] 1st swap: Account stETH Balance: " + ethers.utils.formatUnits(await stETH.balanceOf(account.address), tokenConfig.tokens.stETH.decimals));

        // [WETH -> stETH -> ETH] 1st swap
        console.log("before toAddress ETH Balance: " + ethers.utils.formatUnits(await to.getBalance(), tokenConfig.tokens.ETH.decimals));
        await WETH.connect(account).deposit({value: fromTokenAmount});
        await WETH.connect(account).approve(tokenApprove.address, fromTokenAmount);
        await dexRouter.connect(account).swapCurveV1Pools(
            true,
            toAddress,
            WETH.address,
            fromTokenAmount,
            ethers.utils.parseUnits("0.9", tokenConfig.tokens.ETH.decimals),
            [exchangeInfo1, exchangeInfo2],
        );
        console.log("[1 WETH -> stETH -> ETH] 1st swap: toAddress ETH Balance: " + ethers.utils.formatUnits(await to.getBalance(), tokenConfig.tokens.ETH.decimals));
        console.log("[1 WETH -> stETH -> ETH] 1st swap: Account ETH Balance: " + ethers.utils.formatUnits(await account.getBalance(), tokenConfig.tokens.ETH.decimals));
        console.log("[1 WETH -> stETH -> ETH] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 WETH -> stETH -> ETH] 1st swap: Account stETH Balance: " + ethers.utils.formatUnits(await stETH.balanceOf(account.address), tokenConfig.tokens.stETH.decimals));
    })

    it("2.1 swapCurveV2Pools(ERC20)", async () => {
        console.log("before Account USDT Balance: " + ethers.utils.formatUnits(await USDT.balanceOf(account.address), tokenConfig.tokens.USDT.decimals));
        console.log("before Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));
        console.log("before Account BADGER Balance: " + ethers.utils.formatUnits(await BADGER.balanceOf(account.address), tokenConfig.tokens.BADGER.decimals));

        // set 1000 USDT
        let fromTokenAmount = ethers.utils.parseUnits("1000", tokenConfig.tokens.USDT.decimals);
        let pool1 = "0xD51a44d3FaE010294C616388b506AcdA1bfAAE46";
        let exchangeInfo1 =  ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256"],
            [pool1, WBTC.address, 0, 1]
        )

        // [USDT -> WBTC] 1st swap
        await USDT.connect(account).approve(tokenApprove.address, fromTokenAmount);
        await dexRouter.connect(account).swapCurveV2Pools(
            false,
            accountAddress,
            USDT.address,
            fromTokenAmount,
            0,
            [exchangeInfo1]
        );
        console.log("[1000 USDT -> WBTC] 1st swap: Account USDT Balance: " + ethers.utils.formatUnits(await USDT.balanceOf(account.address), tokenConfig.tokens.USDT.decimals));
        console.log("[1000 USDT -> WBTC] 1st swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));
        console.log("[1000 USDT -> WBTC] 1st swap: Account BADGER Balance: " + ethers.utils.formatUnits(await BADGER.balanceOf(account.address), tokenConfig.tokens.BADGER.decimals));

        // [USDT -> WBTC] 2nd swap
        await USDT.connect(account).approve(tokenApprove.address, fromTokenAmount);
        await dexRouter.connect(account).swapCurveV2Pools(
            false,
            accountAddress,
            USDT.address,
            fromTokenAmount,
            ethers.utils.parseUnits("0.01", tokenConfig.tokens.WBTC.decimals),
            [exchangeInfo1]
        );
        console.log("[1000 USDT -> WBTC] 2nd swap: Account USDT Balance: " + ethers.utils.formatUnits(await USDT.balanceOf(account.address), tokenConfig.tokens.USDT.decimals));
        console.log("[1000 USDT -> WBTC] 2nd swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));
        console.log("[1000 USDT -> WBTC] 2nd swap: Account BADGER Balance: " + ethers.utils.formatUnits(await BADGER.balanceOf(account.address), tokenConfig.tokens.BADGER.decimals));

        // [USDT -> WBTC -> BADGER] 1st swap
        let pool2 = "0x50f3752289e1456BfA505afd37B241bca23e685d";
        let exchangeInfo2 =  ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256"],
            [pool2, BADGER.address, 1, 0]
        )
        await USDT.connect(account).approve(tokenApprove.address, fromTokenAmount);
        await dexRouter.connect(account).swapCurveV2Pools(
            false,
            accountAddress,
            USDT.address,
            fromTokenAmount,
            0,
            [exchangeInfo1, exchangeInfo2]
        );
        console.log("[1000 USDT -> WBTC -> BADGER] 1st swap: Account USDT Balance: " + ethers.utils.formatUnits(await USDT.balanceOf(account.address), tokenConfig.tokens.USDT.decimals));
        console.log("[1000 USDT -> WBTC -> BADGER] 1st swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));
        console.log("[1000 USDT -> WBTC -> BADGER] 1st swap: Account BADGER Balance: " + ethers.utils.formatUnits(await BADGER.balanceOf(account.address), tokenConfig.tokens.BADGER.decimals));
    });

    it("2.2 swapCurveV2Pools(ETH/WETH)", async () => {
        ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
        console.log("before Account ETH Balance: " + ethers.utils.formatUnits(await account.getBalance(), tokenConfig.tokens.ETH.decimals));
        console.log("before Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals)); // 2
        console.log("before Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals)); // 1

        // set 1eth
        let fromTokenAmount = ethers.utils.parseUnits("1", tokenConfig.tokens.ETH.decimals);
        let pool1 = "0xd51a44d3fae010294c616388b506acda1bfaae46";
        let exchangeInfo1 =  ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256"],
            [pool1, WBTC.address, 2, 1]
        )
        // [ETH -> WBTC] 1st swap
        await dexRouter.connect(account).swapCurveV2Pools(
            false,
            accountAddress,
            ETH.address,
            fromTokenAmount,
            ethers.utils.parseUnits("0.001", tokenConfig.tokens.WBTC.decimals),
            [exchangeInfo1],
            { value: fromTokenAmount },
        );
        console.log("[1 ETH -> WBTC] 1st swap: Account ETH Balance: " + ethers.utils.formatUnits(await account.getBalance(), tokenConfig.tokens.ETH.decimals));
        console.log("[1 ETH -> WBTC] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 ETH -> WBTC] 1st swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));

        // [ETH -> WBTC -> WETH] 1st swap
        console.log("before toAddress WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(toAddress), tokenConfig.tokens.WETH.decimals));
        let exchangeInfo2 =  ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256", "uint256"],
            [pool1, WETH.address, 1, 2]
        )
        await dexRouter.connect(account).swapCurveV2Pools(
            false,
            toAddress,
            ETH.address,
            fromTokenAmount,
            0,
            [exchangeInfo1, exchangeInfo2],
            { value: fromTokenAmount },
        );
        console.log("[1 ETH -> WBTC -> WETH] 1st swap: toAddress WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(toAddress), tokenConfig.tokens.WETH.decimals));
        console.log("[1 ETH -> WBTC -> WETH] 1st swap: Account ETH Balance: " + ethers.utils.formatUnits(await account.getBalance(), tokenConfig.tokens.ETH.decimals));
        console.log("[1 ETH -> WBTC -> WETH] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 ETH -> WBTC -> WETH] 1st swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));

        // [ETH -> WBTC -> ETH] 1st swap
        console.log("before toAddress ETH Balance: " + ethers.utils.formatUnits(await to.getBalance(), tokenConfig.tokens.ETH.decimals));
        await dexRouter.connect(account).swapCurveV2Pools(
            true,
            toAddress,
            ETH.address,
            fromTokenAmount,
            0,
            [exchangeInfo1, exchangeInfo2],
            { value: fromTokenAmount },
        );
        console.log("[1 ETH -> WBTC -> ETH] 1st swap: toAddress ETH Balance: " + ethers.utils.formatUnits(await to.getBalance(), tokenConfig.tokens.ETH.decimals));
        console.log("[1 ETH -> WBTC -> ETH] 1st swap: Account ETH Balance: " + ethers.utils.formatUnits(await account.getBalance(), tokenConfig.tokens.ETH.decimals));
        console.log("[1 ETH -> WBTC -> ETH] 1st swap: Account WETH Balance: " + ethers.utils.formatUnits(await WETH.balanceOf(account.address), tokenConfig.tokens.WETH.decimals));
        console.log("[1 ETH -> WBTC -> ETH] 1st swap: Account WBTC Balance: " + ethers.utils.formatUnits(await WBTC.balanceOf(account.address), tokenConfig.tokens.WBTC.decimals));
    })


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

        await dexRouter.setPriorityAddress(xBridge.address, true);
    }
})