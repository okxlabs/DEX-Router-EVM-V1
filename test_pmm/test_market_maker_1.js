const { getPullInfosToBeSigned, getPullInfosToBeSigned_paidByCarol, getPushInfosToBeSigned, multipleQuotes, getDigest } = require("./pmm/quoter");
const { ethers } = require("hardhat");
const { BigNumber } = require('ethers')
const { expect } = require("chai");

describe("Market Marker test", function() {

    let wbtc, usdt, weth;
    let owner, alice, bob, carol, backEnd;
    const ETH = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
    const FOREVER = '2000000000';
    let layer1, layer2, layer3;

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

//  =========================  Single  Exchange Test  ============================

    it("DexRouter -> MarketMaker single exchange test: ERC20 Exchange ERC20", async () => {
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
            FOREVER             //2000000000
        ]
        // const RouterPath = [
        //     // address[] mixAdapters;
        //     // address[] assetTo;
        //     // uint256[] rawData;
        //     // bytes[] extraData;
        //     // address fromToken;
        //     // [pmmAdapter.address]
        // ]
        let res = await dexRouter.connect(alice).smartSwap(
            baseRequest,
            [swapAmount],
            [[]],
            [request]
        );
        // console.log("baseRequest", baseRequest);
        // console.log("swapAmount", swapAmount);
        // console.log("request", request);
        // console.log("calldata", res.data);

        // 8. check balance
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(infos.toTokenAmountMax);
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('50000'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2').sub(BigNumber.from(infos.toTokenAmountMax)));
    });

    // since the origin DexRouter use a constant of _WETH, here we have to use a temp version of DexRouter which we can config weth
    it("DexRouter -> MarketMaker single exchange test: Native token Exchange ERC20", async () => {
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
            FOREVER
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
    it("DexRouter -> MarketMaker single exchange test: ERC20 Exchange Native token ", async () => {
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
            FOREVER
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

//  =========================  Multiple  Exchange Test  ============================
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

    it("DexRouter -> MarketMaker multiple exchange test: Replace the whole swap ", async () => {
        const { chainId }  = await ethers.provider.getNetwork();

        // 1. prepare accounts and tokens
        await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
        await weth.transfer(bob.address, ethers.utils.parseEther('5'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
        await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
        await dot.transfer(bob.address, ethers.utils.parseEther('2000'));

        console.log("usdt",usdt.address);
        console.log("weth",weth.address);
        console.log("wbtc",wbtc.address);
        console.log("okb",okb.address);
        console.log("dot",dot.address);

        // 2. prepare dex and liquidity
        await initUniSwap();
        await addLiquidity();

        // 3. prepare marketMaker
        let marketMaker;
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        marketMaker = await MarketMaker.deploy();
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

        expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('40000'));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
        expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('5'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
        expect(await okb.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
        expect(await dot.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));

        // 5. prepare quotes
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": usdt.address, 
                "toTokenAddress": wbtc.address, 
                "fromTokenAmount": ethers.utils.parseEther('40000'), 
                "toTokenAmountMin": ethers.utils.parseEther('1'),
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
        let swapAmount = ethers.utils.parseEther('40000');
        await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x80' + '0000000000000000000000' + usdt.address.slice(2),
            wbtc.address,
            swapAmount,
            ethers.utils.parseEther('0'),
            FOREVER
        ]

        const layers = await initLayersWholeSwap();
        console.log("layers[0]", layers[0]);


        const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];
        console.log("batchesAmount", batchesAmount);

        // const RouterPath = [
        //     // address[] mixAdapters;
        //     // address[] assetTo;
        //     // uint256[] rawData;
        //     // bytes[] extraData;
        //     // uint256 fromToken;
        // ]

        await dexRouter.connect(alice).smartSwap(
            baseRequest,
            batchesAmount,
            layers,
            [request]
        );

        // 8. check balance
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from(infos.toTokenAmountMax));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('40000'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2').sub(BigNumber.from(infos.toTokenAmountMax)));
    });


//  =================================  internal functions  ===================================
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
        console.log("lpUSDTWETH", pair);

        pair = await factory.getPair(weth.address, wbtc.address);
        lpWETHWBTC = await UniswapPair.attach(pair);
        console.log("lpWETHWBTC", pair);


        pair = await factory.getPair(usdt.address, wbtc.address);
        lpUSDTWBTC = await UniswapPair.attach(pair);
        console.log("lpUSDTWBTC", pair);


        pair = await factory.getPair(usdt.address, okb.address);
        lpUSDTOKB = await UniswapPair.attach(pair);
        console.log("lpUSDTOKB", pair);


        pair = await factory.getPair(okb.address, dot.address);
        lpOKBDOT = await UniswapPair.attach(pair);
        console.log("lpOKBDOT", pair);

        pair = await factory.getPair(dot.address, wbtc.address);
        lpDOTWBTC = await UniswapPair.attach(pair);
        console.log("lpDOTWBTC", pair);

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
            [usdt, weth, ethers.utils.parseEther('1500000'), ethers.utils.parseEther('500')],
            [weth, wbtc, ethers.utils.parseEther('400'), ethers.utils.parseEther('30')],
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

    const initMockTokens = async function() {
        // alice has 50000 usdt, bob has 2 wbtc
        // alice want to buy 1 wbtc with her 50000 usdt, and bob is willing to provide pmm liquidity
        const MockERC20 = await ethers.getContractFactory("MockERC20");

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
            value: ethers.utils.parseEther('990')
        })
    };

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


});