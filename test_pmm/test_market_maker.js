const { getPullInfosToBeSigned, multipleQuotes } = require("./pmm/quoter");
const { ethers } = require("hardhat");
const { BigNumber } = require('ethers')
const { expect } = require("chai");

describe("Market Marker test", function() {

    let wbtc, usdt, weth;
    let owner, alice, bob, carol, backEnd;

    beforeEach(async function() {
        // 1. prepare accounts and chain id
        [owner, alice, bob, carol, backEnd] = await ethers.getSigners();

        // 2. prepare mock tokens
        await initMockTokens();

        await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
    });

    it("ERC20 Exchange By FixRate", async () => {
        const { chainId }  = await ethers.provider.getNetwork();

        // 3. prepare marketMaker
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        const marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0, backEnd.address);
        await marketMaker.connect(bob).setOperator(bob.address);
        let ownerAddress = await marketMaker.owner();

        // 4. approve
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

        // console.log("before bob usdt: " + await usdt.balanceOf(bob.address));
        // console.log("before alice usdt: " + await usdt.balanceOf(alice.address));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
        expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

        // 5. prepare quotes
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": usdt.address, 
                "toTokenAddress": wbtc.address, 
                "fromTokenAmount": '50000000000000000000000', 
                "toTokenAmountMin": '1000000000000000000',
                "chainId": chainId,
                "marketMaker": marketMaker.address,
                "pmmAdapter" : ethers.constants.AddressZero
            }
        ]
        let infosToBeSigned = getPullInfosToBeSigned(rfq);
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
        // 7. swap
        let markerAmount = ethers.utils.parseEther('2');
        await wbtc.connect(bob).approve(tokenApprove.address,markerAmount);
        let swapAmount = ethers.utils.parseEther('50000');
        await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
        await marketMaker.connect(alice).swap(
            swapAmount,
            request
        );

        // 8. check balance
        // console.log("alice get usdt: " + await usdt.balanceOf(alice.address));
        // console.log("after bob usdt: " + await usdt.balanceOf(bob.address));
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(infos.toTokenAmountMax);
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('50000'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2').sub(BigNumber.from(infos.toTokenAmountMax)));
    });

    it("ERC20 Exchange By FixRate With PMMAdapter", async () => {
        const { chainId }  = await ethers.provider.getNetwork();

        // 3. prepare marketMaker
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        const marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0, backEnd.address);
        await marketMaker.connect(bob).setOperator(bob.address);

        // 4. approve
        const TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy");
        const tokenApproveProxy = await TokenApproveProxy.deploy();
        await tokenApproveProxy.initialize();

        const TokenApprove = await ethers.getContractFactory("TokenApprove");
        const tokenApprove = await TokenApprove.deploy();
        await tokenApprove.initialize(tokenApproveProxy.address);

        await tokenApproveProxy.addProxy(marketMaker.address);
        await tokenApproveProxy.setTokenApprove(tokenApprove.address);

        await tokenApprove.setApproveProxy(tokenApproveProxy.address);

        // let ownerAddress = await marketMaker.owner();
        // console.log("marketMaker owner", ownerAddress);
        await marketMaker.setApproveProxy(tokenApproveProxy.address);

        PMMAdapter = await ethers.getContractFactory("PMMAdapter");
        pmmAdapter = await PMMAdapter.deploy(marketMaker.address, alice.address);

        await marketMaker.addPmmAdapter(pmmAdapter.address);

        // console.log("before bob usdt: " + await usdt.balanceOf(bob.address));
        // console.log("before alice usdt: " + await usdt.balanceOf(alice.address));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
        expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

        // 5. prepare quotes
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": usdt.address, 
                "toTokenAddress": wbtc.address, 
                "fromTokenAmount": '50000000000000000000000', 
                "toTokenAmountMin": '1000000000000000000',
                "chainId": chainId,
                "marketMaker": marketMaker.address,
                "pmmAdapter": pmmAdapter.address
            }
        ]
        let infosToBeSigned = getPullInfosToBeSigned(rfq);
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

        // 7. swap
        let markerAmount = ethers.utils.parseEther('2');
        await wbtc.connect(bob).approve(tokenApprove.address,markerAmount);
        let swapAmount = ethers.utils.parseEther('50000');

        await usdt.connect(alice).transfer(pmmAdapter.address, swapAmount);
        data = ethers.utils.defaultAbiCoder.encode(
            ['tuple(uint256,address,address,address,uint256,uint256,uint256,uint256,bool,bytes)'],
            [request]
        )
        await pmmAdapter.connect(alice).sellBase(alice.address, ethers.constants.AddressZero, data);

        // 8. check balance
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(infos.toTokenAmountMax);
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('50000'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2').sub(BigNumber.from(infos.toTokenAmountMax)));
    });

    it("ERC20 Exchange By FixRate With DEXRouter", async () => {
        const { chainId }  = await ethers.provider.getNetwork();

        // 3. prepare marketMaker
        let marketMaker;
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0, backEnd.address);
        // await marketMaker.connect(bob).setOperator(bob.address);

        // 4. approve
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

        PMMAdapter = await ethers.getContractFactory("PMMAdapter");
        pmmAdapter = await PMMAdapter.deploy(marketMaker.address, dexRouter.address);

        await marketMaker.addPmmAdapter(pmmAdapter.address);
        // 给 DexRouter 设置为 pmmAdapter 合约地址
        // await dexRouter.setPmmAdapter(pmmAdapter.address);

        // console.log("before bob usdt: " + await usdt.balanceOf(bob.address));
        // console.log("before alice usdt: " + await usdt.balanceOf(alice.address));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
        expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('50000'));

        // 5. prepare quotes
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": usdt.address, 
                "toTokenAddress": wbtc.address, 
                "fromTokenAmount": '50000000000000000000000', 
                "toTokenAmountMin": '1000000000000000000',
                "chainId": chainId,
                "marketMaker": marketMaker.address,
                "pmmAdapter": pmmAdapter.address
            }
        ]
        let infosToBeSigned = getPullInfosToBeSigned(rfq);
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

        // 7. swap
        let markerAmount = ethers.utils.parseEther('2');
        await wbtc.connect(bob).approve(tokenApprove.address, markerAmount);
        let swapAmount = ethers.utils.parseEther('50000');
        await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x80' + '0000000000000000000000' + usdt.address.toString().slice(2),
            wbtc.address,
            swapAmount,
            ethers.utils.parseEther('0'),
            2000000000
        ]
        // const RouterPath = [
        //     // address[] mixAdapters;
        //     // address[] assetTo;
        //     // uint256[] rawData;
        //     // bytes[] extraData;
        //     // address fromToken;
        //     // [pmmAdapter.address]
        // ]
        await dexRouter.connect(alice).smartSwap(
            baseRequest,
            [swapAmount],
            [[]],
            [request]
        );

        // 8. check balance
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(infos.toTokenAmountMax);
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('50000'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2').sub(BigNumber.from(infos.toTokenAmountMax)));
    });

    async function initMockTokens() {
        // alice has 50000 usdt, bob has 2 wbtc
        // alice want to buy 1 wbtc with her 50000 usdt, and bob is willing to provide pmm liquidity
        const MockERC20 = await ethers.getContractFactory("MockERC20");

        usdt = await MockERC20.deploy('USDT', 'USDT', ethers.utils.parseEther('10000000000'));
        await usdt.deployed();

        wbtc = await MockERC20.deploy('WBTC', 'WBTC', ethers.utils.parseEther('10000000000'));
        await wbtc.deployed();

        weth = await MockERC20.deploy('WETH', 'WETH', ethers.utils.parseEther('10000000000'));
        await wbtc.deployed();
    }
});