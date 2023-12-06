const { ethers, upgrades, network} = require("hardhat");
const hre = require("hardhat");
const { BigNumber } = require('ethers')
const { expect } = require("chai");
const ethDeployed = require("../scripts/deployed/eth");
const pmm_params = require("../dex_router_v2_test/pmm/pmm_params");
const { getDaiLikePermitDigest, sign } = require('../dex_router_v2_test/signatures')

require ('../scripts/tools');


describe("Test unxswapV3 path with commission", function() {
    this.timeout(300000);
    let weth, usdc, dai, busd, lpDAIBUSD, lpDAIWETH;
    let tokenApprove, dexRouter, xBridge, WNativeRelayer, OneInchRouter;
    let owner, alice, bob, wNativeRelayerOwner, XBridgeOwner;

    const ETH = {"address":'0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'};
    const feeReceiver = "0x94d3af948652ea2b272870ffa10da3250e0a34c3" // unibot address
    const fee = ethers.BigNumber.from(100).toHexString()
    const commissionFlag = "0x3ca20afc2aaa"
    const commissionInfo = "0x"+commissionFlag.replace('0x','')+'0000000000'+fee.replace('0x','')+feeReceiver.replace('0x','')
    // const commissionInfo = "0x3ca20afc2aaa00000000006494d3af948652ea2b272870ffa10da3250e0a34c3"; // unibot address, with commission fee 100/10000

    beforeEach(async function() {
      [owner,alice, bob, tom] = await ethers.getSigners();
      await setForkBlockNumber(16094434); 
      await initWeth();
      await initTokenApproveProxy();
      await initDexRouter();
      await initMockXBridge();
      await initWNativeRelayer();
      await initAccounts();
      await initTokens();
      await initOneInchRouter();
    });


    // ERC20 -> ERC20 : OKX V2 135623 vs OKX V1 190513 vs 1inch V5 114119, 优化29%
    it("1. ERC20 -> ERC20 with commission", async () => {
        // DAI -> BUSD
        let token0 = await lpDAIBUSD.token0();
        let fromToken = dai;
        let toToken = busd;
        // unwrap = 0
        flag = fromToken.address == token0 ? "0x0" : "0x8";
        pool0 = flag + '00000000000000000000000' + lpDAIBUSD.address.slice(2);

        const totalAmount = ethers.utils.parseEther('0.1');
        const commissionAmount = totalAmount.mul(fee).div(10000)
        const fromTokenAmount = totalAmount.sub(commissionAmount)
        let minReturn = ethers.utils.parseEther('0.09');

        // 2. swap
        await fromToken.connect(bob).approve(tokenApprove.address, ethers.utils.parseEther('10000'));

        let rawInfo = await dexRouter.connect(bob).populateTransaction.uniswapV3SwapTo(
            tom.address,
            fromTokenAmount,
            minReturn,
            [pool0]
        );
        rawInfo.data = rawInfo.data + commissionInfo.replace('0x','')
        let tx = await bob.sendTransaction(rawInfo)
        let receipt = await tx.wait()

        expect(await fromToken.balanceOf(feeReceiver)).to.be.equal(commissionAmount)
        expect(await toToken.balanceOf(tom.address)).to.be.equal("98988016503682195")


    })

    // ERC20 -> native: OKX V2 165811 vs OKX V1 ~220000 vs 1inch V5 113933，优化25%
    it("2. ERC20 -> native with commission", async () => {
        // DAI -> ETH
        let token0 = await lpDAIWETH.token0();
        let fromToken = dai;
        let toToken = ETH;
        // unwrap = 1
        flag = dai.address == token0 ? "0x2" : "0xa";
        pool0 = flag + '00000000000000000000000' + lpDAIWETH.address.slice(2);

        const totalAmount = ethers.utils.parseEther('0.1');
        const commissionAmount = totalAmount.mul(fee).div(10000)
        const fromTokenAmount = totalAmount.sub(commissionAmount)
        let minReturn = ethers.utils.parseEther('0.00001');

        // 2. swap

        await dai.connect(bob).approve(tokenApprove.address, ethers.utils.parseEther('10000'));

        let rawInfo = await dexRouter.connect(bob).populateTransaction.uniswapV3SwapTo(
            tom.address,
            fromTokenAmount,
            minReturn,
            [pool0]
        );
        rawInfo.data = rawInfo.data + commissionInfo.replace('0x','')
        let tx = await bob.sendTransaction(rawInfo)
        let receipt = await tx.wait()


        // 3. check 
        expect(await fromToken.balanceOf(feeReceiver)).to.be.equal(commissionAmount)
        expect(await ethers.provider.getBalance(tom.address)).to.be.equal("10000000077705569872760")

    })


    // native -> ERC20: OKX V2 116505 vs OKX V1 171390 vs 1inch V5 108400，优化32%
    it("3. native -> ERC20 with commission", async () => {
        // ETH -> DAI
        let token0 = await lpDAIWETH.token0();
        let fromToken = ETH;
        let toToken = dai;
        // unwrap = 0
        flag = weth.address == token0 ? "0x0" : "0x8";
        pool0 = flag + '00000000000000000000000' + lpDAIWETH.address.slice(2);

        const totalAmount = ethers.utils.parseEther('1');
        const commissionAmount = totalAmount.mul(fee).div(10000)
        const fromTokenAmount = totalAmount.sub(commissionAmount)
        let minReturn = ethers.utils.parseEther('1000');

        // 2. swap
        let fromBalBeforeTx = await ethers.provider.getBalance(bob.address);
        let toBalBeforeTx = await dai.balanceOf(bob.address);
        let rawInfo = await dexRouter.connect(bob).populateTransaction.uniswapV3SwapTo(
            tom.address,
            fromTokenAmount,
            minReturn,
            [pool0],
            {
                value: totalAmount
            }
        );
        rawInfo.data = rawInfo.data + commissionInfo.replace('0x','')
        let tx = await bob.sendTransaction(rawInfo)
        let receipt = await tx.wait()

        expect(await ethers.provider.getBalance(feeReceiver)).to.be.equal(commissionAmount)
        expect(await toToken.balanceOf(tom.address)).to.be.equal("1259976436924206629708")
    });

    // two hops: OKX V2 245631 vs OKX V1 ~300000 vs 1inch V5 193359
    it("4. two hops with commission", async () => {
        // BUSD -> DAI -> ETH
        let fromToken = busd;
        let toToken = ETH;
        // unwrap = 0
        let token0 = await lpDAIBUSD.token0();
        flag0 = busd.address == token0 ? "0x0" : "0x8";
        pool0 = flag0 + '00000000000000000000000' + lpDAIBUSD.address.slice(2);

        // unwrap = 1
        token0 = await lpDAIWETH.token0();
        flag1 = dai.address == token0 ?  "0x2" : "0xa";
        pool1 = flag1 + '00000000000000000000000' + lpDAIWETH.address.slice(2);

        const totalAmount = ethers.utils.parseEther('1');
        const commissionAmount = totalAmount.mul(fee).div(10000)
        const fromTokenAmount = totalAmount.sub(commissionAmount)
        let minReturn = ethers.utils.parseEther('0.0005');

        // 2. swap
        await busd.connect(bob).approve(tokenApprove.address, ethers.utils.parseEther('10000'));
        
        let rawInfo = await dexRouter.connect(bob).populateTransaction.uniswapV3SwapTo(
            tom.address,
            fromTokenAmount,
            minReturn,
            [pool0,pool1]
        );
        rawInfo.data = rawInfo.data + commissionInfo.replace('0x','')
        let tx = await bob.sendTransaction(rawInfo)
        let receipt = await tx.wait()
        

        // 3. check
        expect(await fromToken.balanceOf(feeReceiver)).to.be.equal(commissionAmount)
        expect(await ethers.provider.getBalance(tom.address)).to.be.equal("10000000776994310902772")
    });

    // three hops: OKX V2 279536 vs OKX V1 ~410000 vs 1inch V5 263991
    it("5. three hops with commission", async () => {
        // ETH -> DAI -> BUSD -> USDC
        // unwrap = 0

        let token0 = await lpDAIWETH.token0();
        let fromToken = ETH;
        let toToken = usdc;
        flag0 = weth.address == token0 ? "0x0" : "0x8";
        pool0 = flag0 + '00000000000000000000000' + lpDAIWETH.address.slice(2);

        // unwrap = 0
        token0 = await lpDAIBUSD.token0();
        flag1 = dai.address == token0 ?  "0x0" : "0x8";
        pool1 = flag1 + '00000000000000000000000' + lpDAIBUSD.address.slice(2);

        // unwrap = 0
        token0 = await lpBUSDUSDC.token0();
        flag2 = busd.address == token0 ?  "0x0" : "0x8";
        pool2 = flag2 + '00000000000000000000000' + lpBUSDUSDC.address.slice(2);

        const totalAmount = ethers.utils.parseEther('1');
        const commissionAmount = totalAmount.mul(fee).div(10000)
        const fromTokenAmount = totalAmount.sub(commissionAmount)
        let minReturn = "1000000000";

        // 2. swap
        let fromBalBeforeTx = await ethers.provider.getBalance(bob.address);
        let toBalBeforeTx = await usdc.balanceOf(bob.address);
        let rawInfo = await dexRouter.connect(bob).populateTransaction.uniswapV3SwapTo(
            tom.address,
            fromTokenAmount,
            minReturn,
            [pool0,pool1,pool2],
            {
                value: totalAmount
            }
        );
        rawInfo.data = rawInfo.data + commissionInfo.replace('0x','')
        let tx = await bob.sendTransaction(rawInfo)
        let receipt = await tx.wait()

        expect(await ethers.provider.getBalance(feeReceiver)).to.be.equal(commissionAmount)
        expect(await toToken.balanceOf(tom.address)).to.be.equal("1259540490")


    });

        
    const initWeth = async () => {
        weth = await ethers.getContractAt(
            "WETH9",
            ethDeployed.tokens.weth
        );
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
        DexRouter = await ethers.getContractFactory("DexRouter");
        dexRouter = await upgrades.deployProxy(DexRouter);
        await dexRouter.deployed();
        await dexRouter.initializePMMRouter(_feeRateAndReceiver);

  
        expect(await dexRouter._WETH()).to.be.equal(weth.address);
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
        let accountAddress = await xBridge.owner();

        startMockAccount([accountAddress]);
        XBridgeOwner = await ethers.getSigner(accountAddress);
        setBalance(XBridgeOwner.address, '0x56bc75e2d63100000');

        await xBridge.connect(XBridgeOwner).setDexRouter(dexRouter.address);
        await xBridge.connect(XBridgeOwner).setMpc([alice.address],[true]);
        await xBridge.connect(XBridgeOwner).setApproveProxy(tokenApproveProxy.address);
    }

    const initAccounts = async () => {
        accountAddress = "0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6";
        startMockAccount([accountAddress]);
        bob = await ethers.getSigner(accountAddress);
        setBalance(bob.address, '0x56bc75e2d63100000');
    }

    const initTokens = async () => {
        dai = await ethers.getContractAt(
            "MockDaiLikeERC20",
            ethDeployed.tokens.dai
        );

        busd = await ethers.getContractAt(
            "MockERC20",
            ethDeployed.tokens.busd
        );

        usdc = await ethers.getContractAt(
            "MockERC20",
            ethDeployed.tokens.usdc
        );
        lpDAIBUSD = await ethers.getContractAt(
            "IUniV3",
            "0xd1000344c3A00846462B4624bB452621cf2Ce001"
        )

        lpDAIWETH = await ethers.getContractAt(
            "IUniV3",
            "0x60594a405d53811d3BC4766596EFD80fd545A270"
        )
        lpBUSDUSDC = await ethers.getContractAt(
            "IUniV3",
            "0x5E35C4Eba72470Ee1177dcB14dDdf4d9e6D915f4"
        )

    }

    const initOneInchRouter = async () => {
        OneInchRouter = await ethers.getContractAt(
            "DexRouter",
            "0x1111111254EEB25477B68fb85Ed929f73A960582"
        )
    }

    const getTransactionCost = async (txResult) => {
        const cumulativeGasUsed = (await txResult.wait()).cumulativeGasUsed;
        // console.log("cumulativeGasUsed", cumulativeGasUsed);
        return BigNumber.from(txResult.gasPrice).mul(BigNumber.from(cumulativeGasUsed));
      };

});









