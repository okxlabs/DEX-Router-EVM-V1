const { ethers, upgrades, network } = require("hardhat");
const hre = require("hardhat");
const { BigNumber } = require('ethers')
const { expect } = require("chai");
const ethDeployed = require("../scripts/deployed/eth");
const pmm_params = require("../dex_router_v2_test/pmm/pmm_params");
const { getDaiLikePermitDigest, sign } = require('../dex_router_v2_test/signatures')

require('../scripts/tools');


describe("Test unxswapV3 path", function () {
    this.timeout(300000);
    let weth, usdc, dai, busd, lpDAIBUSD, lpDAIWETH;
    let tokenApprove, dexRouter, xBridge, WNativeRelayer, OneInchRouter;
    let owner, alice, bob, wNativeRelayerOwner, XBridgeOwner;

    const ETH = { "address": '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE' };

    before(async function () {
        [owner, alice, bob] = await ethers.getSigners();
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
    it("1. ERC20 -> ERC20", async () => {
        // DAI -> BUSD
        let token0 = await lpDAIBUSD.token0();
        let fromToken = dai;
        let toToken = busd;
        // unwrap = 0
        flag = fromToken.address == token0 ? "0x0" : "0x8";
        pool0 = flag + '00000000000000000000000' + lpDAIBUSD.address.slice(2);

        let fromTokenAmount = ethers.utils.parseEther('0.1');
        let minReturn = ethers.utils.parseEther('0.09');

        // 2. swap
        let fromBalBeforeTx = await fromToken.balanceOf(bob.address);
        let toBalBeforeTx = await toToken.balanceOf(bob.address);

        await fromToken.connect(bob).approve(tokenApprove.address, ethers.utils.parseEther('10000'));
        let returnAmount = await dexRouter.connect(bob).callStatic.uniswapV3SwapTo(
            bob.address,
            fromTokenAmount,
            minReturn,
            [pool0]
        );
        await expect(
            dexRouter.connect(bob).uniswapV3SwapTo(
                bob.address,
                fromTokenAmount,
                minReturn,
                [pool0]
            )
        ).to.emit(dexRouter, "OrderRecord").withArgs(fromToken.address, toToken.address, bob.address, fromTokenAmount, returnAmount);
        // console.log("tx", tx);

        // let receipt = await tx.wait();
        // console.log("receipt", receipt.gasUsed);

        let fromBalAfterTx = await fromToken.balanceOf(bob.address);
        let toBalAfterTx = await toToken.balanceOf(bob.address);

        // 3. check
        expect(fromBalAfterTx.eq(fromBalBeforeTx.sub(fromTokenAmount))).to.be.ok;
        expect(toBalAfterTx.sub(toBalBeforeTx).gte(minReturn)).to.be.ok;

        // 4. test in 1inch 
        // await fromToken.connect(bob).approve(OneInchRouter.address, ethers.utils.parseEther('10000'));
        // await dai.connect(bob).transfer(OneInchRouter.address, "1");
        // await toToken.connect(bob).transfer(OneInchRouter.address, "1");

        // tx = await OneInchRouter.connect(bob).uniswapV3SwapTo(
        //     1,
        //     bob.address,
        //     fromTokenAmount,
        //     minReturn,
        //     [pool0]
        // );

        // receipt = await tx.wait();
        // console.log("1inch test res", receipt.gasUsed);

    })

    // ERC20 -> native: OKX V2 165811 vs OKX V1 ~220000 vs 1inch V5 113933，优化25%
    it("2. ERC20 -> native", async () => {
        // DAI -> ETH
        let token0 = await lpDAIWETH.token0();
        let fromToken = dai;
        let toToken = ETH;
        // unwrap = 1
        flag = dai.address == token0 ? "0x2" : "0xa";
        pool0 = flag + '00000000000000000000000' + lpDAIWETH.address.slice(2);

        let fromTokenAmount = ethers.utils.parseEther('0.1');
        let minReturn = ethers.utils.parseEther('0.00001');

        // 2. swap

        await dai.connect(bob).approve(tokenApprove.address, ethers.utils.parseEther('10000'));

        let fromBalBeforeTx = await dai.balanceOf(bob.address);
        let toBalBeforeTx = await ethers.provider.getBalance(bob.address);

        let returnAmount = await dexRouter.connect(bob).callStatic.uniswapV3SwapTo(
            bob.address,
            fromTokenAmount,
            minReturn,
            [pool0]
        );
        await expect(
            dexRouter.connect(bob).uniswapV3SwapTo(
                bob.address,
                fromTokenAmount,
                minReturn,
                [pool0]
            )
        ).to.emit(dexRouter, "OrderRecord").withArgs(fromToken.address, toToken.address, bob.address, fromTokenAmount, returnAmount);
        // let gasCost = await getTransactionCost(tx);

        let fromBalAfterTx = await dai.balanceOf(bob.address);
        let toBalAfterTx = await ethers.provider.getBalance(bob.address);

        // 3. check 
        expect(fromBalAfterTx.eq(fromBalBeforeTx.sub(fromTokenAmount))).to.be.ok;
        // expect(toBalAfterTx.sub(toBalBeforeTx.sub(gasCost)).gte(minReturn)).to.be.ok;  

        // 4. test in 1inch 
        // await dai.connect(bob).approve(OneInchRouter.address, ethers.utils.parseEther('10000'));
        // await dai.connect(bob).transfer(OneInchRouter.address, "1");
        // await busd.connect(bob).transfer(OneInchRouter.address, "1");

        // tx = await OneInchRouter.connect(bob).uniswapV3SwapTo(
        //     bob.address,
        //     fromTokenAmount,
        //     minReturn,
        //     [pool0]
        // );

        // receipt = await tx.wait();
        // console.log("1inch test res", receipt.gasUsed);
    })


    // native -> ERC20: OKX V2 116505 vs OKX V1 171390 vs 1inch V5 108400，优化32%
    it("3. native -> ERC20", async () => {
        // ETH -> DAI
        let token0 = await lpDAIWETH.token0();
        let fromToken = ETH;
        let toToken = dai;
        // unwrap = 0
        flag = weth.address == token0 ? "0x0" : "0x8";
        pool0 = flag + '00000000000000000000000' + lpDAIWETH.address.slice(2);

        let fromTokenAmount = ethers.utils.parseEther('1');
        let minReturn = ethers.utils.parseEther('1000');

        // 2. swap
        let fromBalBeforeTx = await ethers.provider.getBalance(bob.address);
        let toBalBeforeTx = await dai.balanceOf(bob.address);
        let returnAmount = await dexRouter.connect(bob).callStatic.uniswapV3SwapTo(
            bob.address,
            fromTokenAmount,
            minReturn,
            [pool0],
            {
                value: fromTokenAmount
            }
        );
        await expect(
            dexRouter.connect(bob).uniswapV3SwapTo(
                bob.address,
                fromTokenAmount,
                minReturn,
                [pool0],
                {
                    value: fromTokenAmount
                }
            )
        ).to.emit(dexRouter, "OrderRecord").withArgs(fromToken.address, toToken.address, bob.address, fromTokenAmount, returnAmount);

        // let gasCost = await getTransactionCost(tx);

        let fromBalAfterTx = await ethers.provider.getBalance(bob.address);
        let toBalAfterTx = await dai.balanceOf(bob.address);

        // 3. check 
        // expect(fromBalAfterTx.eq(fromBalBeforeTx.sub(fromTokenAmount).sub(gasCost))).to.be.ok;
        expect(toBalAfterTx.sub(toBalBeforeTx).gte(minReturn)).to.be.ok;

        // 4. test in 1inch router
        // await dai.connect(bob).transfer(OneInchRouter.address, "1");
        // await busd.connect(bob).transfer(OneInchRouter.address, "1");
        // tx = await OneInchRouter.connect(bob).uniswapV3SwapTo(
        //     bob.address,
        //     fromTokenAmount,
        //     minReturn,
        //     [pool0],
        //     {
        //         value: fromTokenAmount
        //     }
        // );

        // let receipt = await tx.wait();
        // console.log("1inch test res", receipt.gasUsed);
    });

    // two hops: OKX V2 245631 vs OKX V1 ~300000 vs 1inch V5 193359
    it("4. two hops", async () => {
        // BUSD -> DAI -> ETH
        let fromToken = busd;
        let toToken = ETH;
        // unwrap = 0
        let token0 = await lpDAIBUSD.token0();
        flag0 = busd.address == token0 ? "0x0" : "0x8";
        pool0 = flag0 + '00000000000000000000000' + lpDAIBUSD.address.slice(2);

        // unwrap = 1
        token0 = await lpDAIWETH.token0();
        flag1 = dai.address == token0 ? "0x2" : "0xa";
        pool1 = flag1 + '00000000000000000000000' + lpDAIWETH.address.slice(2);

        let fromTokenAmount = ethers.utils.parseEther('1');
        let minReturn = ethers.utils.parseEther('0.0005');

        // 2. swap
        await busd.connect(bob).approve(tokenApprove.address, ethers.utils.parseEther('10000'));
        let fromBalBeforeTx = await busd.balanceOf(bob.address);
        let toBalBeforeTx = await ethers.provider.getBalance(bob.address);
        let returnAmount = await dexRouter.connect(bob).callStatic.uniswapV3SwapTo(
            bob.address,
            fromTokenAmount,
            minReturn,
            [pool0, pool1]
        );
        await expect(
            dexRouter.connect(bob).uniswapV3SwapTo(
                bob.address,
                fromTokenAmount,
                minReturn,
                [pool0, pool1]
            )
        ).to.emit(dexRouter, "OrderRecord").withArgs(fromToken.address, toToken.address, bob.address, fromTokenAmount, returnAmount);

        // let gasCost = await getTransactionCost(tx);

        let fromBalAfterTx = await busd.balanceOf(bob.address);
        let toBalAfterTx = await ethers.provider.getBalance(bob.address);

        // 3. check
        expect(fromBalAfterTx.eq(fromBalBeforeTx.sub(fromTokenAmount))).to.be.ok;
        // expect(toBalAfterTx.sub(toBalBeforeTx.sub(gasCost)).gte(minReturn)).to.be.ok;

        // 4. test in 1inch 
        // await busd.connect(bob).approve(OneInchRouter.address, ethers.utils.parseEther('10000'));
        // await dai.connect(bob).transfer(OneInchRouter.address, "1");
        // await busd.connect(bob).transfer(OneInchRouter.address, "1");

        // tx = await OneInchRouter.connect(bob).uniswapV3SwapTo(
        //     bob.address,
        //     fromTokenAmount,
        //     minReturn,
        //     [pool0,pool1]
        // );

        // receipt = await tx.wait();
        // console.log("1inch test res", receipt.gasUsed);
    });

    // three hops: OKX V2 279536 vs OKX V1 ~410000 vs 1inch V5 263991
    it("5. three hops", async () => {
        // ETH -> DAI -> BUSD -> USDC
        // unwrap = 0

        let token0 = await lpDAIWETH.token0();
        let fromToken = ETH;
        let toToken = usdc;
        flag0 = weth.address == token0 ? "0x0" : "0x8";
        pool0 = flag0 + '00000000000000000000000' + lpDAIWETH.address.slice(2);

        // unwrap = 0
        token0 = await lpDAIBUSD.token0();
        flag1 = dai.address == token0 ? "0x0" : "0x8";
        pool1 = flag1 + '00000000000000000000000' + lpDAIBUSD.address.slice(2);

        // unwrap = 0
        token0 = await lpBUSDUSDC.token0();
        flag2 = busd.address == token0 ? "0x0" : "0x8";
        pool2 = flag2 + '00000000000000000000000' + lpBUSDUSDC.address.slice(2);

        let fromTokenAmount = ethers.utils.parseEther('1');
        let minReturn = "1000000000";

        // 2. swap
        let fromBalBeforeTx = await ethers.provider.getBalance(bob.address);
        let toBalBeforeTx = await usdc.balanceOf(bob.address);
        let returnAmount = await dexRouter.connect(bob).callStatic.uniswapV3SwapTo(
            bob.address,
            fromTokenAmount,
            minReturn,
            [pool0, pool1, pool2],
            {
                value: ethers.utils.parseEther('1')
            }
        );
        await expect(
            dexRouter.connect(bob).uniswapV3SwapTo(
                bob.address,
                fromTokenAmount,
                minReturn,
                [pool0, pool1, pool2],
                {
                    value: ethers.utils.parseEther('1')
                }
            )
        ).to.emit(dexRouter, "OrderRecord").withArgs(fromToken.address, toToken.address, bob.address, fromTokenAmount, returnAmount);
        // let gasCost = await getTransactionCost(tx);

        let fromBalAfterTx = await ethers.provider.getBalance(bob.address);
        let toBalAfterTx = await await usdc.balanceOf(bob.address);

        // 3. check
        // expect(fromBalAfterTx.eq(fromBalBeforeTx.sub(fromTokenAmount).sub(gasCost))).to.be.ok;
        expect(toBalAfterTx.sub(toBalBeforeTx).gte(minReturn)).to.be.ok;

        // 4. test in 1inch 
        // await dai.connect(bob).transfer(OneInchRouter.address, "1");
        // await busd.connect(bob).transfer(OneInchRouter.address, "1");

        // tx = await OneInchRouter.connect(bob).uniswapV3SwapTo(
        //     bob.address,
        //     fromTokenAmount,
        //     minReturn,
        //     [pool0,pool1,pool2],
        //     {
        //         value: ethers.utils.parseEther('1')
        //     }
        // );

        // receipt = await tx.wait();
        // console.log("1inch test res", receipt.gasUsed);

    });

    it("6. ERC20 -> ERC20 swap with permit", async () => {
        // DAI -> BUSD
        let token0 = await lpDAIBUSD.token0();
        let fromToken = dai;
        let toToken = busd;
        // unwrap = 0
        flag = fromToken.address == token0 ? "0x0" : "0x8";
        pool0 = flag + '00000000000000000000000' + lpDAIBUSD.address.slice(2);

        let fromTokenAmount = ethers.utils.parseEther('0.1');
        let minReturn = ethers.utils.parseEther('0.09');

        // 2. swap
        await fromToken.connect(bob).transfer(owner.address, fromTokenAmount);

        let fromBalBeforeTx = await fromToken.balanceOf(owner.address);
        let toBalBeforeTx = await toToken.balanceOf(owner.address);

        // await fromToken.connect(bob).approve(tokenApprove.address, ethers.utils.parseEther('10000'));
        const nonce = await fromToken.nonces(owner.address);

        const approve = {
            owner: owner.address,
            spender: tokenApprove.address,
            allowed: true,
        }
        const deadline = 200000000000000;

        const name = "Dai Stablecoin";
        const chainId = 1;

        const digest = getDaiLikePermitDigest(
            name, fromToken.address, chainId, approve, nonce, deadline
        )

        const mnemonic = "test test test test test test test test test test test junk"
        const walletMnemonic = ethers.Wallet.fromMnemonic(mnemonic)
        const ownerPrivateKey = Buffer.from(walletMnemonic.privateKey.replace('0x', ''), 'hex')
        const { v, r, s } = sign(digest, ownerPrivateKey)

        const signdata = await ethers.utils.defaultAbiCoder.encode(
            ['address', 'address', 'uint256', 'uint256', 'bool', 'uint8', 'bytes32', 'bytes32'],
            [
                approve.owner,
                approve.spender,
                nonce,
                deadline,
                approve.allowed,
                v,
                r,
                s
            ]
        )

        let returnAmount = await dexRouter.connect(owner).callStatic.uniswapV3SwapToWithPermit(
            owner.address,
            fromToken.address,
            fromTokenAmount,
            minReturn,
            [pool0],
            signdata
        );
        await expect(
            dexRouter.connect(owner).uniswapV3SwapToWithPermit(
                owner.address,
                fromToken.address,
                fromTokenAmount,
                minReturn,
                [pool0],
                signdata
            )
        ).to.emit(dexRouter, "OrderRecord").withArgs(fromToken.address, toToken.address, owner.address, fromTokenAmount, returnAmount);
        // console.log("tx", tx);

        // let receipt = await tx.wait();
        // console.log("receipt", receipt.gasUsed);

        let fromBalAfterTx = await fromToken.balanceOf(owner.address);
        let toBalAfterTx = await toToken.balanceOf(owner.address);

        // 3. check
        expect(fromBalAfterTx.eq(fromBalBeforeTx.sub(fromTokenAmount))).to.be.ok;
        expect(toBalAfterTx.sub(toBalBeforeTx).gte(minReturn)).to.be.ok;

        // // 4. test in 1inch 
        // await fromToken.connect(bob).approve(OneInchRouter.address, ethers.utils.parseEther('10000'));
        // await dai.connect(bob).transfer(OneInchRouter.address, "1");
        // await toToken.connect(bob).transfer(OneInchRouter.address, "1");

        // tx = await OneInchRouter.connect(bob).uniswapV3SwapTo(
        //     bob.address,
        //     fromTokenAmount,
        //     minReturn,
        //     [pool0]
        // );

        // receipt = await tx.wait();
        // // console.log("1inch test res", receipt.gasUsed);

    })

    //  ==========================  internal functions  ===========================


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
        // await dexRouter.initializePMMRouter(_feeRateAndReceiver);


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
        await xBridge.connect(XBridgeOwner).setMpc([alice.address], [true]);
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









