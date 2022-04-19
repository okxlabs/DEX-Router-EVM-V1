const { getPullInfosToBeSigned, getPullInfosToBeSigned_paidByCarol, multipleQuotes, getDigest } = require("./pmm/quoter");
const { ethers } = require("hardhat");
const { BigNumber } = require('ethers')
const { expect } = require("chai");

describe("Market Marker test", function() {

    let wbtc, usdt, weth;
    let owner, alice, bob, carol;

    beforeEach(async function() {
        // 1. prepare accounts and chain id
        [owner, alice, bob, carol] = await ethers.getSigners();

        // 2. prepare mock tokens
        await initMockTokens();

        await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
    });

    it("ERC20 Exchange without approve", async () => {
        const { chainId }  = await ethers.provider.getNetwork();

        // 3. prepare marketMaker
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        const marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0);

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

        let quote = multipleQuotes(
            infosToBeSigned.pullInfosToBeSigned, 
            infosToBeSigned.chainId, 
            infosToBeSigned.marketMaker,
            infosToBeSigned.pmmAdapter
        );

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
            infos.pmmAdapter,
            infos.signature
        ];

        // 7. swap

        // what if bob has not approved token ?
        // let markerAmount = ethers.utils.parseEther('2');
        // await wbtc.connect(bob).approve(tokenApprove.address,markerAmount);
        let swapAmount = ethers.utils.parseEther('50000');
        await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

        let errorCode = await marketMaker.connect(alice).callStatic.swap(
            swapAmount,
            request
        )
        await expect(errorCode).to.equal(6);
        
    });

    it("ERC20 Exchange with invalid pmm swap request", async () => {
        const { chainId }  = await ethers.provider.getNetwork();

        // 3. prepare marketMaker
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        const marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0);

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

        let quote = multipleQuotes(
            infosToBeSigned.pullInfosToBeSigned, 
            infosToBeSigned.chainId, 
            infosToBeSigned.marketMaker,
            infosToBeSigned.pmmAdapter
        );

        // 6. construct of input of funciton swap
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
            infos.pmmAdapter,
            infos.signature
        ];

        // 7. swap
        let markerAmount = ethers.utils.parseEther('2');
        await wbtc.connect(bob).approve(tokenApprove.address,markerAmount);
        let swapAmount = ethers.utils.parseEther('50000');
        await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

        let errorCode = await marketMaker.connect(alice).callStatic.swap(
            swapAmount,
            request
        )
        await expect(errorCode).to.equal(1);

    });

    it("Set operator", async () => {
        const { chainId }  = await ethers.provider.getNetwork();

        // 3. prepare marketMaker
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        const marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0);

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
        await wbtc.transfer(carol.address, ethers.utils.parseEther('2'));

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
        let infosToBeSigned = getPullInfosToBeSigned_paidByCarol(rfq);

        let quote = multipleQuotes(
            infosToBeSigned.pullInfosToBeSigned, 
            infosToBeSigned.chainId, 
            infosToBeSigned.marketMaker,
            infosToBeSigned.pmmAdapter
        );

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
            infos.pmmAdapter,
            infos.signature
        ];

        // 7. swap
        let markerAmount = ethers.utils.parseEther('2');
        await wbtc.connect(carol).approve(tokenApprove.address,markerAmount);
        let swapAmount = ethers.utils.parseEther('50000');
        await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

        // carol has not set bob as operator
        let errorCode = await marketMaker.connect(alice).callStatic.swap(
            swapAmount,
            request
        )
        await expect(errorCode).to.equal(1);

        // carol has set bob as operator
        await marketMaker.connect(carol).setOperator(bob.address);
        await marketMaker.connect(alice).swap(
            swapAmount,
            request
        );

        // 8. check balance
        // console.log("alice get usdt: " + await usdt.balanceOf(alice.address));
        // console.log("after bob usdt: " + await usdt.balanceOf(bob.address));
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(infos.toTokenAmountMax);
        expect(await usdt.balanceOf(carol.address)).to.equal(ethers.utils.parseEther('50000'));
        expect(await wbtc.balanceOf(carol.address)).to.equal(ethers.utils.parseEther('2').sub(BigNumber.from(infos.toTokenAmountMax)));
    });

    it("Cancel quotes and query order status", async () => {
        const { chainId }  = await ethers.provider.getNetwork();

        // 3. prepare marketMaker
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        const marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0);

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
        await wbtc.transfer(carol.address, ethers.utils.parseEther('2'));

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
        let infosToBeSigned = getPullInfosToBeSigned_paidByCarol(rfq);

        let quote = multipleQuotes(
            infosToBeSigned.pullInfosToBeSigned, 
            infosToBeSigned.chainId, 
            infosToBeSigned.marketMaker,
            infosToBeSigned.pmmAdapter
        );

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
            infos.pmmAdapter,
            infos.signature
        ];

        // 7. swap
        let markerAmount = ethers.utils.parseEther('2');
        await wbtc.connect(carol).approve(tokenApprove.address,markerAmount);
        let swapAmount = ethers.utils.parseEther('50000');
        await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
        await marketMaker.connect(carol).setOperator(bob.address);

        // query order status before cancel quote
        let hash = getDigest(request, chainId, marketMaker.address);
        let orderStatus = await marketMaker.queryOrderStatus([hash]);
        expect(orderStatus[0].cancelledOrFinalized).to.equal(false);


        // carol cancelled quotes
        await marketMaker.connect(carol).cancelQuotes([request]);

        errorCode = await marketMaker.connect(alice).callStatic.swap(
            swapAmount,
            request
        );

        expect(errorCode).to.equal(4);

        // query order status after cancel quote
        orderStatus = await marketMaker.queryOrderStatus([hash]);
        expect(orderStatus[0].cancelledOrFinalized).to.equal(true);

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