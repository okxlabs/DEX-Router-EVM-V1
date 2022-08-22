const { 
    getPullInfosToBeSigned, 
    getPullInfosToBeSigned_paidByCarol, 
    getPushInfosToBeSigned, 
    multipleQuotes, 
    getDigest,
    getPullInfosToBeSigned_paidByOKCMockAccount,
    getPullInfosToBeSigned_paidByETHMockAccount
} = require("./pmm/quoter");
const { ethers, upgrades, network} = require("hardhat");
const hre = require("hardhat");

const { BigNumber } = require('ethers')
const { expect } = require("chai");
const okcdevDeployed = require("../scripts/deployed/okc_dev");
const ethdevDeployed = require("../scripts/deployed/eth_dev");

require ('../scripts/tools');

describe("Market Maker Test (version: 1.0.0)", function(){
    let wbtc, usdt, weth, factory, router, marketMaker;
    let owner, alice, bob, carol, backEnd, canceler, cancelerGuardian, singer;
    let layer1, layer2, layer3;
    const FOREVER = '2000000000';
    const ETH = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

    const initMockTokens = async function() {
        const MockERC20 = await ethers.getContractFactory("MockERC20");

        usdc = await MockERC20.deploy('USDC', 'USDC', ethers.utils.parseEther('10000000000'));
        await usdc.deployed();

        usdt = await MockERC20.deploy('USDT', 'USDT', ethers.utils.parseEther('10000000000'));
        await usdt.deployed();

        wbtc = await MockERC20.deploy('WBTC', 'WBTC', ethers.utils.parseEther('10000000000'));
        await wbtc.deployed();

        okb = await MockERC20.deploy('OKB', 'OKB', ethers.utils.parseEther('10000000000'));
        await usdt.deployed();

        dot = await MockERC20.deploy('DOT', 'DOT', ethers.utils.parseEther('10000000000'));
        await usdt.deployed();

        const WETH9 = await ethers.getContractFactory("WETH9");
        weth = await WETH9.deploy();
        await weth.deployed();
        await weth.deposit({
            value: ethers.utils.parseEther('99')
        })
    };

    const initUniSwap = async () => {
        UniAdapter = await ethers.getContractFactory("UniAdapter");
        uniAdapter = await UniAdapter.deploy();

        const UniswapV2Factory = await ethers.getContractFactory("UniswapV2Factory");
        factory = await UniswapV2Factory.deploy(owner.address);
        await factory.deployed();
        const UniswapV2Router = await ethers.getContractFactory("UniswapRouter");
        router = await UniswapV2Router.deploy(factory.address, weth.address);
        await router.deployed();

        await factory.createPair(usdt.address, weth.address);
        await factory.createPair(weth.address, wbtc.address);
        await factory.createPair(usdt.address, wbtc.address);
        await factory.createPair(usdt.address, okb.address);
        await factory.createPair(okb.address, dot.address);
        await factory.createPair(dot.address,  wbtc.address);

        const UniswapPair = await ethers.getContractFactory("UniswapV2Pair");

        pair = await factory.getPair(usdt.address, weth.address)
        lpUSDTWETH = await UniswapPair.attach(pair);

        pair = await factory.getPair(weth.address, wbtc.address);
        lpWETHWBTC = await UniswapPair.attach(pair);

        pair = await factory.getPair(usdt.address, wbtc.address);
        lpUSDTWBTC = await UniswapPair.attach(pair);

        pair = await factory.getPair(usdt.address, okb.address);
        lpUSDTOKB = await UniswapPair.attach(pair);

        pair = await factory.getPair(okb.address, dot.address);
        lpOKBDOT = await UniswapPair.attach(pair);

        pair = await factory.getPair(dot.address, wbtc.address);
        lpDOTWBTC = await UniswapPair.attach(pair);
    }

    const uniV2AddLiquidity = async (token0, token1, amount0, amount1) => {
        await token0.approve(router.address, amount0);
        await token1.approve(router.address, amount1);
        await router.addLiquidity(
        token0.address,
        token1.address,
        amount0, 
        amount1, 
        '0', 
        '0', 
        owner.address,
        FOREVER
        );
    }
//  dex swap path
//  30%  usdt -> weth -> wbtc
//  20%  usdt -> wbtc
//  50%  usdt -> okb -> dot -> wbtc
//
//  market maker quotes
//  100% usdt -> wbtc
//  30%  usdt -> wbtc, usdt -> weth, weth -> wbtc
//  20%  usdt -> wbtc
//  50%  usdt -> wbtc, usdt -> okb, okb -> dot, dot -> wbtc

//  price:
//  wbtc: 40000
//  weth: 3000
//  okb:  20
//  dot:  15
    const addLiquidity = async function(){
        const pairs = [
            [usdt, weth, ethers.utils.parseEther('150000'), ethers.utils.parseEther('50')],
            [weth, wbtc, ethers.utils.parseEther('40'), ethers.utils.parseEther('3')],
            [usdt, wbtc, ethers.utils.parseEther('4000000'), ethers.utils.parseEther('100')],
            [usdt, okb, ethers.utils.parseEther('40000000'), ethers.utils.parseEther('2000000')],
            [okb, dot, ethers.utils.parseEther('1500000'), ethers.utils.parseEther('2000000')],
            [dot, wbtc, ethers.utils.parseEther('4000000'), ethers.utils.parseEther('2000')]
          ]
          for (let i = 0; i < pairs.length; i++) {
            await uniV2AddLiquidity(
              pairs[i][0],
              pairs[i][1],
              pairs[i][2], 
              pairs[i][3],
            );
          }
    }

    const direction = async (fromToken, toToken, pair) => {
        if (!pair) return 0;
        const token0 = await pair.token0();
        const token1 = await pair.token1();
        if (fromToken === token0 && toToken === token1) {
          return 0;
        } else {
          return 8;
        }
      }

    const getWeight = function(weight) {
        return ethers.utils.hexZeroPad(weight, 2).slice(2);
    }

    const getSource = async function(pair, fromToken, toToken) {
        let isReverse = "0000";
        let token0 = await pair.token0();
        let token1 = await pair.token1();
        if (toToken == token0 && fromToken == token1) {
            isReverse = "0080";
        }
        let source = isReverse + "00000000000000000000" + pair.address.slice(2);
        return source;
    }

    const getUniV3Source = async function(pair, fromToken, toToken) {
        let isReverse = "0100";
        let token0 = await pair.token0();
        let token1 = await pair.token1();
        if (toToken == token0 && fromToken == token1) {
            isReverse = "0180";
        }
        let source = isReverse + "00000000000000000000" + pair.address.slice(2);
        return source;
    }


    const initLayersWholeSwap = async function() {

        //  30%  usdt -> weth -> wbtc
        //  20%  usdt -> wbtc
        //  50%  usdt -> okb -> dot -> wbtc
        //  router11 usdt -> weth
        const mixAdapter11 = [uniAdapter.address];
        const assertTo11 = [lpUSDTWETH.address];
        const weight11 = getWeight(10000);
        const rawData11 = ["0x" + await direction(usdt.address, weth.address, lpUSDTWETH) + "0000000000000000000" + weight11 + lpUSDTWETH.address.slice(2)];
        const extraData11 = ['0x'];
        const router11 = [mixAdapter11, assertTo11, rawData11, extraData11, usdt.address];

        // router12 weth -> wbtc
        const mixAdapter12 = [uniAdapter.address];
        const assertTo12 = [lpWETHWBTC.address];
        const weight12 = getWeight(10000);
        const rawData12 = ["0x" + await direction(weth.address, wbtc.address, lpWETHWBTC) + "0000000000000000000" + weight12 + lpWETHWBTC.address.slice(2)];
        const extraData12 = ['0x'];
        const router12 = [mixAdapter12, assertTo12, rawData12, extraData12, weth.address];

        // router21 usdt -> wbtc
        const mixAdapter21 = [uniAdapter.address];
        const assertTo21 = [lpUSDTWBTC.address];
        const weight21 = getWeight(10000);
        const rawData21 = ["0x" + await direction(usdt.address, wbtc.address, lpUSDTWBTC) + "0000000000000000000" + weight21 + lpUSDTWBTC.address.slice(2)];
        const extraData21 = ['0x'];
        const router21 = [mixAdapter21, assertTo21, rawData21, extraData21, usdt.address];

        // router31 usdt -> okb
        const mixAdapter31 = [uniAdapter.address];
        const assertTo31 = [lpUSDTOKB.address];
        const weight31 = getWeight(10000);
        const rawData31 = ["0x" + await direction(usdt.address, okb.address, lpUSDTOKB) + "0000000000000000000" + weight31 + lpUSDTOKB.address.slice(2)];
        const extraData31 = ['0x'];
        const router31 = [mixAdapter31, assertTo31, rawData31, extraData31, usdt.address];

        // router32 okb -> dot
        const mixAdapter32 = [uniAdapter.address];
        const assertTo32 = [lpOKBDOT.address];
        const weight32 = getWeight(10000);
        const rawData32 = ["0x" + await direction(okb.address, dot.address, lpOKBDOT) + "0000000000000000000" + weight32 + lpOKBDOT.address.slice(2)];
        const extraData32 = ['0x'];
        const router32 = [mixAdapter32, assertTo32, rawData32, extraData32, okb.address];

        // router33 dot -> wbtc
        const mixAdapter33 = [uniAdapter.address];
        const assertTo33 = [lpDOTWBTC.address];
        const weight33 = getWeight(10000);
        const rawData33 = ["0x" + await direction(dot.address, wbtc.address, lpDOTWBTC) + "0000000000000000000" + weight33 + lpDOTWBTC.address.slice(2)];
        const extraData33 = ['0x'];
        const router33 = [mixAdapter33, assertTo33, rawData33, extraData33, dot.address];

        layer1 = [router11, router12];
        layer2 = [router21];
        layer3 = [router31, router32, router33];

        const layers = [layer1, layer2, layer3];
        return layers;
    }
        

    const initLayersReplaceFirstBatch = async function() {

        //  30%  usdt -> weth -> wbtc
        //  20%  usdt -> wbtc
        //  50%  usdt -> okb -> dot -> wbtc
        //  router11 usdt -> weth
        const mixAdapter11 = [uniAdapter.address];
        const assertTo11 = [lpUSDTWETH.address];
        const weight11 = getWeight(10000);
        const rawData11 = ["0x" + await direction(usdt.address, weth.address, lpUSDTWETH) + "0000000000000000000" + weight11 + lpUSDTWETH.address.slice(2)];
        const extraData11 = ['0x'];
        const router11 = [mixAdapter11, assertTo11, rawData11, extraData11, '0x80' + '0000000000000000000000' + usdt.address.slice(2)];

        // router12 weth -> wbtc
        const mixAdapter12 = [uniAdapter.address];
        const assertTo12 = [lpWETHWBTC.address];
        const weight12 = getWeight(10000);
        const rawData12 = ["0x" + await direction(weth.address, wbtc.address, lpWETHWBTC) + "0000000000000000000" + weight12 + lpWETHWBTC.address.slice(2)];
        const extraData12 = ['0x'];
        const router12 = [mixAdapter12, assertTo12, rawData12, extraData12, weth.address];

        // router21 usdt -> wbtc
        const mixAdapter21 = [uniAdapter.address];
        const assertTo21 = [lpUSDTWBTC.address];
        const weight21 = getWeight(10000);
        const rawData21 = ["0x" + await direction(usdt.address, wbtc.address, lpUSDTWBTC) + "0000000000000000000" + weight21 + lpUSDTWBTC.address.slice(2)];
        const extraData21 = ['0x'];
        const router21 = [mixAdapter21, assertTo21, rawData21, extraData21, usdt.address];

        // router31 usdt -> okb
        const mixAdapter31 = [uniAdapter.address];
        const assertTo31 = [lpUSDTOKB.address];
        const weight31 = getWeight(10000);
        const rawData31 = ["0x" + await direction(usdt.address, okb.address, lpUSDTOKB) + "0000000000000000000" + weight31 + lpUSDTOKB.address.slice(2)];
        const extraData31 = ['0x'];
        const router31 = [mixAdapter31, assertTo31, rawData31, extraData31, usdt.address];

        // router32 okb -> dot
        const mixAdapter32 = [uniAdapter.address];
        const assertTo32 = [lpOKBDOT.address];
        const weight32 = getWeight(10000);
        const rawData32 = ["0x" + await direction(okb.address, dot.address, lpOKBDOT) + "0000000000000000000" + weight32 + lpOKBDOT.address.slice(2)];
        const extraData32 = ['0x'];
        const router32 = [mixAdapter32, assertTo32, rawData32, extraData32, okb.address];

        // router33 dot -> wbtc
        const mixAdapter33 = [uniAdapter.address];
        const assertTo33 = [lpDOTWBTC.address];
        const weight33 = getWeight(10000);
        const rawData33 = ["0x" + await direction(dot.address, wbtc.address, lpDOTWBTC) + "0000000000000000000" + weight33 + lpDOTWBTC.address.slice(2)];
        const extraData33 = ['0x'];
        const router33 = [mixAdapter33, assertTo33, rawData33, extraData33, dot.address];

        layer1 = [router11, router12];
        layer2 = [router21];
        layer3 = [router31, router32, router33];

        const layers = [layer1, layer2, layer3];
        return layers;
    }


    const initLayersReplaceHops = async function() {

        //  30%  usdt -> weth -> wbtc
        //  20%  usdt -> wbtc
        //  50%  usdt -> okb -> dot -> wbtc
        //  router11 usdt -> weth
        const mixAdapter11 = [uniAdapter.address];
        const assertTo11 = [lpUSDTWETH.address];
        const weight11 = getWeight(10000);
        const rawData11 = ["0x" + await direction(usdt.address, weth.address, lpUSDTWETH) + "0000000000000000000" + weight11 + lpUSDTWETH.address.slice(2)];
        const extraData11 = ['0x'];
        const router11 = [mixAdapter11, assertTo11, rawData11, extraData11, '0x40' + '0000000000000000000000' + usdt.address.slice(2)];

        // router12 weth -> wbtc
        const mixAdapter12 = [uniAdapter.address];
        const assertTo12 = [lpWETHWBTC.address];
        const weight12 = getWeight(10000);
        const rawData12 = ["0x" + await direction(weth.address, wbtc.address, lpWETHWBTC) + "0000000000000000000" + weight12 + lpWETHWBTC.address.slice(2)];
        const extraData12 = ['0x'];
        const router12 = [mixAdapter12, assertTo12, rawData12, extraData12, '0x40' + '0001000000000000000000' + weth.address.slice(2)];

        // router21 usdt -> wbtc
        const mixAdapter21 = [uniAdapter.address];
        const assertTo21 = [lpUSDTWBTC.address];
        const weight21 = getWeight(10000);
        const rawData21 = ["0x" + await direction(usdt.address, wbtc.address, lpUSDTWBTC) + "0000000000000000000" + weight21 + lpUSDTWBTC.address.slice(2)];
        const extraData21 = ['0x'];
        const router21 = [mixAdapter21, assertTo21, rawData21, extraData21, usdt.address];

        // router31 usdt -> okb
        const mixAdapter31 = [uniAdapter.address];
        const assertTo31 = [lpUSDTOKB.address];
        const weight31 = getWeight(10000);
        const rawData31 = ["0x" + await direction(usdt.address, okb.address, lpUSDTOKB) + "0000000000000000000" + weight31 + lpUSDTOKB.address.slice(2)];
        const extraData31 = ['0x'];
        const router31 = [mixAdapter31, assertTo31, rawData31, extraData31, usdt.address];

        // router32 okb -> dot
        const mixAdapter32 = [uniAdapter.address];
        const assertTo32 = [lpOKBDOT.address];
        const weight32 = getWeight(10000);
        const rawData32 = ["0x" + await direction(okb.address, dot.address, lpOKBDOT) + "0000000000000000000" + weight32 + lpOKBDOT.address.slice(2)];
        const extraData32 = ['0x'];
        const router32 = [mixAdapter32, assertTo32, rawData32, extraData32, okb.address];

        // router33 dot -> wbtc
        const mixAdapter33 = [uniAdapter.address];
        const assertTo33 = [lpDOTWBTC.address];
        const weight33 = getWeight(10000);
        const rawData33 = ["0x" + await direction(dot.address, wbtc.address, lpDOTWBTC) + "0000000000000000000" + weight33 + lpDOTWBTC.address.slice(2)];
        const extraData33 = ['0x'];
        const router33 = [mixAdapter33, assertTo33, rawData33, extraData33, dot.address];

        layer1 = [router11, router12];
        layer2 = [router21];
        layer3 = [router31, router32, router33];

        const layers = [layer1, layer2, layer3];
        return layers;
    }

    const startMockAccount = async (account) => {
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: account,
        });
    }

    describe("1. Uint Test", function() {

        beforeEach(async function() {
            [owner, alice, bob, carol, backEnd, canceler, cancelerGuardian] = await ethers.getSigners();

            await initMockTokens();
            await initUniSwap();
            await addLiquidity();

        });

        it("1.1 ERC20 Exchange By FixRate", async () => {
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
            const { chainId }  = await ethers.provider.getNetwork();

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
            await marketMaker.setDexRouter(alice.address);
    
            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter" : ethers.constants.AddressZero,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address,markerAmount);
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
            await marketMaker.connect(alice).dexRouterSwap(
                swapAmount,
                alice.address,
                request
            );

            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await wbtc.balanceOf(alice.address)).to.equal(infos.toTokenAmountMax);
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('50000'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2').sub(BigNumber.from(infos.toTokenAmountMax)));
        });

        it("1.2 ERC20 Exchange By FixRate, Price Protected By Passed Source", async () => {
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
            const { chainId }  = await ethers.provider.getNetwork();

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
            await marketMaker.setDexRouter(alice.address);
    
            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);

            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '2000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter" : ethers.constants.AddressZero,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address,markerAmount);
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
            await marketMaker.connect(alice).dexRouterSwap(
                swapAmount,
                alice.address,
                request
            );

            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await wbtc.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('1.25'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('50000'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0.75'));
        });

        it("1.3 ERC20 Exchange By FixRate, Price Protected By Default Source", async () => {
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
            const { chainId }  = await ethers.provider.getNetwork();

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
            await marketMaker.setDexRouter(alice.address);
            await marketMaker.setUniV2Factory(factory.address);
    
            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '2000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter" : ethers.constants.AddressZero,
                    "source": "000000000000000000000000" + ethers.constants.AddressZero.slice(2)
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address,markerAmount);
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
            await marketMaker.connect(alice).dexRouterSwap(
                swapAmount,
                alice.address,
                request
            );

            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await wbtc.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('1.25'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('50000'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0.75'));
        });


        it("1.4 ERC20 Exchange By FixRate, Wrong Price Source Passed, Error Catched", async () => {
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
            const { chainId }  = await ethers.provider.getNetwork();

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
            await marketMaker.setDexRouter(alice.address);
            await marketMaker.setUniV2Factory(factory.address);
    
            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter" : ethers.constants.AddressZero,
                    "source": "000000000000000000000000" + usdt.address.slice(2)             // this is a wrong source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address,markerAmount);
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
            await marketMaker.connect(alice).dexRouterSwap(
                swapAmount,
                alice.address,
                request
            );

            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await wbtc.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('1.01'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('50000'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0.99'));
        });


        it("1.5 Approve Token", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
            await marketMaker.setDexRouter(alice.address);
            await marketMaker.setUniV2Factory(factory.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter" : alice.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);

            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            // what if bob has not approved token ?
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
            await marketMaker.connect(bob).setOperator(bob.address);
            let errorCode = await marketMaker.connect(alice).callStatic.dexRouterSwap(
                swapAmount,
                alice.address,
                request
            )
            await expect(errorCode).to.equal(8);

            // after bob approve token
            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address,markerAmount);

            await marketMaker.connect(alice).dexRouterSwap(
                swapAmount,
                alice.address,
                request
            )

            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await wbtc.balanceOf(alice.address)).to.equal(infos.toTokenAmountMax);
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('50000'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2').sub(BigNumber.from(infos.toTokenAmountMax)));
            
        });

        it("1.6 Invalid Pmm Swap Request", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
    
            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
            await marketMaker.setDexRouter(alice.address);
            await marketMaker.setUniV2Factory(factory.address);
    
            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();
    
            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);
    
            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);
    
            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));
    
            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter" : ethers.constants.AddressZero,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);
    
            let infos = quote[0];
            let request = [
                // here we made a mistake in pathIndex
                infos.pathIndex + 1, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
    
            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address,markerAmount);
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
    
            let errorCode = await marketMaker.connect(alice).callStatic.dexRouterSwap(
                swapAmount,
                alice.address,
                request
            )
            await expect(errorCode).to.equal(1);
    
        });


        it("1.7 Set operator", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
            await marketMaker.setDexRouter(alice.address);
            await marketMaker.setUniV2Factory(factory.address);
            
            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            await wbtc.transfer(carol.address, ethers.utils.parseEther('2'));

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter" : ethers.constants.AddressZero,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned_paidByCarol(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(carol).approve(tokenApprove.address,markerAmount);
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            // carol has not set bob as operator
            let errorCode = await marketMaker.connect(alice).callStatic.dexRouterSwap(
                swapAmount,
                alice.address,
                request
            )
            await expect(errorCode).to.equal(1);

            // carol has set bob as operator
            await marketMaker.connect(carol).setOperator(bob.address);
            await marketMaker.connect(alice).dexRouterSwap(
                swapAmount,
                alice.address,
                request
            );

            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await wbtc.balanceOf(alice.address)).to.equal(infos.toTokenAmountMax);
            expect(await usdt.balanceOf(carol.address)).to.equal(ethers.utils.parseEther('50000'));
            expect(await wbtc.balanceOf(carol.address)).to.equal(ethers.utils.parseEther('2').sub(BigNumber.from(infos.toTokenAmountMax)));
        });



        it("1.8 Cancel Quotes And Query Order Status", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
            await marketMaker.setDexRouter(alice.address);
            await marketMaker.setUniV2Factory(factory.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            await wbtc.transfer(carol.address, ethers.utils.parseEther('2'));

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let rfq = [];
            let N = 1;
            for (let i = 0; i < N; i++) {
                let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
                rfq[i] = {
                    "pathIndex": i,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter" : ethers.constants.AddressZero,
                    "source": source
                }
            }

            let infosToBeSigned = getPullInfosToBeSigned_paidByCarol(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let pathIndex = [];
            for (let i = 0; i < N; i ++){
                pathIndex[i] = i;
            }

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(carol).approve(tokenApprove.address,markerAmount);
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
            await marketMaker.connect(carol).setOperator(bob.address);

            let orderStatus = await marketMaker.queryOrderStatus(pathIndex);
            expect(orderStatus[0].cancelledOrFinalized).to.equal(false);

            let res = await marketMaker.setCancelerGuardian(carol.address);
            // let receipt = await res.wait();
            // console.log("receipt",receipt);

            // cancelled quotes
            // 方案三 由白名单canceler进行EIP72签名，由任何帐户发交易来取消
            await marketMaker.setCanceler([canceler.address], [true]);
            let tx = await marketMaker.connect(canceler).cancelQuotes(pathIndex);

            for (let i = 0; i < N; i++) {
                let requestForSwap = [
                    quote[i].pathIndex, 
                    quote[i].payer, 
                    quote[i].fromTokenAddress, 
                    quote[i].toTokenAddress, 
                    quote[i].fromTokenAmountMax, 
                    quote[i].toTokenAmountMax, 
                    quote[i].salt, 
                    quote[i].deadLine, 
                    quote[i].isPushOrder,
                    quote[i].extension
                ];
                errorCode = await marketMaker.connect(alice).callStatic.dexRouterSwap(
                    swapAmount,
                    alice.address,
                    requestForSwap
                );
        
                expect(errorCode).to.equal(5);
            }


            // query order status after cancel quote
            orderStatus = await marketMaker.queryOrderStatus(pathIndex);
            for (let i = 0; i < N; i++){
                expect(orderStatus[i].cancelledOrFinalized).to.equal(true);
            }

        });


        it("1.9 Reuse a pull quote which has been already been used", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
            await marketMaker.setDexRouter(alice.address);
            await marketMaker.setUniV2Factory(factory.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter" : ethers.constants.AddressZero,
                    "source" : source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address,markerAmount);
            let swapAmount = ethers.utils.parseEther('10000');
            await usdt.connect(alice).approve(tokenApprove.address, ethers.utils.parseEther('50000'));

            await marketMaker.connect(alice).dexRouterSwap(
                swapAmount,
                alice.address,
                request
            )

            let errorCode = await marketMaker.connect(alice).callStatic.dexRouterSwap(
                swapAmount,
                alice.address,
                request
            )

            await expect(errorCode).to.equal(5);
            
        });


        it("1.10 Actual request amount exceeds fromTokenAmountMax of a push order", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
            await marketMaker.setDexRouter(alice.address);
            await marketMaker.setUniV2Factory(factory.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "takerWantToken": usdt.address, 
                    "makerSellToken": wbtc.address, 
                    "makeAmountMax": '1000000000000000000', 
                    "PriceMin": '50000',
                    "pushQuoteValidPeriod": '3600',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter" : ethers.constants.AddressZero,
                    "source" : source
                }
            ]
            let infosToBeSigned = getPushInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address,markerAmount);
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, ethers.utils.parseEther('100000'));

            let hash = getDigest(request, chainId, marketMaker.address);

            await marketMaker.connect(alice).dexRouterSwap(
                swapAmount,
                alice.address,
                request
            )

            let orderStatus = await marketMaker.queryOrderStatus([infos.pathIndex]);
            await expect(BigNumber.from(orderStatus[0].fromTokenAmountUsed)).to.equal(ethers.utils.parseEther('50000'));

            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            let errorCode = await marketMaker.connect(alice).callStatic.dexRouterSwap(
                swapAmount,
                alice.address,
                request
            )
            await expect(errorCode).to.equal(6);
            
        });



    });



    describe("2. Integration Test (swap from DexRouter)", function() {

        beforeEach(async function() {
            [owner, alice, bob, carol, backEnd, canceler, cancelerGuardian] = await ethers.getSigners();

            await initMockTokens();
            await initUniSwap();
            await addLiquidity();
        });

        it("2.1 DexRouter Swap: ERC20 Exchange ERC20", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            DexRouter = await ethers.getContractFactory("DexRouter");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize();
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);

            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source" : source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            const baseRequest = [
                '0x80' + '0000000000000000000000' + usdt.address.toString().slice(2),
                wbtc.address,
                swapAmount,
                ethers.utils.parseEther('0'),
                FOREVER            
            ]

            let res = await dexRouter.connect(alice).smartSwap(
                baseRequest,
                [swapAmount],
                [[]],
                [request]
            );

            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await wbtc.balanceOf(alice.address)).to.equal(infos.toTokenAmountMax);
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('50000'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2').sub(BigNumber.from(infos.toTokenAmountMax)));
        });


        // since the origin DexRouter use a constant of _WETH, here we have to use a temp version of DexRouter which we can config weth
        it("2.2 DexRouter Swap: Native token Exchange ERC20", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(bob.address, ethers.utils.parseEther('5000'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            const WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
            const wNativeRelayer = await WNativeRelayer.deploy();
            await wNativeRelayer.deployed;
            await wNativeRelayer.initialize(weth.address);

            DexRouter = await ethers.getContractFactory("MockDexRouterForLocalPMMTest");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize(weth.address);
            await dexRouter.setWNativeRelayer(wNativeRelayer.address);
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);

            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5000'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('0'));

            let source = await getSource(lpUSDTWETH, weth.address, usdt.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": weth.address, 
                    "toTokenAddress": usdt.address, 
                    "fromTokenAmount": '1000000000000000000', 
                    "toTokenAmountMin": '2500000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('5000');
            await usdt.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('1');

            const baseRequest = [
                '0x80' + '0000000000000000000000' + ETH.slice(2),
                usdt.address,
                swapAmount,
                ethers.utils.parseEther('0'),
                FOREVER
            ]

            await dexRouter.connect(alice).smartSwap(
                baseRequest,
                [swapAmount],
                [[]],
                [request],
                {
                    value: ethers.utils.parseEther('1')
                }
            );
 
            expect(await usdt.balanceOf(alice.address)).to.equal(BigNumber.from(infos.toTokenAmountMax));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5000').sub(BigNumber.from(infos.toTokenAmountMax)));
            expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('1'));

        });


        // since the origin DexRouter use a constant of _WETH, here we have to use a temp version of DexRouter which we can config weth
        it("2.3 DexRouter Swap: ERC20 Exchange Native token ", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(alice.address, ethers.utils.parseEther('3000'));
            await weth.connect(bob).deposit(            {
                value: ethers.utils.parseEther('2')
            });

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            const WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
            const wNativeRelayer = await WNativeRelayer.deploy();
            await wNativeRelayer.deployed;
            await wNativeRelayer.initialize(weth.address);

            DexRouter = await ethers.getContractFactory("MockDexRouterForLocalPMMTest");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize(weth.address);
            await dexRouter.setWNativeRelayer(wNativeRelayer.address);
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);
            await wNativeRelayer.setCallerOk([dexRouter.address], true);

            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);

            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('3000'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));

            let source = await getSource(lpUSDTWETH, weth.address, usdt.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": weth.address, 
                    "fromTokenAmount": '3000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('2');
            await weth.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('3000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            const baseRequest = [
                '0x80' + '0000000000000000000000' + usdt.address.slice(2),
                ETH,
                swapAmount,
                ethers.utils.parseEther('0'),
                FOREVER
            ]

            await dexRouter.connect(alice).smartSwap(
                baseRequest,
                [swapAmount],
                [[]],
                [request]
            );

            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('3000'));
        });


        it("2.4 User swap: ERC20 Exchange ERC20", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            DexRouter = await ethers.getContractFactory("DexRouter");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize();
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);

            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source" : source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            const baseRequest = [
                usdt.address,
                wbtc.address,
                swapAmount,
                ethers.utils.parseEther('0'),
                FOREVER            
            ]
            let res = await marketMaker.connect(alice).userSwap(
                baseRequest,
                request
            );

            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await wbtc.balanceOf(alice.address)).to.equal(infos.toTokenAmountMax);
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('50000'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2').sub(BigNumber.from(infos.toTokenAmountMax)));
        });

        it("2.5 User swap: Native token Exchange ERC20", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(bob.address, ethers.utils.parseEther('5000'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            const WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
            const wNativeRelayer = await WNativeRelayer.deploy();
            await wNativeRelayer.deployed;
            await wNativeRelayer.initialize(weth.address);

            DexRouter = await ethers.getContractFactory("MockDexRouterForLocalPMMTest");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize(weth.address);
            await dexRouter.setWNativeRelayer(wNativeRelayer.address);
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);

            await marketMaker.setWNativeRelayer(wNativeRelayer.address);

            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5000'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('0'));

            let source = await getSource(lpUSDTWETH, weth.address, usdt.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": weth.address, 
                    "toTokenAddress": usdt.address, 
                    "fromTokenAmount": '1000000000000000000', 
                    "toTokenAmountMin": '2500000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('5000');
            await usdt.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('1');

            const baseRequest = [
                ETH,
                usdt.address,
                swapAmount,
                ethers.utils.parseEther('0'),
                FOREVER
            ]

            await marketMaker.connect(alice).userSwap(
                baseRequest,
                request,
                {
                    value: ethers.utils.parseEther('1')
                }
            );

            expect(await usdt.balanceOf(alice.address)).to.equal(BigNumber.from(infos.toTokenAmountMax));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5000').sub(BigNumber.from(infos.toTokenAmountMax)));
            expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('1'));

        });

        it("2.6 User swap: ERC20 Exchange Native token ", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(alice.address, ethers.utils.parseEther('3000'));
            await weth.connect(bob).deposit(            {
                value: ethers.utils.parseEther('2')
            });

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            const WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
            const wNativeRelayer = await WNativeRelayer.deploy();
            await wNativeRelayer.deployed;
            await wNativeRelayer.initialize(weth.address);

            await wNativeRelayer.setCallerOk([marketMaker.address],true);
            await marketMaker.setWNativeRelayer(wNativeRelayer.address);


            DexRouter = await ethers.getContractFactory("MockDexRouterForLocalPMMTest");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize(weth.address);
            await dexRouter.setWNativeRelayer(wNativeRelayer.address);
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);
            await wNativeRelayer.setCallerOk([dexRouter.address], true);

            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);

            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('3000'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));

            let source = await getSource(lpUSDTWETH, weth.address, usdt.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": weth.address, 
                    "fromTokenAmount": '3000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            let markerAmount = ethers.utils.parseEther('2');
            await weth.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('3000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            const baseRequest = [
                usdt.address,
                ETH,
                swapAmount,
                ethers.utils.parseEther('0'),
                FOREVER
            ]

            await marketMaker.connect(alice).userSwap(
                baseRequest,
                request
            );

            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('3000'));
        });

        //  dex swap path
        //  30%  usdt -> weth -> wbtc
        //  20%  usdt -> wbtc
        //  50%  usdt -> okb -> dot -> wbtc
        //
        //  market maker quotes
        //  100% usdt -> wbtc
        //  30%  usdt -> wbtc, usdt -> weth, weth -> wbtc
        //  20%  usdt -> wbtc
        //  50%  usdt -> wbtc, usdt -> okb, okb -> dot, dot -> wbtc

        //  price:
        //  wbtc: 40000
        //  weth: 3000
        //  okb:  20
        //  dot:  15

        it("2.7 Try to replace the whole swap with pmm but failed, turn to dex ", async () => {
            const { chainId }  = await ethers.provider.getNetwork();

            await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
            await weth.transfer(bob.address, ethers.utils.parseEther('5'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
            await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
            await dot.transfer(bob.address, ethers.utils.parseEther('2000'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            const WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
            const wNativeRelayer = await WNativeRelayer.deploy();
            await wNativeRelayer.deployed;
            await wNativeRelayer.initialize(weth.address);

            DexRouter = await ethers.getContractFactory("MockDexRouterForLocalPMMTest");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize(weth.address);
            await dexRouter.setWNativeRelayer(wNativeRelayer.address);
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);
            await wNativeRelayer.setCallerOk([dexRouter.address], true);

            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);

            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('40000'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
            expect(await okb.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
            expect(await dot.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));

            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": ethers.utils.parseEther('40000'), 
                    "toTokenAmountMin": ethers.utils.parseEther('1'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex + 1,        // we make a wrong pathIndex here leading to failure of pmm swap
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            const pmmRequests = [request];

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('40000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            const baseRequest = [
                '0x80' + '0000000000000000000000' + usdt.address.slice(2),
                wbtc.address,
                swapAmount,
                ethers.utils.parseEther('1'),
                FOREVER
            ]

            const layers = await initLayersWholeSwap();

            const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];

            await dexRouter.connect(alice).smartSwap(
                baseRequest,
                batchesAmount,
                layers,
                pmmRequests
            );

            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1111597868718424651'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
        });


        it("2.8 Try to replace the whole swap with pmm and success", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
    
            await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
            await weth.transfer(bob.address, ethers.utils.parseEther('5'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
            await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
            await dot.transfer(bob.address, ethers.utils.parseEther('2000'));
    
            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
    
            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();
    
            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);
    
            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);
    
            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);
    
            const WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
            const wNativeRelayer = await WNativeRelayer.deploy();
            await wNativeRelayer.deployed;
            await wNativeRelayer.initialize(weth.address);
    
            DexRouter = await ethers.getContractFactory("MockDexRouterForLocalPMMTest");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize(weth.address);
            await dexRouter.setWNativeRelayer(wNativeRelayer.address);
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);
            await wNativeRelayer.setCallerOk([dexRouter.address], true);
    
            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);
    
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('40000'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
            expect(await okb.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
            expect(await dot.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
    
            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": ethers.utils.parseEther('40000'), 
                    "toTokenAmountMin": ethers.utils.parseEther('0.95'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);
    
            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            const pmmRequests = [request];
    
            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('40000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
    
            const baseRequest = [
                '0x80' + '0000000000000000000000' + usdt.address.slice(2),
                wbtc.address,
                swapAmount,
                ethers.utils.parseEther('0.95'),
                FOREVER
            ]
            const layers = await initLayersWholeSwap();
            const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];
    
            await dexRouter.connect(alice).smartSwap(
                baseRequest,
                batchesAmount,
                layers,
                pmmRequests
            );
    
            // 8. check balance
            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from(infos.toTokenAmountMax));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('40000'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2').sub(BigNumber.from(infos.toTokenAmountMax)));
        });
    
        it("2.9 Try to replace the first batch with pmm but failed, turn to dex", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
    
            await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
            await weth.transfer(bob.address, ethers.utils.parseEther('5'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
            await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
            await dot.transfer(bob.address, ethers.utils.parseEther('2000'));
    
            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
    
            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();
    
            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);
    
            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);
    
            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);
    
            const WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
            const wNativeRelayer = await WNativeRelayer.deploy();
            await wNativeRelayer.deployed;
            await wNativeRelayer.initialize(weth.address);
    
            DexRouter = await ethers.getContractFactory("MockDexRouterForLocalPMMTest");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize(weth.address);
            await dexRouter.setWNativeRelayer(wNativeRelayer.address);

            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);
            await wNativeRelayer.setCallerOk([dexRouter.address], true);
    
            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);
    
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('40000'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
            expect(await okb.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
            expect(await dot.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
    
            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": ethers.utils.parseEther('12000'), 
                    "toTokenAmountMin": ethers.utils.parseEther('0.3'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);
    
            let infos = quote[0];
            let request = [
                infos.pathIndex + 1,       // we make a wrong pathIndex here leading to failure of pmm swap 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            const pmmRequests = [request];
    
            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('40000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
    
            const baseRequest = [
                '0x00' + '0000000000000000000000' + usdt.address.slice(2),
                wbtc.address,
                swapAmount,
                ethers.utils.parseEther('1'),
                FOREVER
            ]
            const layers = await initLayersReplaceFirstBatch();
            const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];
    
            await dexRouter.connect(alice).smartSwap(
                baseRequest,
                batchesAmount,
                layers,
                pmmRequests
            );
    
            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1111597868718424651'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
        });
    
    
        it("2.10 Try to replace the first batch with pmm and success", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
    
            await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
            await weth.transfer(bob.address, ethers.utils.parseEther('5'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
            await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
            await dot.transfer(bob.address, ethers.utils.parseEther('2000'));
    
            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
    
            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();
    
            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);
    
            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);
    
            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);
    
            const WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
            const wNativeRelayer = await WNativeRelayer.deploy();
            await wNativeRelayer.deployed;
            await wNativeRelayer.initialize(weth.address);
    
            DexRouter = await ethers.getContractFactory("MockDexRouterForLocalPMMTest");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize(weth.address);
            await dexRouter.setWNativeRelayer(wNativeRelayer.address);
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);
            await wNativeRelayer.setCallerOk([dexRouter.address], true);
    
            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);
    
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('40000'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
            expect(await okb.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
            expect(await dot.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
    
            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": ethers.utils.parseEther('12000'), 
                    "toTokenAmountMin": ethers.utils.parseEther('0.3'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);
    
            let infos = quote[0];
            let request = [
                infos.pathIndex,
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            const pmmRequests = [request];
    
            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('40000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
    
            const baseRequest = [
                '0x00' + '0000000000000000000000' + usdt.address.slice(2),
                wbtc.address,
                swapAmount,
                ethers.utils.parseEther('1'),
                FOREVER
            ]
            const layers = await initLayersReplaceFirstBatch();
            const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];
    
            await dexRouter.connect(alice).smartSwap(
                baseRequest,
                batchesAmount,
                layers,
                pmmRequests
            );
    
            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            // price protected by protection solution
            expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1158703882834055521'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('12000'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(BigNumber.from('1700000000000000000'));
        });

        //  dex swap path
        //  30%  usdt -> weth -> wbtc
        //  20%  usdt -> wbtc
        //  50%  usdt -> okb -> dot -> wbtc

        it("2.11 Try to replace the two hops of the first batch separately with pmm and success", async () => {
            const { chainId }  = await ethers.provider.getNetwork();

            await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
            await weth.transfer(bob.address, ethers.utils.parseEther('5'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
            await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
            await dot.transfer(bob.address, ethers.utils.parseEther('2000'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            const WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
            const wNativeRelayer = await WNativeRelayer.deploy();
            await wNativeRelayer.deployed;
            await wNativeRelayer.initialize(weth.address);

            DexRouter = await ethers.getContractFactory("MockDexRouterForLocalPMMTest");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize(weth.address);
            await dexRouter.setWNativeRelayer(wNativeRelayer.address);
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);
            await wNativeRelayer.setCallerOk([dexRouter.address], true);

            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);

            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('40000'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
            expect(await okb.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
            expect(await dot.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));

            let source1 = await getSource(lpUSDTWETH, usdt.address, weth.address);
            let source2 = await getSource(lpWETHWBTC, weth.address, wbtc.address);

            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": weth.address, 
                    "fromTokenAmount": ethers.utils.parseEther('12000'), 
                    "toTokenAmountMin": ethers.utils.parseEther('4'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source1
                },
                {
                    "pathIndex": 200000000000000,
                    "fromTokenAddress": weth.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": ethers.utils.parseEther('5'), 
                    "toTokenAmountMin": ethers.utils.parseEther('0.375'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source2

                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let request1 = [
                quote[0].pathIndex,
                quote[0].payer, 
                quote[0].fromTokenAddress, 
                quote[0].toTokenAddress, 
                quote[0].fromTokenAmountMax, 
                quote[0].toTokenAmountMax, 
                quote[0].salt, 
                quote[0].deadLine, 
                quote[0].isPushOrder,
                quote[0].extension
            ];
            let request2 = [
                quote[1].pathIndex,
                quote[1].payer, 
                quote[1].fromTokenAddress, 
                quote[1].toTokenAddress, 
                quote[1].fromTokenAmountMax, 
                quote[1].toTokenAmountMax, 
                quote[1].salt, 
                quote[1].deadLine, 
                quote[1].isPushOrder,
                quote[1].extension
            ];

            
            const pmmRequests = [request1, request2];

            let markerAmountWETH = ethers.utils.parseEther('5');
            await weth.connect(bob).approve(tokenApprove.address, markerAmountWETH);
            let markerAmountWBTC = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address, markerAmountWBTC);
            let swapAmount = ethers.utils.parseEther('40000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            const baseRequest = [
                '0x00' + '0000000000000000000000' + usdt.address.slice(2),
                wbtc.address,
                swapAmount,
                ethers.utils.parseEther('1'),
                FOREVER
            ]
            const layers = await initLayersReplaceHops();
            const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];

            await dexRouter.connect(alice).smartSwap(
                baseRequest,
                batchesAmount,
                layers,
                pmmRequests
            );
            
            // 8. check balance, bob was protected by price protection solution
            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1158703882834055521'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('12000'));
            expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(BigNumber.from('1700000000000000000'));
        });

    
    
        it("2.12 Try to replace the two hops of the first batch separately with pmm, one of it failed and turned to dex", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
    
            await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
            await weth.transfer(bob.address, ethers.utils.parseEther('5'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
            await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
            await dot.transfer(bob.address, ethers.utils.parseEther('2000'));
    
            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);
    
            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();
    
            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);
    
            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);
    
            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);
    
            const WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
            const wNativeRelayer = await WNativeRelayer.deploy();
            await wNativeRelayer.deployed;
            await wNativeRelayer.initialize(weth.address);
    
            DexRouter = await ethers.getContractFactory("MockDexRouterForLocalPMMTest");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize(weth.address);
            await dexRouter.setWNativeRelayer(wNativeRelayer.address);
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);
            await wNativeRelayer.setCallerOk([dexRouter.address], true);
    
            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);
    
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('40000'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
            expect(await okb.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
            expect(await dot.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
    
            let source1 = await getSource(lpUSDTWETH, usdt.address, weth.address);
            let source2 = await getSource(lpWETHWBTC, weth.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": weth.address, 
                    "fromTokenAmount": ethers.utils.parseEther('12000'), 
                    "toTokenAmountMin": ethers.utils.parseEther('4'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source1
                },
                {
                    "pathIndex": 200000000000000,
                    "fromTokenAddress": weth.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": ethers.utils.parseEther('5'), 
                    "toTokenAmountMin": ethers.utils.parseEther('0.375'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source2
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);
    
            let request1 = [
                quote[0].pathIndex,
                quote[0].payer, 
                quote[0].fromTokenAddress, 
                quote[0].toTokenAddress, 
                quote[0].fromTokenAmountMax, 
                quote[0].toTokenAmountMax, 
                quote[0].salt, 
                quote[0].deadLine, 
                quote[0].isPushOrder,
                quote[0].extension
            ];
            let request2 = [
                quote[1].pathIndex,     
                quote[1].payer, 
                quote[1].fromTokenAddress, 
                quote[1].toTokenAddress, 
                quote[1].fromTokenAmountMax + 1,    // we make a wrong pathIndex here
                quote[1].toTokenAmountMax, 
                quote[1].salt, 
                quote[1].deadLine, 
                quote[1].isPushOrder,
                quote[1].extension
            ];
    
            
            const pmmRequests = [request1, request2];
    
            let markerAmountWETH = ethers.utils.parseEther('5');
            await weth.connect(bob).approve(tokenApprove.address, markerAmountWETH);
            let markerAmountWBTC = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address, markerAmountWBTC);
            let swapAmount = ethers.utils.parseEther('40000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
    
            const baseRequest = [
                '0x00' + '0000000000000000000000' + usdt.address.slice(2),
                wbtc.address,
                swapAmount,
                ethers.utils.parseEther('1'),
                FOREVER
            ]
            const layers = await initLayersReplaceHops();
            const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];
    
            await dexRouter.connect(alice).smartSwap(
                baseRequest,
                batchesAmount,
                layers,
                pmmRequests
            );
            
            expect(await usdt.balanceOf(alice.address)).to.equal(0);
            expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1130687150998100260'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('12000'));
            expect(await weth.balanceOf(bob.address)).to.equal(BigNumber.from('1000000000000000000'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
        });



        it("2.13 Use a push order twice", async () => {
            const { chainId }  = await ethers.provider.getNetwork();

            await usdt.transfer(alice.address, ethers.utils.parseEther('80000'));
            await weth.transfer(bob.address, ethers.utils.parseEther('5'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
            await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
            await dot.transfer(bob.address, ethers.utils.parseEther('2000'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            const WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
            const wNativeRelayer = await WNativeRelayer.deploy();
            await wNativeRelayer.deployed;
            await wNativeRelayer.initialize(weth.address);

            DexRouter = await ethers.getContractFactory("MockDexRouterForLocalPMMTest");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize(weth.address);
            await dexRouter.setWNativeRelayer(wNativeRelayer.address);
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);
            await wNativeRelayer.setCallerOk([dexRouter.address], true);

            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);

            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('80000'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
            expect(await okb.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
            expect(await dot.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));

            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "takerWantToken": usdt.address, 
                    "makerSellToken": wbtc.address, 
                    "makeAmountMax": '2000000000000000000', 
                    "PriceMin": '40000',
                    "pushQuoteValidPeriod": '3600',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter" : marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPushInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            const pmmRequests = [request];

            // first swap
            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('40000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            const baseRequest = [
                '0x80' + '0000000000000000000000' + usdt.address.slice(2),
                wbtc.address,
                swapAmount,
                ethers.utils.parseEther('1'),
                FOREVER
            ]
            const layers = await initLayersWholeSwap();
            const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];

            await dexRouter.connect(alice).smartSwap(
                baseRequest,
                batchesAmount,
                layers,
                pmmRequests
            );

            // check balance
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('40000'));
            expect(await wbtc.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('1'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('40000'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('1'));

            // second swap
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
            await dexRouter.connect(alice).smartSwap(
                baseRequest,
                batchesAmount,
                layers,
                pmmRequests
            );

            // check balance
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await wbtc.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('2'));
            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('80000'));
            expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));

        });

        it("2.14 DexRouter Swap: Pmm failed and turned to empty batches, revert info emitted", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            DexRouter = await ethers.getContractFactory("DexRouter");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize();
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);

            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source" : source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex + 1, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            const baseRequest = [
                '0x80' + '0000000000000000000000' + usdt.address.toString().slice(2),
                wbtc.address,
                swapAmount,
                ethers.utils.parseEther('0'),
                FOREVER            
            ];

            await expect(
                dexRouter.connect(alice).smartSwap(
                    baseRequest,
                    [swapAmount],
                    [],
                    [request]
                )
            ).to.be.revertedWith("PMMErrorCode(1)");

        });

        it("2.15 DexRouter Swap: Pmm failed and turned to empty hops, revert info emitted", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            DexRouter = await ethers.getContractFactory("DexRouter");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize();
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);

            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source" : source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex + 1, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            const baseRequest = [
                '0x80' + '0000000000000000000000' + usdt.address.toString().slice(2),
                wbtc.address,
                swapAmount,
                ethers.utils.parseEther('0'),
                FOREVER            
            ];

            await expect(
                dexRouter.connect(alice).smartSwap(
                    baseRequest,
                    [swapAmount],
                    [[]],
                    [request]
                )
            ).to.be.revertedWith("PMMErrorCode(1)");

        });

        it("2.16 User swap: pmm failed with revert info", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
            await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

            MarketMaker = await ethers.getContractFactory("MarketMaker");
            marketMaker = await upgrades.deployProxy(
                MarketMaker,[
                    weth.address, 
                    owner.address, 
                    0, 
                    backEnd.address,
                    cancelerGuardian.address
                ]
            );        
            await marketMaker.deployed();
            await marketMaker.connect(bob).setOperator(bob.address);

            const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
            const tokenApproveProxy = await TokenApproveProxy.deploy();
            await tokenApproveProxy.initialize();

            const TokenApprove = await ethers.getContractFactory("TokenApprove");
            const tokenApprove = await TokenApprove.deploy();
            await tokenApprove.initialize(tokenApproveProxy.address);

            await tokenApproveProxy.addProxy(marketMaker.address);
            await tokenApproveProxy.setTokenApprove(tokenApprove.address);

            await tokenApprove.setApproveProxy(tokenApproveProxy.address);
            await marketMaker.setApproveProxy(tokenApproveProxy.address);

            DexRouter = await ethers.getContractFactory("DexRouter");
            const dexRouter = await DexRouter.deploy();
            await dexRouter.deployed();
            await dexRouter.initialize();
            await dexRouter.setApproveProxy(tokenApproveProxy.address);
            await tokenApproveProxy.addProxy(dexRouter.address);

            await marketMaker.setDexRouter(dexRouter.address);
            await marketMaker.setUniV2Factory(factory.address);

            expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

            let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": '50000000000000000000000', 
                    "toTokenAmountMin": '1000000000000000000',
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source" : source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex + 1, 
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];

            let markerAmount = ethers.utils.parseEther('2');
            await wbtc.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('50000');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            const baseRequest = [
                usdt.address,
                wbtc.address,
                swapAmount,
                ethers.utils.parseEther('0'),
                FOREVER            
            ]

            await expect(
                marketMaker.connect(alice).userSwap(
                    baseRequest,
                    request
                )
            ).to.be.revertedWith("PMMErrorCode(1)");

            
        });


    });





    describe("3. Fork OKC Network Test", function() {
        this.timeout(30000);
        let wokt;
        const OKT = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
        const FOREVER = '2000000000';


        const initAccounts = async () => {
            // moc alice as user
            let accountAddress = "0x98FAFc37e930c3C9326EDa1B5B75227f2563cFF6";
            startMockAccount([accountAddress]);
            alice = await ethers.getSigner(accountAddress);
    
            // mock bob as market maker
            accountAddress = "0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6";
            startMockAccount([accountAddress]);
            bob = await ethers.getSigner(accountAddress);
    
        }
    
        const initTokens = async () => {
            btck = await ethers.getContractAt(
                "MockERC20",
                okcdevDeployed.tokens.btck
            );
    
            usdc = await ethers.getContractAt(
                "MockERC20",
                okcdevDeployed.tokens.usdc
            );
    
            usdt = await ethers.getContractAt(
                "MockERC20",
                okcdevDeployed.tokens.usdt
            );
    
            wokt = await ethers.getContractAt(
                "WETH9",
                okcdevDeployed.tokens.wokt
            );
    
            const UniswapPair = await ethers.getContractFactory("UniswapV2Pair");
    
            const factory = await ethers.getContractAt(
                "UniswapV2Factory",
                "0x709102921812B3276A65092Fe79eDfc76c4D4AFe"            // cherry factory
            )
    
            pair = await factory.getPair(usdt.address, wokt.address);
            lpUSDCBTCK = await UniswapPair.attach(pair);
            // console.log("lpUSDCWBTC", lpUSDCWBTC.address);
    
            pair = await factory.getPair(usdc.address, usdt.address)
            lpUSDCUSDT = await UniswapPair.attach(pair);
            // console.log("lpUSDCUSDT", lpUSDCUSDT.address);
    
            pair = await factory.getPair(usdt.address, btck.address)
            lpUSDTBTCK = await UniswapPair.attach(pair);
            // console.log("lpUSDTWBTC", lpUSDTWBTC.address);
    
            pair = await factory.getPair(wokt.address, usdt.address)
            lpWOKTUSDT = await UniswapPair.attach(pair);
            // console.log("lpWETHUSDT", lpWETHUSDT.address);
      
        }
    
        const initContract = async () => {
            dexRouter = await ethers.getContractAt(
                "DexRouter",
                okcdevDeployed.base.dexRouter
            );
    
            tokenApprove = await ethers.getContractAt(
                "TokenApprove",
                okcdevDeployed.base.tokenApprove
            );
    
            uniAdapter = await ethers.getContractAt(
                "UniAdapter",
                okcdevDeployed.adapter.uniV2
            );
    
            marketMaker = await ethers.getContractAt(
                "MarketMaker",
                okcdevDeployed.base.marketMaker
            );
    
        }
    
        const initLayersWholeSwap = async function() {
            //  router11 usdt -> weth
            const mixAdapter11 = [uniAdapter.address];
            const assertTo11 = [lpWOKTUSDT.address];
            const weight11 = getWeight(10000);
            const rawData11 = ["0x" + await direction(wokt.address, usdt.address, lpWOKTUSDT) + "0000000000000000000" + weight11 + lpWOKTUSDT.address.slice(2)];
            const extraData11 = ['0x'];
            const router11 = [mixAdapter11, assertTo11, rawData11, extraData11, wokt.address];
    
            const layers = [[router11]];
            return layers;
        }
    
        const setForkBlockNumber = async (targetBlockNumber) => {
            await network.provider.request({
                method: "hardhat_reset",
                params: [
                    {
                        forking: {
                            // jsonRpcUrl: `http://35.73.164.192:26659`,
                            jsonRpcUrl: ` http://13.230.141.168:26659`,
                            // jsonRpcUrl: `https://okc-mainnet.gateway.pokt.network/v1/lb/6275309bea1b320039c893ff`,
                            blockNumber: targetBlockNumber,
                        },
                    },
                ],
            });
        }

        beforeEach(async function() {
            // fork states 
    
            // 1. prepare accounts
            await setForkBlockNumber(13150000);
    
            await initAccounts();
    
            [, , singer] = await ethers.getSigners();
    
            // console.log("backEnd",backEnd.address);
            // 2. prepare tokens
            await initTokens();
    
            await initContract();
    
    
        });
    
        //  =========================  Multiple  Exchange Test  ============================
    //  dex swap path
    //  100%  okt -> usdt
    //
    //  market maker quotes
    //  100%  okt -> usdt
    //0.183159557704380937
    
    //  price:
    //  okt: 25
    
        it("3.1 Try to replace the whole swap with pmm and success", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            // chainId = 66;
                
            // 5. prepare quotes
            // let source = await getSource(lpWOKTUSDT, wokt.address, usdt.address);
            let source = "0000000000000000000000000000000000000000000000000000000000000000";
            let rfq = [
                {
                    "pathIndex": '202000000000000001',
                    "fromTokenAddress": wokt.address, 
                    "toTokenAddress": usdt.address, 
                    "fromTokenAmount": ethers.utils.parseEther('0.001'), 
                    "toTokenAmountMin": ethers.utils.parseEther('0.025'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned_paidByOKCMockAccount(rfq);
            let quote = multipleQuotes(infosToBeSigned);
    
            // 6. construct of input of funciton swap
            let infos = quote[0];
            let request = [
                infos.pathIndex,
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            const pmmRequests = [request];
    
            // 7. swap
            await marketMaker.connect(bob).setOperator(singer.address);
            let markerAmount = ethers.utils.parseEther('10');
            await usdt.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('0.0001');
            // await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
    
            const baseRequest = [
                '0x80' + '0000000000000000000000' + OKT.slice(2),
                usdt.address,
                swapAmount,
                ethers.utils.parseEther('0.00015'),
                FOREVER
            ]
    
            // const layers = await initLayersWholeSwap();
            const layers = [[]];
    
            const batchesAmount = [swapAmount];
    
            let aliceUSDTBalBefore = await usdt.balanceOf(alice.address);
            let bobWOKTBalBefore = await wokt.balanceOf(bob.address);
    
            let res = await dexRouter.connect(alice).smartSwap(
                baseRequest,
                batchesAmount,
                layers,
                pmmRequests,
                {
                    value: ethers.utils.parseEther('0.0001')
                }
            );
            // let receipt = await res.wait();
            // console.log("receipt.logs", receipt.logs);
            // console.log("res", res.data);
                
            aliceUSDTBalAfter = await usdt.balanceOf(alice.address);
            bobWOKTBalAfter = await wokt.balanceOf(bob.address);
    
    
            // 8. check balance
            expect(aliceUSDTBalAfter.sub(aliceUSDTBalBefore)).to.equal(ethers.utils.parseEther('0.001836650889467037'));
            expect(bobWOKTBalAfter.sub(bobWOKTBalBefore)).to.equal(ethers.utils.parseEther('0.0001'));
    
        });
    
    
    
        it("3.2 Try to replace the whole swap with pmm but failed, turn to dex", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
                
            // 5. prepare quotes
            let source = await getSource(lpWOKTUSDT, wokt.address, usdt.address);
            let rfq = [
                {
                    "pathIndex": '202000000000000002',
                    "fromTokenAddress": wokt.address, 
                    "toTokenAddress": usdt.address, 
                    "fromTokenAmount": ethers.utils.parseEther('0.001'), 
                    "toTokenAmountMin": ethers.utils.parseEther('0.025'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned_paidByOKCMockAccount(rfq);
            let quote = multipleQuotes(infosToBeSigned);
    
            // 6. construct of input of funciton swap
            let infos = quote[0];
            let request = [
                infos.pathIndex + 1,
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            const pmmRequests = [request];
    
            // 7. swap
            await marketMaker.connect(bob).setOperator(singer.address);
            let markerAmount = ethers.utils.parseEther('10');
            await usdt.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('0.0001');
            // await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
    
            const baseRequest = [
                '0x80' + '0000000000000000000000' + OKT.slice(2),
                usdt.address,
                swapAmount,
                ethers.utils.parseEther('0.001'),
                FOREVER
            ]
    
            const layers = await initLayersWholeSwap();
    
            const batchesAmount = [swapAmount];
    
            let aliceUSDTBalBefore = await usdt.balanceOf(alice.address);
            let bobWOKTBalBefore = await wokt.balanceOf(bob.address);
    
    
            let res = await dexRouter.connect(alice).smartSwap(
                baseRequest,
                batchesAmount,
                layers,
                pmmRequests,
                {
                    value: ethers.utils.parseEther('0.0001')
                }
            );
            // let receipt = await res.wait();
            // console.log("receipt.logs", receipt.logs);
            // console.log("res", res);
    
            aliceUSDTBalAfter = await usdt.balanceOf(alice.address);
            bobWOKTBalAfter = await wokt.balanceOf(bob.address);
    
            // 8. check balance
            expect(aliceUSDTBalAfter.sub(aliceUSDTBalBefore)).to.equal(ethers.utils.parseEther('0.001836650872607920'));
            expect(bobWOKTBalAfter.sub(bobWOKTBalBefore)).to.equal(ethers.utils.parseEther('0')); 
        });

        it("3.3 User Swap: ERC20 -> ERC20", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
                
            // 5. prepare quotes
            let source = await getSource(lpWOKTUSDT, wokt.address, usdt.address);
            let rfq = [
                {
                    "pathIndex": '202000000000000002',
                    "fromTokenAddress": wokt.address, 
                    "toTokenAddress": usdt.address, 
                    "fromTokenAmount": ethers.utils.parseEther('0.001'), 
                    "toTokenAmountMin": ethers.utils.parseEther('0.025'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned_paidByOKCMockAccount(rfq);
            let quote = multipleQuotes(infosToBeSigned);
    
            // 6. construct of input of funciton swap
            let infos = quote[0];
            let request = [
                infos.pathIndex,
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            const pmmRequests = request;
    
            // 7. swap
            await marketMaker.connect(bob).setOperator(singer.address);
            let markerAmount = ethers.utils.parseEther('10');
            await usdt.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('0.0001');
            // await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
    
            const baseRequest = [
                wokt.address,
                usdt.address,
                swapAmount,
                ethers.utils.parseEther('0'),
                FOREVER
            ]
        
            let aliceUSDTBalBefore = await usdt.balanceOf(alice.address);
            let bobWOKTBalBefore = await wokt.balanceOf(bob.address);

            let res = await marketMaker.connect(alice).userSwap(
                baseRequest,
                pmmRequests
                // {
                //     value: ethers.utils.parseEther('0.0001')
                // }
            );
            // let receipt = await res.wait();
            // console.log("receipt.logs", receipt.logs);
            // console.log("res", res);
    
            aliceUSDTBalAfter = await usdt.balanceOf(alice.address);
            bobWOKTBalAfter = await wokt.balanceOf(bob.address);
            // console.log("aliceUSDTBalAfter",aliceUSDTBalAfter);
            // console.log("bobWOKTBalAfter",bobWOKTBalAfter);

    
            // 8. check balance
            expect(aliceUSDTBalAfter.sub(aliceUSDTBalBefore)).to.equal(ethers.utils.parseEther('0.001836650889467037'));
            expect(bobWOKTBalAfter.sub(bobWOKTBalBefore)).to.equal(ethers.utils.parseEther('0.0001')); 
        });

        it("3.4 User Swap: Native Token -> ERC20", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
                
            // 5. prepare quotes
            let source = await getSource(lpWOKTUSDT, wokt.address, usdt.address);
            let rfq = [
                {
                    "pathIndex": '202000000000000002',
                    "fromTokenAddress": wokt.address, 
                    "toTokenAddress": usdt.address, 
                    "fromTokenAmount": ethers.utils.parseEther('0.001'), 
                    "toTokenAmountMin": ethers.utils.parseEther('0.025'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned_paidByOKCMockAccount(rfq);
            let quote = multipleQuotes(infosToBeSigned);
    
            // 6. construct of input of funciton swap
            let infos = quote[0];
            let request = [
                infos.pathIndex,
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            const pmmRequests = request;
    
            // 7. swap
            await marketMaker.connect(bob).setOperator(singer.address);
            let markerAmount = ethers.utils.parseEther('10');
            await usdt.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('0.0001');
            // await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
    
            const baseRequest = [
                OKT,
                usdt.address,
                swapAmount,
                ethers.utils.parseEther('0'),
                FOREVER
            ]
        
            let aliceUSDTBalBefore = await usdt.balanceOf(alice.address);
            let bobWOKTBalBefore = await wokt.balanceOf(bob.address);

            let res = await marketMaker.connect(alice).userSwap(
                baseRequest,
                pmmRequests,
                {
                    value: ethers.utils.parseEther('0.0001')
                }
            );
            // let receipt = await res.wait();
            // console.log("receipt.logs", receipt.logs);
            // console.log("res", res);
    
            aliceUSDTBalAfter = await usdt.balanceOf(alice.address);
            bobWOKTBalAfter = await wokt.balanceOf(bob.address);
            // console.log("aliceUSDTBalAfter",aliceUSDTBalAfter);
            // console.log("bobWOKTBalAfter",bobWOKTBalAfter);

    
            // 8. check balance
            expect(aliceUSDTBalAfter.sub(aliceUSDTBalBefore)).to.equal(ethers.utils.parseEther('0.001836650889467037'));
            expect(bobWOKTBalAfter.sub(bobWOKTBalBefore)).to.equal(ethers.utils.parseEther('0.0001')); 
        });

        it("3.5 User Swap: ERC20 -> Native Token", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
                
            // 5. prepare quotes
            let source = await getSource(lpWOKTUSDT, usdt.address, wokt.address);
            let rfq = [
                {
                    "pathIndex": '202000000000000002',
                    "fromTokenAddress": usdt.address, 
                    "toTokenAddress": wokt.address, 
                    "fromTokenAmount": ethers.utils.parseEther('0.018'), 
                    "toTokenAmountMin": ethers.utils.parseEther('0.001'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned_paidByOKCMockAccount(rfq);
            let quote = multipleQuotes(infosToBeSigned);
    
            // 6. construct of input of funciton swap
            let infos = quote[0];
            let request = [
                infos.pathIndex,
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            const pmmRequests = request;
    
            // 7. swap
            await marketMaker.connect(bob).setOperator(singer.address);
            let markerAmount = ethers.utils.parseEther('10');
            await wokt.connect(bob).deposit({value: ethers.utils.parseEther('0.001')});
            await wokt.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('0.0018');
            await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
    
            const baseRequest = [
                usdt.address,
                OKT,
                swapAmount,
                ethers.utils.parseEther('0'),
                FOREVER
            ];
       
            let aliceOKTBalBefore = await ethers.provider.getBalance(alice.address);
            let bobUSDTBalBefore = await usdt.balanceOf(bob.address);
            // console.log("aliceOKTBalBefore",aliceOKTBalBefore);
            // console.log("bobUSDTBalBefore",bobUSDTBalBefore);

            let res = await marketMaker.connect(alice).userSwap(
                baseRequest,
                pmmRequests,
                // {
                //     value: ethers.utils.parseEther('0.0001')
                // }
            );
            let gasPrice = res.gasPrice;
            let receipt = await res.wait();
            // console.log("receipt.logs", receipt.logs);
            // console.log("res", res);
            let gasUsed = await receipt.gasUsed;
    
            aliceOKTBalAfter = await ethers.provider.getBalance(alice.address);
            bobUSDTBalAfter = await usdt.balanceOf(bob.address);
            // console.log("aliceOKTBalAfter",aliceOKTBalAfter);
            // console.log("bobUSDTBalAfter",bobUSDTBalAfter);

    
            // 8. check balance
            expect(aliceOKTBalAfter.add(gasUsed.mul(gasPrice)).sub(aliceOKTBalBefore)).to.equal(ethers.utils.parseEther('0.000097417326845342'));
            expect(bobUSDTBalAfter.sub(bobUSDTBalBefore)).to.equal(ethers.utils.parseEther('0.0018')); 
        });

    });
    


    describe("4. Fork Eth Network Test", function() {
        this.timeout(30000);

        let owner, alice, bob, backEnd, cancelerGuardian;
        let weth, factory;
        const ETH = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
        const FOREVER = '2000000000';


        //  ==========================  internal functions  ===========================

        const initAccounts = async () => {
            // set alice's balance as 100 eth
            let accountAddress = "0xbCDb3624c3101463c7EF19e8cfe94183Dc45b2Fd";
            startMockAccount([accountAddress]);
            alice = await ethers.getSigner(accountAddress);
            setBalance(alice.address, '0x56bc75e2d63100000');
            // mock bob as a rich account for market maker
            accountAddress = "0x7abE0cE388281d2aCF297Cb089caef3819b13448";
            startMockAccount([accountAddress]);
            bob = await ethers.getSigner(accountAddress);

            accountAddress = "0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6";
            startMockAccount([accountAddress]);
            proxyOwner = await ethers.getSigner(accountAddress);
            setBalance(proxyOwner.address, '0x56bc75e2d63100000');

        }

        const initTokens = async () => {
            wbtc = await ethers.getContractAt(
                "MockERC20",
                ethdevDeployed.tokens.wbtc
            );

            usdc = await ethers.getContractAt(
                "MockERC20",
                ethdevDeployed.tokens.usdc
            );

            usdt = await ethers.getContractAt(
                "MockERC20",
                ethdevDeployed.tokens.usdt
            );

            uni = await ethers.getContractAt(
                "MockERC20",
                ethdevDeployed.tokens.uni
            );

            weth = await ethers.getContractAt(
                "WETH9",
                ethdevDeployed.tokens.weth
            )

            const UniswapPair = await ethers.getContractFactory("UniswapV2Pair");

            factory = await ethers.getContractAt(
                "UniswapV2Factory",
                "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f"
            )

            pair = await factory.getPair(usdc.address, wbtc.address)
            lpUSDCWBTC = await UniswapPair.attach(pair);
            // console.log("lpUSDCWBTC", lpUSDCWBTC.address);

            pair = await factory.getPair(usdc.address, usdt.address)
            lpUSDCUSDT = await UniswapPair.attach(pair);
            // console.log("lpUSDCUSDT", lpUSDCUSDT.address);

            pair = await factory.getPair(usdt.address, wbtc.address)
            lpUSDTWBTC = await UniswapPair.attach(pair);
            // console.log("lpUSDTWBTC", lpUSDTWBTC.address);

            pair = await factory.getPair(weth.address, usdt.address)
            lpWETHUSDT = await UniswapPair.attach(pair);
            // console.log("lpWETHUSDT", lpWETHUSDT.address);

            pair = await factory.getPair(weth.address, uni.address)
            lpWETHUNI = await UniswapPair.attach(pair);
            // console.log("lpWETHUNI", lpWETHUNI.address);
    
        }

        const initContract = async () => {
            dexRouter = await ethers.getContractAt(
                "DexRouter",
                ethdevDeployed.base.dexRouter
            );
    
            tokenApprove = await ethers.getContractAt(
                "TokenApprove",
                ethdevDeployed.base.tokenApprove
            );
    
            uniAdapter = await ethers.getContractAt(
                "UniAdapter",
                ethdevDeployed.adapter.uniV2
            );
    
            marketMaker = await ethers.getContractAt(
                "MarketMaker",
                ethdevDeployed.base.marketMaker
            );
    
        }

        const initLayersWholeSwap = async function() {
            //  router11 usdt -> weth
            const mixAdapter11 = [uniAdapter.address];
            const assertTo11 = [lpWETHUNI.address];
            const weight11 = getWeight(10000);
            const rawData11 = ["0x" + await direction(weth.address, uni.address, lpWETHUNI) + "0000000000000000000" + weight11 + lpWETHUNI.address.slice(2)];
            const extraData11 = ['0x'];
            const router11 = [mixAdapter11, assertTo11, rawData11, extraData11, weth.address];

            const layers = [[router11]];
            return layers;
        }

        const setForkBlockNumber = async (targetBlockNumber) => {
            const INFURA_KEY = process.env.INFURA_KEY || '';
            await network.provider.request({
                method: "hardhat_reset",
                params: [
                    {
                        forking: {
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
            // fork states 
            // https://cn.etherscan.com/tx/0xd4902a42097534a33ecf9b2e817c80da1972e91effd58a06abbe0214c107c25f

            // 1. prepare accounts
            await setForkBlockNumber(15382800);
            await initAccounts();
            [owner,,signer,,backEnd, cancelerGuardian] = await ethers.getSigners();

            // console.log("backEnd",backEnd.address);
            // 2. prepare tokens
            await initTokens();

            await initContract();

        });

        //  dex swap path
        //  100%  eth -> uni
        //
        //  market maker quotes
        //  100%  eth -> uni
        it("4.1 Try to replace the whole swap with pmm and success, price protected by uniV2", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await marketMaker.connect(bob).setOperator(signer.address);

            let source = await getSource(lpWETHUNI, weth.address, uni.address);

            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": weth.address, 
                    "toTokenAddress": uni.address, 
                    "fromTokenAmount": ethers.utils.parseEther('0.014'), 
                    "toTokenAmountMin": ethers.utils.parseEther('3'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned_paidByETHMockAccount(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex,
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            const pmmRequests = [request];

            let markerAmount = ethers.utils.parseEther('10');
            await uni.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('0.013658558763417873');
            // await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            const baseRequest = [
                '0x80' + '0000000000000000000000' + ETH.slice(2),
                uni.address,
                swapAmount,
                ethers.utils.parseEther('2'),
                FOREVER
            ]

            const layers = await initLayersWholeSwap();

            const batchesAmount = [swapAmount];

            let aliceUniBalBefore = await uni.balanceOf(alice.address);

            let res = await dexRouter.connect(alice).smartSwap(
                baseRequest,
                batchesAmount,
                layers,
                pmmRequests,
                {
                    value: ethers.utils.parseEther('0.013658558763417873')
                }
            );

            aliceUniBalAfter = await uni.balanceOf(alice.address);

            expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0.013658558763417873'));
            expect(aliceUniBalAfter.sub(aliceUniBalBefore)).to.equal(ethers.utils.parseEther('2.956102360939725370'));

        })

        it("4.2 Try to replace the whole swap with pmm and success, price protected by uniV3", async () => {
            const { chainId }  = await ethers.provider.getNetwork();

            await marketMaker.connect(bob).setOperator(signer.address);

            let lpUNIWETH = await ethers.getContractAt(
                "IUniV3",
                "0x1d42064Fc4Beb5F8aAF85F4617AE8b3b5B8Bd801"
            )
            let source = await getUniV3Source(lpUNIWETH, weth.address, uni.address);

            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": weth.address, 
                    "toTokenAddress": uni.address, 
                    "fromTokenAmount": ethers.utils.parseEther('0.014'), 
                    "toTokenAmountMin": ethers.utils.parseEther('3'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned_paidByETHMockAccount(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            let infos = quote[0];
            let request = [
                infos.pathIndex,
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            const pmmRequests = [request];

            let markerAmount = ethers.utils.parseEther('10');
            await uni.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('0.013658558763417873');
            // await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            const baseRequest = [
                '0x80' + '0000000000000000000000' + ETH.slice(2),
                uni.address,
                swapAmount,
                ethers.utils.parseEther('2'),
                FOREVER
            ]

            const layers = await initLayersWholeSwap();

            const batchesAmount = [swapAmount];

            let aliceUniBalBefore = await uni.balanceOf(alice.address);

            await dexRouter.connect(alice).smartSwap(
                baseRequest,
                batchesAmount,
                layers,
                pmmRequests,
                {
                    value: ethers.utils.parseEther('0.013658558763417873')
                }
            );

            aliceUniBalAfter = await uni.balanceOf(alice.address);

            expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0.013658558763417873'));
            expect(aliceUniBalAfter.sub(aliceUniBalBefore)).to.equal(ethers.utils.parseEther('2.956102360939725370'));

        })



        it("4.3 Try to replace the whole swap with pmm but failed, turn to dex", async () => {
            const { chainId }  = await ethers.provider.getNetwork();
            await marketMaker.connect(bob).setOperator(signer.address);
                
            // 1. prepare quotes
            let source = await getUniV3Source(lpWETHUNI, weth.address, uni.address);
            let rfq = [
                {
                    "pathIndex": 100000000000000,
                    "fromTokenAddress": weth.address, 
                    "toTokenAddress": uni.address, 
                    "fromTokenAmount": ethers.utils.parseEther('0.014'), 
                    "toTokenAmountMin": ethers.utils.parseEther('3'),
                    "chainId": chainId,
                    "marketMaker": marketMaker.address,
                    "pmmAdapter": marketMaker.address,
                    "source": source
                }
            ]
            let infosToBeSigned = getPullInfosToBeSigned_paidByETHMockAccount(rfq);
            let quote = multipleQuotes(infosToBeSigned);

            // 2. construct of input of funciton swap
            let infos = quote[0];
            let request = [
                infos.pathIndex + 1,        // we make a wrong pathIndex here leading to failure of pmm swap
                infos.payer, 
                infos.fromTokenAddress, 
                infos.toTokenAddress, 
                infos.fromTokenAmountMax, 
                infos.toTokenAmountMax, 
                infos.salt, 
                infos.deadLine, 
                infos.isPushOrder,
                infos.extension
            ];
            const pmmRequests = [request];

            // 3. swap
            let markerAmount = ethers.utils.parseEther('10');
            await uni.connect(bob).approve(tokenApprove.address, markerAmount);
            let swapAmount = ethers.utils.parseEther('0.013658558763417873');
            // await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

            const baseRequest = [
                '0x80' + '0000000000000000000000' + ETH.slice(2),
                uni.address,
                swapAmount,
                ethers.utils.parseEther('2'),
                FOREVER
            ]

            const layers = await initLayersWholeSwap();

            const batchesAmount = [swapAmount];

            let aliceUniBalBefore = await uni.balanceOf(alice.address);

            await dexRouter.connect(alice).smartSwap(
                baseRequest,
                batchesAmount,
                layers,
                pmmRequests,
                {
                    value: ethers.utils.parseEther('0.013658558763417873')
                }
            );

            aliceUniBalAfter = await uni.balanceOf(alice.address);
            uniOut = aliceUniBalAfter.sub(aliceUniBalBefore);

            // 4. check balance
            expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
            expect(uniOut).to.equal(ethers.utils.parseEther('3.028693610581796279'));
        });

    });
}) 









