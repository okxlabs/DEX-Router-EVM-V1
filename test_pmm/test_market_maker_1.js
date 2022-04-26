const { getPullInfosToBeSigned, getPullInfosToBeSigned_paidByCarol, getPushInfosToBeSigned, multipleQuotes, getDigest } = require("./pmm/quoter");
const { ethers } = require("hardhat");
const { BigNumber } = require('ethers')
const { expect } = require("chai");

describe("Market Marker test", function() {

    let wbtc, usdt, weth;
    let owner, alice, bob, carol, backEnd;
    const ETH = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

    beforeEach(async function() {
        // 1. prepare accounts and chain id
        [owner, alice, bob, carol, backEnd] = await ethers.getSigners();

        // 2. prepare mock tokens
        await initMockTokens();
    });

    it("MarketMaker test: Approve token", async () => {
        const { chainId }  = await ethers.provider.getNetwork();
        await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

        // 3. prepare marketMaker
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        const marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0, backEnd.address);

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

        // what if bob has not approved token ?
        let swapAmount = ethers.utils.parseEther('50000');
        await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
        await marketMaker.connect(bob).setOperator(bob.address);

        let errorCode = await marketMaker.connect(alice).callStatic.swap(
            swapAmount,
            request
        )
        await expect(errorCode).to.equal(7);

        // after bob approve token
        let markerAmount = ethers.utils.parseEther('2');
        await wbtc.connect(bob).approve(tokenApprove.address,markerAmount);

        await marketMaker.connect(alice).swap(
            swapAmount,
            request
        )

        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(infos.toTokenAmountMax);
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('50000'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2').sub(BigNumber.from(infos.toTokenAmountMax)));
        
    });

    it("MarketMaker test: Invalid pmm swap request", async () => {
        const { chainId }  = await ethers.provider.getNetwork();
        await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

        // 3. prepare marketMaker
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        const marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0, ethers.constants.AddressZero);

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

    it("MarketMaker test: Set operator", async () => {
        const { chainId }  = await ethers.provider.getNetwork();
        await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

        // 3. prepare marketMaker
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        const marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0, backEnd.address);

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

    it("MarketMaker test: Cancel quotes and query order status", async () => {
        const { chainId }  = await ethers.provider.getNetwork();
        await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

        // 3. prepare marketMaker
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        const marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0, backEnd.address);

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
        let quote = multipleQuotes(infosToBeSigned);

        // 6. construct of input of funciton swap
        let infos = quote[0];
        let requestForCancel = [
            infos.pathIndex, 
            infos.payer, 
            infos.fromTokenAddress, 
            infos.toTokenAddress, 
            infos.fromTokenAmountMax, 
            infos.toTokenAmountMax, 
            infos.salt, 
            infos.deadLine, 
            infos.isPushOrder,
            '0x' + infos.extension.slice(130,258)
        ];

        // 7. swap
        let markerAmount = ethers.utils.parseEther('2');
        await wbtc.connect(carol).approve(tokenApprove.address,markerAmount);
        let swapAmount = ethers.utils.parseEther('50000');
        await usdt.connect(alice).approve(tokenApprove.address, swapAmount);
        await marketMaker.connect(carol).setOperator(bob.address);

        // query order status before cancel quote
        let hash = getDigest(requestForCancel, chainId, marketMaker.address);
        let orderStatus = await marketMaker.queryOrderStatus([hash]);
        expect(orderStatus[0].cancelledOrFinalized).to.equal(false);


        // carol cancelled quotes
        await marketMaker.connect(carol).cancelQuotes([requestForCancel]);


        let requestForSwap = [
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
        errorCode = await marketMaker.connect(alice).callStatic.swap(
            swapAmount,
            requestForSwap
        );

        expect(errorCode).to.equal(5);

        // query order status after cancel quote
        orderStatus = await marketMaker.queryOrderStatus([hash]);
        expect(orderStatus[0].cancelledOrFinalized).to.equal(true);

    });

    it("MarketMaker test: Reuse a pull quote which has been already been used", async () => {
        const { chainId }  = await ethers.provider.getNetwork();
        await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

        // 3. prepare marketMaker
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        const marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0, backEnd.address);

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
        let swapAmount = ethers.utils.parseEther('10000');
        await usdt.connect(alice).approve(tokenApprove.address, ethers.utils.parseEther('50000'));

        await marketMaker.connect(alice).swap(
            swapAmount,
            request
        )

        let errorCode = await marketMaker.connect(alice).callStatic.swap(
            swapAmount,
            request
        )

        await expect(errorCode).to.equal(5);
        
    });

    it("MarketMaker test: Actual request amount exceeds fromTokenAmountMax of a push order", async () => {
        const { chainId }  = await ethers.provider.getNetwork();
        await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

        // 3. prepare marketMaker
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        const marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0, backEnd.address);

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
                "takerWantToken": usdt.address, 
                "makerSellToken": wbtc.address, 
                "makeAmountMax": '1000000000000000000', 
                "PriceMin": '50000',
                "pushQuoteValidPeriod": '3600',
                "chainId": chainId,
                "marketMaker": marketMaker.address,
                "pmmAdapter" : ethers.constants.AddressZero
            }
          ]
        let infosToBeSigned = getPushInfosToBeSigned(rfq);
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
        await usdt.connect(alice).approve(tokenApprove.address, ethers.utils.parseEther('50000'));

        let hash = getDigest(request, chainId, marketMaker.address);

        await marketMaker.connect(alice).swap(
            swapAmount,
            request
        )

        let orderStatus = await marketMaker.queryOrderStatus([hash]);
        await expect(BigNumber.from(orderStatus[0].fromTokenAmountUsed)).to.equal(ethers.utils.parseEther('50000'));

        await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
        let errorCode = await marketMaker.connect(alice).callStatic.swap(
            swapAmount,
            request
        )
        await expect(errorCode).to.equal(6);
        
    });

    it("DexRouter -> MarketMaker test: ERC20 Exchange ERC20", async () => {
        const { chainId }  = await ethers.provider.getNetwork();
        await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));

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

    // since the origin DexRouter use a constant of _WETH, here we have to use a temp version of DexRouter which we can config weth
    it("DexRouter -> MarketMaker test: Native token Exchange ERC20", async () => {
        const { chainId }  = await ethers.provider.getNetwork();
        await usdt.transfer(bob.address, ethers.utils.parseEther('5000'));

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

        const WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
        const wNativeRelayer = await WNativeRelayer.deploy();
        await wNativeRelayer.deployed;
        await wNativeRelayer.initialize(weth.address);

        DexRouter = await ethers.getContractFactory("MockDexRouterForLocalPMMTest");
        const dexRouter = await DexRouter.deploy();
        await dexRouter.deployed();
        await dexRouter.initialize(weth.address, wNativeRelayer.address);
        await dexRouter.setApproveProxy(tokenApproveProxy.address);
        await tokenApproveProxy.addProxy(dexRouter.address);

        PMMAdapter = await ethers.getContractFactory("PMMAdapter");
        pmmAdapter = await PMMAdapter.deploy(marketMaker.address, dexRouter.address);

        await marketMaker.addPmmAdapter(pmmAdapter.address);

        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5000'));
        expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('0'));

        // 5. prepare quotes
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": weth.address, 
                "toTokenAddress": usdt.address, 
                "fromTokenAmount": '1000000000000000000', 
                "toTokenAmountMin": '3000000000000000000000',
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
        let markerAmount = ethers.utils.parseEther('5000');
        await usdt.connect(bob).approve(tokenApprove.address, markerAmount);
        let swapAmount = ethers.utils.parseEther('1');
        // await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x80' + '0000000000000000000000' + ETH.slice(2),
            usdt.address,
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
        // let ethBalanceBeforeSwap = await ethers.provider.getBalance(alice.address);
        // console.log("alice eth balance before swap", ethBalanceBeforeSwap);
        await dexRouter.connect(alice).smartSwap(
            baseRequest,
            [swapAmount],
            [[]],
            [request],
            {
                value: ethers.utils.parseEther('1')
            }
        );
        // let ethBalanceAfterSwap = await ethers.provider.getBalance(alice.address);
        // console.log("alice eth balance after swap", ethBalanceAfterSwap);

        // 8. check balance
        expect(await usdt.balanceOf(alice.address)).to.equal(BigNumber.from(infos.toTokenAmountMax));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5000').sub(BigNumber.from(infos.toTokenAmountMax)));
        expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('1'));

    });

    // since the origin DexRouter use a constant of _WETH, here we have to use a temp version of DexRouter which we can config weth
    it("DexRouter -> MarketMaker test: ERC20 Exchange Native token ", async () => {
        const { chainId }  = await ethers.provider.getNetwork();
        await usdt.transfer(alice.address, ethers.utils.parseEther('3000'));
        await weth.connect(bob).deposit(            {
            value: ethers.utils.parseEther('2')
        });

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

        const WNativeRelayer = await ethers.getContractFactory("WNativeRelayer");
        const wNativeRelayer = await WNativeRelayer.deploy();
        await wNativeRelayer.deployed;
        await wNativeRelayer.initialize(weth.address);

        DexRouter = await ethers.getContractFactory("MockDexRouterForLocalPMMTest");
        const dexRouter = await DexRouter.deploy();
        await dexRouter.deployed();
        await dexRouter.initialize(weth.address, wNativeRelayer.address);
        await dexRouter.setApproveProxy(tokenApproveProxy.address);
        await tokenApproveProxy.addProxy(dexRouter.address);
        await wNativeRelayer.setCallerOk([dexRouter.address], true);

        PMMAdapter = await ethers.getContractFactory("PMMAdapter");
        pmmAdapter = await PMMAdapter.deploy(marketMaker.address, dexRouter.address);

        await marketMaker.addPmmAdapter(pmmAdapter.address);

        expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('3000'));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));

        // 5. prepare quotes
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": usdt.address, 
                "toTokenAddress": weth.address, 
                "fromTokenAmount": '3000000000000000000000', 
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
        await weth.connect(bob).approve(tokenApprove.address, markerAmount);
        let swapAmount = ethers.utils.parseEther('3000');
        await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x80' + '0000000000000000000000' + usdt.address.slice(2),
            ETH,
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
        // let ethBalanceBeforeSwap = await ethers.provider.getBalance(alice.address);
        // console.log("alice eth balance before swap", ethBalanceBeforeSwap);
        await dexRouter.connect(alice).smartSwap(
            baseRequest,
            [swapAmount],
            [[]],
            [request]
        );
        // let ethBalanceAfterSwap = await ethers.provider.getBalance(alice.address);
        // console.log("alice eth balance before swap", ethBalanceAfterSwap);
        // console.log(ethers.utils.formatEther(ethBalanceAfterSwap.sub(ethBalanceBeforeSwap)));

        // 8. check balance
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('3000'));
    });

    async function initMockTokens() {
        // alice has 50000 usdt, bob has 2 wbtc
        // alice want to buy 1 wbtc with her 50000 usdt, and bob is willing to provide pmm liquidity
        const MockERC20 = await ethers.getContractFactory("MockERC20");

        usdt = await MockERC20.deploy('USDT', 'USDT', ethers.utils.parseEther('10000000000'));
        await usdt.deployed();

        wbtc = await MockERC20.deploy('WBTC', 'WBTC', ethers.utils.parseEther('10000000000'));
        await wbtc.deployed();

        const WETH9 = await ethers.getContractFactory("WETH9");
        weth = await WETH9.deploy();
        await weth.deployed();
    }
});