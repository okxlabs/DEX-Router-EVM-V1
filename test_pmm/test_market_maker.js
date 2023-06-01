const { 
    getPullInfosToBeSigned, 
    multipleQuotes, 
    getDigest,
} = require("./pmm/quoter");
const { ethers, upgrades, network} = require("hardhat");
const hre = require("hardhat");

const { BigNumber } = require('ethers')
const { expect } = require("chai");
const ethDeployed = require("../scripts/deployed/eth");
const pmm_params = require("./pmm/pmm_params");

require ('../scripts/tools');



describe("PMM Test", function() {
    this.timeout(300000);

    let wbtc, usdt, weth, factory, marketMaker;
    let owner, alice, bob, carol, backEnd, canceler, cancelerGuardian, singer;
    let tokenApprove, dexRouter, wNativeRelayer, tokenApproveProxy, uniAdapter;

    let layer1, layer2, layer3;
    const FOREVER = '2000000000';
    const ETH = {"address": '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'};
    const _ORDER_FINALIZED = BigNumber.from("0x8000000000000000000000000000000000000000000000000000000000000000");
    before(async () => {

        [owner, alice, bob, ] = await ethers.getSigners();
        await setForkBlockNumber(16094434); 

        await initWeth();
        await initDexRouter();
        await initTokenApproveProxy();
        await initWNativeRelayer();
    });


    it("1.1 ERC20 Exchange By FixRate", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();
        // alice: taker, bob: maker
        // usdt => wbtc
        let fromToken = usdt;
        let toToken = wbtc;
        await fromToken.transfer(alice.address, ethers.utils.parseEther('50000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('2'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": '50000000000000000000000', 
                "toTokenAmountMin": '1000000000000000000',
                "chainId": chainId,
                "marketMaker": dexRouter.address,
                "pmmAdapter": dexRouter.address,
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
        let swapAmount = ethers.utils.parseEther('50000');
        await toToken.connect(bob).approve(tokenApprove.address,markerAmount);
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        let baseRequest = [
            swapAmount,
            0,
            FOREVER,
            false,
            false
        ]
        let takerFromAmount0 = await fromToken.balanceOf(alice.address);
        let makerFromAmount0 = await fromToken.balanceOf(bob.address);
        let takerToAmount0 = await toToken.balanceOf(alice.address);
        let makerToAmount0 = await toToken.balanceOf(bob.address);

        let tx = await dexRouter.connect(alice).PMMV2Swap(
            1,
            baseRequest,
            request
        );

        let receipt = await tx.wait(); 
        // console.log("gasUsed", receipt.gasUsed);       

        let takerFromAmount1 = await fromToken.balanceOf(alice.address);
        let makerFromAmount1 = await fromToken.balanceOf(bob.address);
        let takerToAmount1 = await toToken.balanceOf(alice.address);
        let makerToAmount1 = await toToken.balanceOf(bob.address);

        expect(takerFromAmount0.sub(takerFromAmount1).eq(swapAmount)).to.be.ok;
        expect(makerFromAmount1.sub(makerFromAmount0).eq(swapAmount)).to.be.ok;
        expect(takerToAmount1.sub(takerToAmount0).eq(infos.toTokenAmountMax)).to.be.ok;
        expect(makerToAmount0.sub(makerToAmount1).eq(infos.toTokenAmountMax)).to.be.ok;
        
    });

    it("1.2 ERC20 Exchange By FixRate, Price Protected By Passed Source", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();
        // alice: taker, bob: maker
        // usdt => wbtc
        let fromToken = usdt;
        let toToken = wbtc;
        await fromToken.transfer(alice.address, ethers.utils.parseEther('50000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('2'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        
        let rfq = [
            {
                "pathIndex": 100000000000001,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": '50000000000000000000000', 
                "toTokenAmountMin": '2000000000000000000',
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        let swapAmount = ethers.utils.parseEther('50000');
        await toToken.connect(bob).approve(tokenApprove.address,markerAmount);
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        let baseRequest = [
            swapAmount,
            0,
            FOREVER,
            false,
            false
        ]
        let takerFromAmount0 = await fromToken.balanceOf(alice.address);
        let makerFromAmount0 = await fromToken.balanceOf(bob.address);
        let takerToAmount0 = await toToken.balanceOf(alice.address);
        let makerToAmount0 = await toToken.balanceOf(bob.address);

        let tx = await dexRouter.connect(alice).PMMV2Swap(
            1,
            baseRequest,
            request
        );
        let receipt = await tx.wait();

        let takerFromAmount1 = await fromToken.balanceOf(alice.address);
        let makerFromAmount1 = await fromToken.balanceOf(bob.address);
        let takerToAmount1 = await toToken.balanceOf(alice.address);
        let makerToAmount1 = await toToken.balanceOf(bob.address);

        expect(takerFromAmount0.sub(takerFromAmount1).eq(swapAmount)).to.be.ok;
        expect(makerFromAmount1.sub(makerFromAmount0).eq(swapAmount)).to.be.ok;
        expect(takerToAmount1.sub(takerToAmount0).lt(infos.toTokenAmountMax)).to.be.ok;
        expect(makerToAmount0.sub(makerToAmount1).lt(infos.toTokenAmountMax)).to.be.ok;

    });

    xit("1.3 ERC20 Exchange By FixRate, Price Protected By Passed Default Source", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();
        // alice: taker, bob: maker
        // usdt => wbtc
        let fromToken = usdt;
        let toToken = wbtc;
        await fromToken.transfer(alice.address, ethers.utils.parseEther('50000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('2'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = "0x0000000000000000000000000000000000000000000000000000000000000000";
        
        let rfq = [
            {
                "pathIndex": 100000000000001,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": '50000000000000000000000', 
                "toTokenAmountMin": '2000000000000000000',
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        let swapAmount = ethers.utils.parseEther('50000');
        await toToken.connect(bob).approve(tokenApprove.address,markerAmount);
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        let baseRequest = [
            swapAmount,
            0,
            FOREVER,
            false,
            false
        ]
        let takerFromAmount0 = await fromToken.balanceOf(alice.address);
        let makerFromAmount0 = await fromToken.balanceOf(bob.address);
        let takerToAmount0 = await toToken.balanceOf(alice.address);
        let makerToAmount0 = await toToken.balanceOf(bob.address);

        let tx = await dexRouter.connect(alice).PMMV2Swap(
            1,
            baseRequest,
            request
        );
        let receipt = await tx.wait();

        let takerFromAmount1 = await fromToken.balanceOf(alice.address);
        let makerFromAmount1 = await fromToken.balanceOf(bob.address);
        let takerToAmount1 = await toToken.balanceOf(alice.address);
        let makerToAmount1 = await toToken.balanceOf(bob.address);

        expect(takerFromAmount0.sub(takerFromAmount1).eq(swapAmount)).to.be.ok;
        expect(makerFromAmount1.sub(makerFromAmount0).eq(swapAmount)).to.be.ok;
        expect(takerToAmount1.sub(takerToAmount0).lt(infos.toTokenAmountMax)).to.be.ok;
        expect(makerToAmount0.sub(makerToAmount1).lt(infos.toTokenAmountMax)).to.be.ok;
        // console.log("makerToAmount0.sub(makerToAmount1)", makerToAmount0.sub(makerToAmount1));
    });

    it("1.4 ERC20 Exchange By FixRate, Wrong Price Source Passed", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();
        // alice: taker, bob: maker
        // usdt => wbtc
        let fromToken = usdt;
        let toToken = wbtc;
        await fromToken.transfer(alice.address, ethers.utils.parseEther('50000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('4'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = await getSource(lpUSDTWETH, usdt.address, weth.address);   // wrong source
        // let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);

        
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": '50000000000000000000000', 
                "toTokenAmountMin": '2000000000000000000',
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        let swapAmount = ethers.utils.parseEther('50000');
        await toToken.connect(bob).approve(tokenApprove.address,ethers.utils.parseEther('100000000'));
        await fromToken.connect(alice).approve(tokenApprove.address, ethers.utils.parseEther('100000000'));

        let baseRequest = [
            swapAmount,
            0,
            FOREVER,
            false,
            false
        ]
        let takerFromAmount0 = await fromToken.balanceOf(alice.address);
        let makerFromAmount0 = await fromToken.balanceOf(bob.address);
        let takerToAmount0 = await toToken.balanceOf(alice.address);
        let makerToAmount0 = await toToken.balanceOf(bob.address);

        let tx = await dexRouter.connect(alice).PMMV2Swap(
            1,
            baseRequest,
            request
        );
        let receipt = await tx.wait();

        let takerFromAmount1 = await fromToken.balanceOf(alice.address);
        let makerFromAmount1 = await fromToken.balanceOf(bob.address);
        let takerToAmount1 = await toToken.balanceOf(alice.address);
        let makerToAmount1 = await toToken.balanceOf(bob.address);

        expect(takerFromAmount0.sub(takerFromAmount1).eq(swapAmount)).to.be.ok;
        expect(makerFromAmount1.sub(makerFromAmount0).eq(swapAmount)).to.be.ok;
        expect(takerToAmount1.sub(takerToAmount0).eq(infos.toTokenAmountMax)).to.be.ok;
        expect(makerToAmount0.sub(makerToAmount1).eq(infos.toTokenAmountMax)).to.be.ok;
    });

    it("1.5 ERC20 -> Native Exchange By FixRate", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();
        // alice: taker, bob: maker
        // usdt => eth
        let fromToken = usdt;
        let toToken = weth;
        await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('2'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = await getSource(lpUSDTWETH, fromToken.address, toToken.address);
        
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": ethers.utils.parseEther('3000'), 
                "toTokenAmountMin": ethers.utils.parseEther('1.1'),
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        let swapAmount = ethers.utils.parseEther('3000');
        await toToken.connect(bob).approve(tokenApprove.address,markerAmount);
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        let baseRequest = [
            swapAmount,
            ethers.utils.parseEther('1'),
            FOREVER,
            false,
            true
        ]
        let takerFromAmount0 = await fromToken.balanceOf(alice.address);
        let makerFromAmount0 = await fromToken.balanceOf(bob.address);
        let takerToAmount0 = await ethers.provider.getBalance(alice.address);
        let makerToAmount0 = await toToken.balanceOf(bob.address);

        let tx = await dexRouter.connect(alice).PMMV2Swap(
            1,
            baseRequest,
            request
        );
        let receipt = await tx.wait();
        // console.log("gas used", receipt.gasUsed);
        let gasCost = await getTransactionCost(tx);

        let takerFromAmount1 = await fromToken.balanceOf(alice.address);
        let makerFromAmount1 = await fromToken.balanceOf(bob.address);
        let takerToAmount1 = await ethers.provider.getBalance(alice.address);
        let makerToAmount1 = await toToken.balanceOf(bob.address);

        expect(takerFromAmount0.sub(takerFromAmount1).eq(swapAmount)).to.be.ok;
        expect(makerFromAmount1.sub(makerFromAmount0).eq(swapAmount)).to.be.ok;

        expect(takerToAmount1.sub(takerToAmount0.sub(gasCost)).lte(infos.toTokenAmountMax)).to.be.ok;
        expect(makerToAmount0.sub(makerToAmount1).lte(infos.toTokenAmountMax)).to.be.ok;
        
    });

    it("1.6 Native -> ERC20 Exchange By FixRate", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();
        // alice: taker, bob: maker
        // eth => usdt
        let fromToken = weth;
        let toToken = usdt;
        // await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('6000'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = await getSource(lpUSDTWETH, fromToken.address, toToken.address);
        
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": ethers.utils.parseEther('1'), 
                "toTokenAmountMin": ethers.utils.parseEther('3000'),
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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

        let markerAmount = ethers.utils.parseEther('6000');
        let swapAmount = ethers.utils.parseEther('1');
        await toToken.connect(bob).approve(tokenApprove.address,markerAmount);
        // await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        let baseRequest = [
            swapAmount,
            ethers.utils.parseEther('3000'),
            FOREVER,
            true,
            false
        ]
        let takerFromAmount0 = await ethers.provider.getBalance(alice.address);
        let makerFromAmount0 = await weth.balanceOf(bob.address);
        let takerToAmount0 = await toToken.balanceOf(alice.address);
        let makerToAmount0 = await toToken.balanceOf(bob.address);

        let tx = await dexRouter.connect(alice).PMMV2Swap(
            1,
            baseRequest,
            request,
            {value: ethers.utils.parseEther('1')}
        );
        let receipt = await tx.wait();
        // console.log("gas used", receipt.gasUsed);
        let gasCost = await getTransactionCost(tx);

        let takerFromAmount1 = await ethers.provider.getBalance(alice.address);
        let makerFromAmount1 = await weth.balanceOf(bob.address);
        let takerToAmount1 = await toToken.balanceOf(alice.address);
        let makerToAmount1 = await toToken.balanceOf(bob.address);
      
        expect(takerFromAmount0.sub(gasCost).sub(takerFromAmount1).eq(swapAmount)).to.be.ok;
        expect(makerFromAmount1.sub(makerFromAmount0).eq(swapAmount)).to.be.ok;

        expect(takerToAmount1.sub(takerToAmount0).lte(infos.toTokenAmountMax)).to.be.ok;
        expect(makerToAmount0.sub(makerToAmount1).lte(infos.toTokenAmountMax)).to.be.ok;
        
    });


    it("1.7 Cancel Quotes And Query Order Status", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();
        // alice: taker, bob: maker
        // usdt => wbtc
        let fromToken = usdt;
        let toToken = wbtc;
        await fromToken.transfer(alice.address, ethers.utils.parseEther('50000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('2'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        
        let rfq = [
            {
                "pathIndex": 1000000000000006,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": '50000000000000000000000', 
                "toTokenAmountMin": '1000000000000000000',
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        let swapAmount = ethers.utils.parseEther('50000');
        await toToken.connect(bob).approve(tokenApprove.address,markerAmount);
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        let baseRequest = [
            swapAmount,
            0,
            FOREVER,
            false
        ]
        // console.log("request", request);
        let tx = await dexRouter.connect(bob).cancelQuotes([request]);
        // console.log("cancel", tx);
        let orderHash = getDigest(request, chainId, dexRouter.address);
        // console.log("orderHash", orderHash);
        let remaining = await dexRouter.orderRemaining(orderHash);
        // console.log("remaining", remaining);

        expect(remaining.eq(_ORDER_FINALIZED)).to.be.ok;
    });

    it("1.8 Fill the same order more than twice", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();
        // alice: taker, bob: maker
        // usdt => wbtc
        let fromToken = usdt;
        let toToken = wbtc;
        await fromToken.transfer(alice.address, ethers.utils.parseEther('500000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('4'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        
        let rfq = [
            {
                "pathIndex": 1000000000000010,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": '100000000000000000000000', 
                "toTokenAmountMin": '2000000000000000000',
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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

        let markerAmount = ethers.utils.parseEther('4');
        let swapAmount0 = ethers.utils.parseEther('50000');
        await toToken.connect(bob).approve(tokenApprove.address,markerAmount);
        await fromToken.connect(alice).approve(tokenApprove.address, ethers.utils.parseEther('500000'));

        let baseRequest = [
            swapAmount0,
            0,
            FOREVER,
            false
        ]
        let takerFromAmount0 = await fromToken.balanceOf(alice.address);
        let makerFromAmount0 = await fromToken.balanceOf(bob.address);
        let takerToAmount0 = await toToken.balanceOf(alice.address);
        let makerToAmount0 = await toToken.balanceOf(bob.address);

        // first filling
        let tx = await dexRouter.connect(alice).PMMV2Swap(
            1,
            baseRequest,
            request
        );
        let receipt = await tx.wait();

        let takerFromAmount1 = await fromToken.balanceOf(alice.address);
        let makerFromAmount1 = await fromToken.balanceOf(bob.address);
        let takerToAmount1 = await toToken.balanceOf(alice.address);
        let makerToAmount1 = await toToken.balanceOf(bob.address);

        expect(takerFromAmount0.sub(takerFromAmount1).eq(swapAmount0)).to.be.ok;
        expect(makerFromAmount1.sub(makerFromAmount0).eq(swapAmount0)).to.be.ok;
        expect(takerToAmount1.sub(takerToAmount0).eq(
            BigNumber.from(swapAmount0)
            .mul(BigNumber.from(infos.toTokenAmountMax))
            .div(BigNumber.from(infos.fromTokenAmountMax))
        )).to.be.ok;
        expect(makerToAmount0.sub(makerToAmount1).eq(
            BigNumber.from(swapAmount0)
            .mul(BigNumber.from(infos.toTokenAmountMax))
            .div(BigNumber.from(infos.fromTokenAmountMax))       
        )).to.be.ok;

        let swapAmount1 = ethers.utils.parseEther('40000');
        baseRequest = [
            swapAmount1,
            0,
            FOREVER,
            false
        ]
        // second filling
        await dexRouter.connect(alice).PMMV2Swap(
            1,
            baseRequest,
            request
        );

        let takerFromAmount2 = await fromToken.balanceOf(alice.address);
        let makerFromAmount2 = await fromToken.balanceOf(bob.address);
        let takerToAmount2 = await toToken.balanceOf(alice.address);
        let makerToAmount2 = await toToken.balanceOf(bob.address);

        expect(takerFromAmount1.sub(takerFromAmount2).eq(swapAmount1)).to.be.ok;
        expect(makerFromAmount2.sub(makerFromAmount1).eq(swapAmount1)).to.be.ok;
        expect(takerToAmount2.sub(takerToAmount1).eq(
            BigNumber.from(swapAmount1)
            .mul(BigNumber.from(infos.toTokenAmountMax))
            .div(BigNumber.from(infos.fromTokenAmountMax))
        )).to.be.ok;
        expect(makerToAmount1.sub(makerToAmount2).eq(
            BigNumber.from(swapAmount1)
            .mul(BigNumber.from(infos.toTokenAmountMax))
            .div(BigNumber.from(infos.fromTokenAmountMax))       
        )).to.be.ok;

        // third filling
        // await dexRouter.connect(alice).PMMV2Swap(
        //     baseRequest,
        //     request
        // );
        
    });

    xit("2.1 ERC20 Exchange By FixRate by smart swap", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();
        // alice: taker, bob: maker
        // usdt => wbtc
        let fromToken = usdt;
        let toToken = wbtc;
        await fromToken.transfer(alice.address, ethers.utils.parseEther('50000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('2'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": '50000000000000000000000', 
                "toTokenAmountMin": '1000000000000000000',
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        let swapAmount = ethers.utils.parseEther('50000');
        await toToken.connect(bob).approve(tokenApprove.address,markerAmount);
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        let baseRequest = [
            '0x80' + '0000000000000000000000' + fromToken.address.toString().slice(2),
            toToken.address,
            swapAmount,
            0,
            FOREVER
        ]

        let takerFromAmount0 = await fromToken.balanceOf(alice.address);
        let makerFromAmount0 = await fromToken.balanceOf(bob.address);
        let takerToAmount0 = await toToken.balanceOf(alice.address);
        let makerToAmount0 = await toToken.balanceOf(bob.address);
        let tx = await dexRouter.connect(alice).smartSwapByOrderId(
            1,
            baseRequest,
            [swapAmount],
            [[]],
            [request]
        );

        // console.log("tx",tx);
        let receipt = await tx.wait();
        // console.log("receipt", receipt);
        let takerFromAmount1 = await fromToken.balanceOf(alice.address);
        let makerFromAmount1 = await fromToken.balanceOf(bob.address);
        let takerToAmount1 = await toToken.balanceOf(alice.address);
        let makerToAmount1 = await toToken.balanceOf(bob.address);

        expect(takerFromAmount0.sub(takerFromAmount1).eq(swapAmount)).to.be.ok;
        expect(makerFromAmount1.sub(makerFromAmount0).eq(swapAmount)).to.be.ok;
        expect(takerToAmount1.sub(takerToAmount0).eq(infos.toTokenAmountMax)).to.be.ok;
        expect(makerToAmount0.sub(makerToAmount1).eq(infos.toTokenAmountMax)).to.be.ok;


        
    });


    xit("2.2 ERC20 -> Native Exchange By smart swap", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();
        // alice: taker, bob: maker
        // usdt => eth
        let fromToken = usdt;
        let toToken = weth;
        await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('2'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = await getSource(lpUSDTWETH, fromToken.address, toToken.address);
        
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": ethers.utils.parseEther('3000'), 
                "toTokenAmountMin": ethers.utils.parseEther('1.1'),
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        let swapAmount = ethers.utils.parseEther('3000');
        await toToken.connect(bob).approve(tokenApprove.address,markerAmount);
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        let baseRequest = [
            '0x80' + '0000000000000000000000' + fromToken.address.toString().slice(2),
            ETH.address,
            swapAmount,
            0,
            FOREVER
        ]

        let takerFromAmount0 = await fromToken.balanceOf(alice.address);
        let makerFromAmount0 = await fromToken.balanceOf(bob.address);
        let takerToAmount0 = await ethers.provider.getBalance(alice.address);
        let makerToAmount0 = await toToken.balanceOf(bob.address);

        let tx = await dexRouter.connect(alice).smartSwapByOrderId(
            1,
            baseRequest,
            [swapAmount],
            [[]],
            [request]
        );

        let gasCost = await getTransactionCost(tx);

        let takerFromAmount1 = await fromToken.balanceOf(alice.address);
        let makerFromAmount1 = await fromToken.balanceOf(bob.address);
        let takerToAmount1 = await ethers.provider.getBalance(alice.address);
        let makerToAmount1 = await toToken.balanceOf(bob.address);

        expect(takerFromAmount0.sub(takerFromAmount1).eq(swapAmount)).to.be.ok;
        expect(makerFromAmount1.sub(makerFromAmount0).eq(swapAmount)).to.be.ok;

        expect(takerToAmount1.sub(takerToAmount0.sub(gasCost)).lte(infos.toTokenAmountMax)).to.be.ok;
        expect(makerToAmount0.sub(makerToAmount1).lte(infos.toTokenAmountMax)).to.be.ok;
        
    });

    xit("2.3 Native -> ERC20 Exchange By smart swap", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();
        // alice: taker, bob: maker
        // eth => usdt
        let fromToken = weth;
        let toToken = usdt;
        // await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('6000'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = await getSource(lpUSDTWETH, fromToken.address, toToken.address);
        
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": ethers.utils.parseEther('1'), 
                "toTokenAmountMin": ethers.utils.parseEther('3000'),
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        let markerAmount = ethers.utils.parseEther('6000');
        let swapAmount = ethers.utils.parseEther('1');
        await toToken.connect(bob).approve(tokenApprove.address,markerAmount);
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        let baseRequest = [
            '0x80' + '0000000000000000000000' + ETH.address.slice(2),
            toToken.address,
            swapAmount,
            0,
            FOREVER
        ]

        let takerFromAmount0 = await ethers.provider.getBalance(alice.address);
        let makerFromAmount0 = await weth.balanceOf(bob.address);
        let takerToAmount0 = await toToken.balanceOf(alice.address);
        let makerToAmount0 = await toToken.balanceOf(bob.address);

        let tx = await dexRouter.connect(alice).smartSwapByOrderId(
            0,
            baseRequest,
            [swapAmount],
            [[]],
            [request],
            {value: ethers.utils.parseEther('1')}
        );

        let gasCost = await getTransactionCost(tx);

        let takerFromAmount1 = await ethers.provider.getBalance(alice.address);
        let makerFromAmount1 = await weth.balanceOf(bob.address);
        let takerToAmount1 = await toToken.balanceOf(alice.address);
        let makerToAmount1 = await toToken.balanceOf(bob.address);
      
        expect(takerFromAmount0.sub(gasCost).sub(takerFromAmount1).eq(swapAmount)).to.be.ok;
        expect(makerFromAmount1.sub(makerFromAmount0).eq(swapAmount)).to.be.ok;

        expect(takerToAmount1.sub(takerToAmount0).lte(infos.toTokenAmountMax)).to.be.ok;
        expect(makerToAmount0.sub(makerToAmount1).lte(infos.toTokenAmountMax)).to.be.ok;
        
    });

    it("2.4 Try to replace the whole swap with pmm but failed, turned to dex", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();

        let fromToken = usdt;
        let toToken = wbtc;
        // await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));

        await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
        await weth.transfer(bob.address, ethers.utils.parseEther('5'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
        await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
        await dot.transfer(bob.address, ethers.utils.parseEther('2000'));
        const { chainId }  = await ethers.provider.getNetwork();


        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": usdt.address,
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": ethers.utils.parseEther('40000'), 
                "toTokenAmountMin": ethers.utils.parseEther('1'),
                "chainId": chainId,
                "marketMaker": dexRouter.address,
                "source": source
            }
        ]
        let infosToBeSigned = getPullInfosToBeSigned(rfq);
        let quote = multipleQuotes(infosToBeSigned);

        let infos = quote[0];
        let request = [
            infos.pathIndex + 1,        // invalid pathIndex
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
        await toToken.connect(bob).approve(tokenApprove.address, markerAmount);
        let swapAmount = ethers.utils.parseEther('40000');
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x80' + '0000000000000000000000' + fromToken.address.slice(2),
            toToken.address,
            swapAmount,
            ethers.utils.parseEther('1'),
            FOREVER
        ]

        let layers = await initLayersWholeSwap();
        const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];
        
        await dexRouter.connect(alice).smartSwapByOrderId(
            0,
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

    xit("2.5 Try to replace the whole swap with pmm and success", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();

        let fromToken = usdt;
        let toToken = wbtc;
        // await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));

        await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
        await weth.transfer(bob.address, ethers.utils.parseEther('5'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
        await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
        await dot.transfer(bob.address, ethers.utils.parseEther('2000'));
        const { chainId }  = await ethers.provider.getNetwork();


        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": ethers.utils.parseEther('40000'), 
                "toTokenAmountMin": ethers.utils.parseEther('1'),
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        await toToken.connect(bob).approve(tokenApprove.address, markerAmount);
        let swapAmount = ethers.utils.parseEther('40000');
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x80' + '0000000000000000000000' + fromToken.address.slice(2),
            toToken.address,
            swapAmount,
            ethers.utils.parseEther('1'),
            FOREVER
        ]

        let layers = await initLayersWholeSwap();
        const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];
        
        await dexRouter.connect(alice).smartSwapByOrderId(
            0,
            baseRequest,
            batchesAmount,
            layers,
            pmmRequests
        );
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        // price protected by protection solution
        expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1000000000000000000'));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('40000'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(BigNumber.from('1000000000000000000'));
        
    });

    xit("2.6 Try to replace the first batch with pmm but failed, turned to dex", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();

        let fromToken = usdt;
        let toToken = wbtc;
        // await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));

        await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
        await weth.transfer(bob.address, ethers.utils.parseEther('5'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
        await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
        await dot.transfer(bob.address, ethers.utils.parseEther('2000'));
        const { chainId }  = await ethers.provider.getNetwork();


        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": usdt.address, 
                "toTokenAddress": wbtc.address, 
                "fromTokenAmount": ethers.utils.parseEther('12000'), 
                "toTokenAmountMin": ethers.utils.parseEther('0.3'),
                "chainId": chainId,
                "marketMaker": dexRouter.address,
                "source": source
            }
        ]
        let infosToBeSigned = getPullInfosToBeSigned(rfq);
        let quote = multipleQuotes(infosToBeSigned);

        let infos = quote[0];
        let request = [
            infos.pathIndex + 1,    // force it fall back to dex
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
        await toToken.connect(bob).approve(tokenApprove.address, markerAmount);
        let swapAmount = ethers.utils.parseEther('40000');
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x00' + '0000000000000000000000' + fromToken.address.slice(2),
            toToken.address,
            swapAmount,
            ethers.utils.parseEther('1'),
            FOREVER
        ]

        const layers = await initLayersReplaceFirstBatch();
        const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];

        await dexRouter.connect(alice).smartSwapByOrderId(
            0,
            baseRequest,
            batchesAmount,
            layers,
            pmmRequests
        );
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1111597868718424651'));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(BigNumber.from('2000000000000000000'));
        
    });

    xit("2.7 Try to replace the first batch with pmm and success", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();

        let fromToken = usdt;
        let toToken = wbtc;
        // await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));

        await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
        await weth.transfer(bob.address, ethers.utils.parseEther('5'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
        await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
        await dot.transfer(bob.address, ethers.utils.parseEther('2000'));
        const { chainId }  = await ethers.provider.getNetwork();


        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": usdt.address, 
                "toTokenAddress": wbtc.address, 
                "fromTokenAmount": ethers.utils.parseEther('12000'), 
                "toTokenAmountMin": ethers.utils.parseEther('0.3'),
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        await toToken.connect(bob).approve(tokenApprove.address, markerAmount);
        let swapAmount = ethers.utils.parseEther('40000');
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x00' + '0000000000000000000000' + fromToken.address.slice(2),
            toToken.address,
            swapAmount,
            ethers.utils.parseEther('1'),
            FOREVER
        ]

        const layers = await initLayersReplaceFirstBatch();
        const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];

        await dexRouter.connect(alice).smartSwapByOrderId(
            0,
            baseRequest,
            batchesAmount,
            layers,
            pmmRequests
        );
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1158703882834055521'));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('12000'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(BigNumber.from('1700000000000000000'));
        
    });

    xit("2.8 Try to replace the two hops of the first batch separately with pmm and success", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();

        let fromToken = usdt;
        let toToken = wbtc;
        // await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));

        await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
        await weth.transfer(bob.address, ethers.utils.parseEther('5'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
        await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
        await dot.transfer(bob.address, ethers.utils.parseEther('2000'));

        const { chainId }  = await ethers.provider.getNetwork();


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
                    "marketMaker": dexRouter.address,
                    "source": source1
                },
                {
                    "pathIndex": 200000000000000,
                    "fromTokenAddress": weth.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": ethers.utils.parseEther('5'), 
                    "toTokenAmountMin": ethers.utils.parseEther('0.375'),
                    "chainId": chainId,
                    "marketMaker": dexRouter.address,
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
            '0x00' + '0000000000000000000000' + fromToken.address.slice(2),
            toToken.address,
            swapAmount,
            ethers.utils.parseEther('0.8'),
            FOREVER
        ]

        const layers = await initLayersReplaceHops();
        const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];

        expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('40000'));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
        expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('29'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
        expect(await okb.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
        expect(await dot.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));

        let tx = await dexRouter.connect(alice).smartSwapByOrderId(
            0,
            baseRequest,
            batchesAmount,
            layers,
            pmmRequests
        );
        let rec = await tx.wait();

        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1158703882834055521'));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('12000'));
        expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('29'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(BigNumber.from('1700000000000000000'));
        
    });

    xit("2.9 Try to replace the two hops of the first batch separately with pmm and success", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();

        let fromToken = usdt;
        let toToken = wbtc;
        // await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));

        await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
        await weth.transfer(bob.address, ethers.utils.parseEther('5'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
        await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
        await dot.transfer(bob.address, ethers.utils.parseEther('2000'));

        const { chainId }  = await ethers.provider.getNetwork();


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
                    "marketMaker": dexRouter.address,
                    "source": source1
                },
                {
                    "pathIndex": 200000000000000,
                    "fromTokenAddress": weth.address, 
                    "toTokenAddress": wbtc.address, 
                    "fromTokenAmount": ethers.utils.parseEther('5'), 
                    "toTokenAmountMin": ethers.utils.parseEther('0.375'),
                    "chainId": chainId,
                    "marketMaker": dexRouter.address,
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
            quote[1].fromTokenAmountMax + 1, 
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
            '0x00' + '0000000000000000000000' + fromToken.address.slice(2),
            toToken.address,
            swapAmount,
            ethers.utils.parseEther('0.8'),
            FOREVER
        ]

        const layers = await initLayersReplaceHops();
        const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];

        expect(await usdt.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('40000'));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
        expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('34'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
        expect(await okb.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));
        expect(await dot.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2000'));

        let tx = await dexRouter.connect(alice).smartSwapByOrderId(
            1,
            baseRequest,
            batchesAmount,
            layers,
            pmmRequests
        );
        let rec = await tx.wait();

        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1130687150998100260'));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('12000'));
        expect(await weth.balanceOf(bob.address)).to.equal(BigNumber.from('30000000000000000000'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('2'));
        
    });

    xit("2.10 ERC20 Exchange By Invest whole replaced by pmm", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();
        // alice: taker, bob: maker
        // usdt => wbtc
        let fromToken = usdt;
        let toToken = wbtc;
        await fromToken.transfer(alice.address, ethers.utils.parseEther('50000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('2'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": '50000000000000000000000', 
                "toTokenAmountMin": '1000000000000000000',
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        let swapAmount = ethers.utils.parseEther('50000');
        await toToken.connect(bob).approve(tokenApprove.address,markerAmount);
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        let baseRequest = [
            '0x80' + '0000000000000000000000' + fromToken.address.toString().slice(2),
            toToken.address,
            swapAmount,
            0,
            FOREVER
        ]

        let takerFromAmount0 = await fromToken.balanceOf(alice.address);
        let makerFromAmount0 = await fromToken.balanceOf(bob.address);
        let takerToAmount0 = await toToken.balanceOf(alice.address);
        let makerToAmount0 = await toToken.balanceOf(bob.address);

        await fromToken.connect(alice).transfer(dexRouter.address, swapAmount);
        let tx = await dexRouter.connect(alice).smartSwapByInvest(
            baseRequest,
            [swapAmount],
            [[]],
            [request],
            alice.address
        );

        // console.log("tx",tx);
        let receipt = await tx.wait();
        console.log("gasUsed", receipt.gasUsed);
        let takerFromAmount1 = await fromToken.balanceOf(alice.address);
        let makerFromAmount1 = await fromToken.balanceOf(bob.address);
        let takerToAmount1 = await toToken.balanceOf(alice.address);
        let makerToAmount1 = await toToken.balanceOf(bob.address);

        expect(takerFromAmount0.sub(takerFromAmount1).eq(swapAmount)).to.be.ok;
        expect(makerFromAmount1.sub(makerFromAmount0).eq(swapAmount)).to.be.ok;
        expect(takerToAmount1.sub(takerToAmount0).eq(infos.toTokenAmountMax)).to.be.ok;
        expect(makerToAmount0.sub(makerToAmount1).eq(infos.toTokenAmountMax)).to.be.ok;


        
    });

    it("2.11 In case of quote expired", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();

        let fromToken = usdt;
        let toToken = wbtc;
        // await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));

        await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
        await weth.transfer(bob.address, ethers.utils.parseEther('5'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
        await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
        await dot.transfer(bob.address, ethers.utils.parseEther('2000'));
        const { chainId }  = await ethers.provider.getNetwork();


        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": usdt.address, 
                "toTokenAddress": wbtc.address, 
                "fromTokenAmount": ethers.utils.parseEther('12000'), 
                "toTokenAmountMin": ethers.utils.parseEther('0.3'),
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
            100, // expired
            infos.isPushOrder, 
            infos.extension
        ];
        const pmmRequests = [request];

        let markerAmount = ethers.utils.parseEther('2');
        await toToken.connect(bob).approve(tokenApprove.address, markerAmount);
        let swapAmount = ethers.utils.parseEther('40000');
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x00' + '0000000000000000000000' + fromToken.address.slice(2),
            toToken.address,
            swapAmount,
            ethers.utils.parseEther('1'),
            FOREVER
        ]

        const layers = await initLayersReplaceFirstBatch();
        const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];

        await dexRouter.connect(alice).smartSwapByOrderId(
            0,
            baseRequest,
            batchesAmount,
            layers,
            pmmRequests
        );
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1111597868718424651'));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(BigNumber.from('2000000000000000000'));
        
    });

    it("2.12 In case of order cancelled", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();

        let fromToken = usdt;
        let toToken = wbtc;
        // await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));

        await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
        await weth.transfer(bob.address, ethers.utils.parseEther('5'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
        await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
        await dot.transfer(bob.address, ethers.utils.parseEther('2000'));
        const { chainId }  = await ethers.provider.getNetwork();


        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        let rfq = [
            {
                "pathIndex": 10000000000000012,
                "fromTokenAddress": usdt.address, 
                "toTokenAddress": wbtc.address, 
                "fromTokenAmount": ethers.utils.parseEther('12000'), 
                "toTokenAmountMin": ethers.utils.parseEther('0.3'),
                "chainId": chainId,
                "marketMaker": dexRouter.address,
                "source": source
            }
        ]
        let infosToBeSigned = getPullInfosToBeSigned(rfq);
        infosToBeSigned.deadLine -= 6000001;
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
        await toToken.connect(bob).approve(tokenApprove.address, markerAmount);
        let swapAmount = ethers.utils.parseEther('40000');
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x00' + '0000000000000000000000' + fromToken.address.slice(2),
            toToken.address,
            swapAmount,
            ethers.utils.parseEther('1'),
            FOREVER
        ]

        const layers = await initLayersReplaceFirstBatch();
        const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];
        
        // order cancelled, fall back to dex
        await dexRouter.connect(bob).cancelQuotes(pmmRequests);

        await dexRouter.connect(alice).smartSwapByOrderId(
            0,
            baseRequest,
            batchesAmount,
            layers,
            pmmRequests
        );
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1111597868718424651'));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(BigNumber.from('2000000000000000000'));
        
    });

    it("2.13 In case of order remaining is not enough", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();

        let fromToken = usdt;
        let toToken = wbtc;
        // await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));

        await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
        await weth.transfer(bob.address, ethers.utils.parseEther('5'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
        await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
        await dot.transfer(bob.address, ethers.utils.parseEther('2000'));
        const { chainId }  = await ethers.provider.getNetwork();


        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        let rfq = [
            {
                "pathIndex": 10000000000000013,
                "fromTokenAddress": usdt.address, 
                "toTokenAddress": wbtc.address, 
                "fromTokenAmount": ethers.utils.parseEther('1200'), 
                "toTokenAmountMin": ethers.utils.parseEther('0.03'),
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        await toToken.connect(bob).approve(tokenApprove.address, markerAmount);
        let swapAmount = ethers.utils.parseEther('40000');
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x00' + '0000000000000000000000' + fromToken.address.slice(2),
            toToken.address,
            swapAmount,
            ethers.utils.parseEther('1'),
            FOREVER
        ]

        const layers = await initLayersReplaceFirstBatch();
        const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];
        
        await dexRouter.connect(alice).smartSwapByOrderId(
            0,
            baseRequest,
            batchesAmount,
            layers,
            pmmRequests
        );
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1111597868718424651'));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(BigNumber.from('2000000000000000000'));
        
    });

    xit("2.14 In case of incorrect price source", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();

        let fromToken = usdt;
        let toToken = wbtc;
        // await fromToken.transfer(alice.address, ethers.utils.parseEther('3000'));

        await usdt.transfer(alice.address, ethers.utils.parseEther('40000'));
        await weth.transfer(bob.address, ethers.utils.parseEther('5'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
        await okb.transfer(bob.address, ethers.utils.parseEther('2000'));
        await dot.transfer(bob.address, ethers.utils.parseEther('2000'));
        const { chainId }  = await ethers.provider.getNetwork();


        let source = await getSource(emptyPool, usdt.address, dot.address);
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": usdt.address, 
                "toTokenAddress": wbtc.address, 
                "fromTokenAmount": ethers.utils.parseEther('12000'), 
                "toTokenAmountMin": ethers.utils.parseEther('0.3'),
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        await toToken.connect(bob).approve(tokenApprove.address, markerAmount);
        let swapAmount = ethers.utils.parseEther('40000');
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x00' + '0000000000000000000000' + fromToken.address.slice(2),
            toToken.address,
            swapAmount,
            ethers.utils.parseEther('1'),
            FOREVER
        ]

        const layers = await initLayersReplaceFirstBatch();
        const batchesAmount = [ethers.utils.parseEther('12000'), ethers.utils.parseEther('8000'), ethers.utils.parseEther('20000')];
        let bal = await wbtc.balanceOf(bob.address);
        await dexRouter.connect(alice).smartSwapByOrderId(
            0,
            baseRequest,
            batchesAmount,
            layers,
            pmmRequests
        );
        bal = await wbtc.balanceOf(bob.address);
        expect(await usdt.balanceOf(alice.address)).to.equal(0);
        expect(await wbtc.balanceOf(alice.address)).to.equal(BigNumber.from('1161703882834055521'));
        expect(await usdt.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('12000'));
        expect(await wbtc.balanceOf(bob.address)).to.equal(BigNumber.from('1697000000000000000'));
    });
    
    xit("3.1 PMM swap with fee", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();

        let feeConfig = "0x0bb8" + "00000000000000000000" + owner.address.slice(2);
        await dexRouter.setPMMFeeConfig(feeConfig);

        await dexRouter.connect(bob).setOperator(bob.address);
        // alice: taker, bob: maker
        // usdt => wbtc
        let fromToken = usdt;
        let toToken = wbtc;
        await fromToken.transfer(alice.address, ethers.utils.parseEther('50000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('2'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": '50000000000000000000000', 
                "toTokenAmountMin": '1000000000000000000',
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        let swapAmount = ethers.utils.parseEther('50000');
        await toToken.connect(bob).approve(tokenApprove.address,markerAmount);
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        let baseRequest = [
            swapAmount,
            0,
            FOREVER,
            false,
            false
        ]
        let takerFromAmount0 = await fromToken.balanceOf(alice.address);
        let makerFromAmount0 = await fromToken.balanceOf(bob.address);
        let takerToAmount0 = await toToken.balanceOf(alice.address);
        let makerToAmount0 = await toToken.balanceOf(bob.address);
        let tx = await dexRouter.connect(alice).PMMV2Swap(
            1,
            baseRequest,
            request
        );
        // console.log("tx",tx);
        let receipt = await tx.wait();

        let takerFromAmount1 = await fromToken.balanceOf(alice.address);
        let makerFromAmount1 = await fromToken.balanceOf(bob.address);
        let takerToAmount1 = await toToken.balanceOf(alice.address);
        let makerToAmount1 = await toToken.balanceOf(bob.address);

        expect(takerFromAmount0.sub(takerFromAmount1).eq(swapAmount)).to.be.ok;
        expect(makerFromAmount1.sub(makerFromAmount0).eq(swapAmount)).to.be.ok;
        expect(takerToAmount1.sub(takerToAmount0).eq(BigNumber.from(infos.toTokenAmountMax).mul(BigNumber.from('997')).div(BigNumber.from("1000")))).to.be.ok;
        expect(makerToAmount0.sub(makerToAmount1).eq(infos.toTokenAmountMax)).to.be.ok;

        feeConfig = "0x000000000000000000000000" + owner.address.slice(2);
        await dexRouter.setPMMFeeConfig(feeConfig);

    });

    it("3.2 PMMV2SwapByInvest", async () => {
        await initMockTokens();
        await initUniSwap();
        await addLiquidity();
        // alice: taker, bob: maker
        // usdt => wbtc
        let fromToken = usdt;
        let toToken = wbtc;
        await fromToken.transfer(alice.address, ethers.utils.parseEther('50000'));
        await toToken.transfer(bob.address, ethers.utils.parseEther('2'));

        const { chainId }  = await ethers.provider.getNetwork();

        let source = await getSource(lpUSDTWBTC, usdt.address, wbtc.address);
        
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": '50000000000000000000000', 
                "toTokenAmountMin": '1000000000000000000',
                "chainId": chainId,
                "marketMaker": dexRouter.address,
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
        let swapAmount = ethers.utils.parseEther('50000');
        await toToken.connect(bob).approve(tokenApprove.address,markerAmount);
        await fromToken.connect(alice).approve(tokenApprove.address, swapAmount);

        let baseRequest = [
            swapAmount,
            0,
            FOREVER,
            false,
            false
        ]

        let takerFromAmount0 = await fromToken.balanceOf(alice.address);
        let makerFromAmount0 = await fromToken.balanceOf(bob.address);
        let takerToAmount0 = await toToken.balanceOf(alice.address);
        let makerToAmount0 = await toToken.balanceOf(bob.address);

        await fromToken.connect(alice).transfer(dexRouter.address, swapAmount);
        let tx = await dexRouter.connect(alice).PMMV2SwapByInvest(
            alice.address,
            baseRequest,
            request
        );

        // console.log("tx",tx);
        let receipt = await tx.wait();
        console.log("gasUsed", receipt.gasUsed);
        let takerFromAmount1 = await fromToken.balanceOf(alice.address);
        let makerFromAmount1 = await fromToken.balanceOf(bob.address);
        let takerToAmount1 = await toToken.balanceOf(alice.address);
        let makerToAmount1 = await toToken.balanceOf(bob.address);

        expect(takerFromAmount0.sub(takerFromAmount1).eq(swapAmount)).to.be.ok;
        expect(makerFromAmount1.sub(makerFromAmount0).eq(swapAmount)).to.be.ok;
        expect(takerToAmount1.sub(takerToAmount0).eq(infos.toTokenAmountMax)).to.be.ok;
        expect(makerToAmount0.sub(makerToAmount1).eq(infos.toTokenAmountMax)).to.be.ok;


        
    });

    it("3.3 PMMV2SwapByXBridge", async () => {
        expect(await dexRouter._WETH()).to.be.equal(weth.address);
        // ETH -> WBTC    
        fromToken = ETH;
        toToken = wbtc;
        const fromTokenAmount = ethers.utils.parseEther('10');
        const minReturnAmount = ethers.utils.parseEther('0');
        const deadLine = FOREVER;    
        const { chainId }  = await ethers.provider.getNetwork();

        let baseRequest = [
            fromTokenAmount,
            0,
            FOREVER,
            true,
            false
        ]
        let source = await getSource(lpWETHWBTC, weth.address, wbtc.address);
        
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": fromToken.address, 
                "toTokenAddress": toToken.address, 
                "fromTokenAmount": ethers.utils.parseEther('10'), 
                "toTokenAmountMin": ethers.utils.parseEther('0.1'),
                "chainId": chainId,
                "marketMaker": dexRouter.address,
                "source": source
            }
        ]
        let infosToBeSigned = getPullInfosToBeSigned(rfq);
        let quote = multipleQuotes(infosToBeSigned);

        let infos = quote[0];
        let pmmRequest = [
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

        let encodeABI = dexRouter.interface.encodeFunctionData('PMMV2SwapByXBridge', [0, baseRequest, pmmRequest]);
        // console.log("encodeABI", encodeABI);
        let xBridge = await initMockXBridge();
        const beforeToTokenBalance = await toToken.balanceOf(xBridge.address);
        expect(await wbtc.balanceOf(xBridge.address)).to.be.equal(0);
        let request = {
          adaptorId : 2,
          fromToken : fromToken.address,
          toToken : toToken.address,
          to : alice.address,
          toChainId : 56,
          fromTokenAmount : fromTokenAmount,
          toTokenMinAmount : 0,
          toChainToTokenMinAmount : 0,
          data : ethers.utils.defaultAbiCoder.encode(["address", "uint64", "uint32"], [usdt.address, 0, 501]),
          dexData : encodeABI,
          extData: "0x"
        };
        await xBridge.connect(alice).swapBridgeToV2(request, {value: fromTokenAmount});
    
        expect(await toToken.balanceOf(xBridge.address)).to.be.eq(infos.toTokenAmountMax);
    });
  
    const initWeth = async () => {
        weth = await ethers.getContractAt(
        "WETH9",
        ethDeployed.tokens.weth
        );

        setBalance(owner.address, ethers.utils.parseEther('1100000'));

        await weth.connect(owner).deposit({ value: ethers.utils.parseEther('1000000') });
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

        let accountAddress = await tokenApproveProxy.owner();
        startMockAccount([accountAddress]);
        tokenApproveProxyOwner = await ethers.getSigner(accountAddress);
        setBalance(tokenApproveProxyOwner.address, '0x56bc75e2d63100000');

        await tokenApproveProxy.connect(tokenApproveProxyOwner).addProxy(dexRouter.address);
        await tokenApproveProxy.connect(tokenApproveProxyOwner).setTokenApprove(tokenApprove.address);

        await dexRouter.setApproveProxy(tokenApproveProxy.address);


    }

    const initDexRouter = async () => {
        let _feeRateAndReceiver = "0x000000000000000000000000" + pmm_params.feeTo.slice(2);
        DexRouter = await ethers.getContractFactory("DexRouter");
        dexRouter = await upgrades.deployProxy(DexRouter)
        await dexRouter.deployed();
        await dexRouter.initializePMMRouter(_feeRateAndReceiver);

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
        await wNativeRelayer.connect(wNativeRelayerOwner).setCallerOk([dexRouter.address], [true, true]);
        expect(await dexRouter._WNATIVE_RELAY()).to.be.equal(wNativeRelayer.address);
        await dexRouter.setWNativeRelayer(wNativeRelayer.address);
    } 

    const initMockXBridge = async () => {
        const XBridgeMock = await ethers.getContractFactory("MockXBridge");
        let xBridge = await upgrades.deployProxy(XBridgeMock);
        await xBridge.deployed();
        await xBridge.setDexRouter(dexRouter.address);
        await dexRouter.setPriorityAddress(xBridge.address, true);
        await xBridge.connect(owner).setMpc([alice.address], [true]);
        await xBridge.setApproveProxy(tokenApproveProxy.address);
        return xBridge;
      }



    const getTransactionCost = async (txResult) => {
        const cumulativeGasUsed = (await txResult.wait()).cumulativeGasUsed;
        return ethers.BigNumber.from(txResult.gasPrice).mul(ethers.BigNumber.from(cumulativeGasUsed));
    };
    const getSource = async (pair, fromToken, toToken) => {
        let isReverse = "0x0000";
        let token0 = await pair.token0();
        let token1 = await pair.token1();

        if (toToken == token0 && fromToken == token1) {
            isReverse = "0x0001";
        }
        let source = isReverse + "00000000000000000000" + pair.address.slice(2);
        return source;
    }

    const initMockTokens = async () => {
        const MockERC20 = await ethers.getContractFactory("MockERC20");

        usdc = await MockERC20.deploy('USDC', 'USDC', ethers.utils.parseEther('10000000000'));
        await usdc.deployed();

        usdt = await MockERC20.deploy('USDT', 'USDT', ethers.utils.parseEther('10000000000'));
        await usdt.deployed();

        wbtc = await MockERC20.deploy('WBTC', 'WBTC', ethers.utils.parseEther('10000000000'));
        await wbtc.deployed();

        okb = await MockERC20.deploy('OKB', 'OKB', ethers.utils.parseEther('10000000000'));
        await okb.deployed();

        dot = await MockERC20.deploy('DOT', 'DOT', ethers.utils.parseEther('10000000000'));
        await dot.deployed();

    };

    const initUniSwap = async () => {
        const UniswapV2Factory = await ethers.getContractFactory("UniswapV2Factory");
        factory = await UniswapV2Factory.deploy(owner.address);
        await factory.deployed();
        const UniswapV2Router = await ethers.getContractFactory("UniswapRouter");
        router = await UniswapV2Router.deploy(factory.address, weth.address);
        await router.deployed();
        UniAdapter = await ethers.getContractFactory("UniAdapter");
        uniAdapter = await UniAdapter.deploy();
        await uniAdapter.deployed();

        await factory.createPair(usdt.address, weth.address);
        await factory.createPair(weth.address, wbtc.address);
        await factory.createPair(usdt.address, wbtc.address);
        await factory.createPair(usdt.address, okb.address);
        await factory.createPair(okb.address, dot.address);
        await factory.createPair(dot.address,  wbtc.address);
        await factory.createPair(okb.address,  wbtc.address);
        await factory.createPair(okb.address,  weth.address);

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

        pair = await factory.getPair(okb.address, weth.address);
        emptyPool = await UniswapPair.attach(pair);
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

    const addLiquidity = async () => {
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

    const initLayersWholeSwap = async () => {

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

        let layers = [layer1, layer2, layer3];
        return layers;
    }

    const initLayersReplaceFirstBatch = async () => {

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

    const initLayersReplaceHops = async () => {

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


});












