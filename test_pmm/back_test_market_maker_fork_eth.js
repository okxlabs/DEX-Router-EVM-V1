const { getPullInfosToBeSigned, getPullInfosToBeSigned_paidByMockAccount, getPushInfosToBeSigned, multipleQuotes, getDigest } = require("./pmm/quoter");
const { ethers, network } = require("hardhat");
const hre = require("hardhat");
const { BigNumber } = require('ethers')
const { expect } = require("chai");
const ALCHEMY_KEY = process.env.ALCHEMY_KEY;
const tokens = require("./pmm/tokens");

describe("Market Marker test", function() {
    this.timeout(10000);

    let owner, alice, bob, backEnd;
    let weth;
    const ETH = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
    const FOREVER = '2000000000';

    beforeEach(async function() {
        // fork states 
        // https://cn.etherscan.com/tx/0xd4902a42097534a33ecf9b2e817c80da1972e91effd58a06abbe0214c107c25f

        // 1. prepare accounts
        await setForkBlockNumber(14684645);
        await initAccounts();
        [owner,,signer,,backEnd] = await ethers.getSigners();

        // console.log("backEnd",backEnd.address);
        // 2. prepare tokens
        await initTokens();

    });

    //  =========================  Multiple  Exchange Test  ============================
//  dex swap path
//  100%  eth -> uni
//
//  market maker quotes
//  100%  eth -> uni


//  price:
//  uni: 7
//  eth: 3000

    it("DexRouter -> MarketMaker fork eth test: Try to replace the whole swap with pmm and success", async () => {
        const { chainId }  = await ethers.provider.getNetwork();
        // 3. prepare marketMaker
        let marketMaker;
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0, backEnd.address);

        await marketMaker.connect(bob).setOperator(signer.address);

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

        UniAdapter = await ethers.getContractFactory("UniAdapter");
        uniAdapter = await UniAdapter.deploy();
            
        // 5. prepare quotes
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": weth.address, 
                "toTokenAddress": uni.address, 
                "fromTokenAmount": ethers.utils.parseEther('0.014'), 
                "toTokenAmountMin": ethers.utils.parseEther('5.1'),
                "chainId": chainId,
                "marketMaker": marketMaker.address,
                "pmmAdapter": pmmAdapter.address
            }
        ]
        let infosToBeSigned = getPullInfosToBeSigned_paidByMockAccount(rfq);
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
        let markerAmount = ethers.utils.parseEther('10');
        await uni.connect(bob).approve(tokenApprove.address, markerAmount);
        let swapAmount = ethers.utils.parseEther('0.013658558763417873');
        // await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x80' + '0000000000000000000000' + ETH.slice(2),
            uni.address,
            swapAmount,
            ethers.utils.parseEther('5'),
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

        // 8. check balance
        expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0.013658558763417873'));
        expect(aliceUniBalAfter.sub(aliceUniBalBefore)).to.equal(ethers.utils.parseEther('5.025374013597533130'));

    })


    it("DexRouter -> MarketMaker fork eth test: Try to replace the whole swap with pmm but failed, turn to dex", async () => {
        const { chainId }  = await ethers.provider.getNetwork();
        // 3. prepare marketMaker
        let marketMaker;
        MarketMaker = await ethers.getContractFactory("MarketMaker");
        marketMaker = await MarketMaker.deploy();
        await marketMaker.deployed();
        marketMaker.initialize(weth.address, alice.address, owner.address, 0, backEnd.address);

        await marketMaker.connect(bob).setOperator(signer.address);

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

        UniAdapter = await ethers.getContractFactory("UniAdapter");
        uniAdapter = await UniAdapter.deploy();
            
        // 5. prepare quotes
        let rfq = [
            {
                "pathIndex": 100000000000000,
                "fromTokenAddress": weth.address, 
                "toTokenAddress": uni.address, 
                "fromTokenAmount": ethers.utils.parseEther('0.014'), 
                "toTokenAmountMin": ethers.utils.parseEther('5.1'),
                "chainId": chainId,
                "marketMaker": marketMaker.address,
                "pmmAdapter": pmmAdapter.address
            }
        ]
        let infosToBeSigned = getPullInfosToBeSigned_paidByMockAccount(rfq);
        let quote = multipleQuotes(infosToBeSigned);

        // 6. construct of input of funciton swap
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

        // 7. swap
        let markerAmount = ethers.utils.parseEther('10');
        await uni.connect(bob).approve(tokenApprove.address, markerAmount);
        let swapAmount = ethers.utils.parseEther('0.013658558763417873');
        // await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x80' + '0000000000000000000000' + ETH.slice(2),
            uni.address,
            swapAmount,
            ethers.utils.parseEther('5'),
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

        // 8. check balance
        expect(await weth.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('0'));
        expect(uniOut).to.equal(ethers.utils.parseEther('5.024974873392398340'));
    })

    //  ==========================  internal functions  ===========================
    const setForkBlockNumber = async (blockNumber) => {
        await network.provider.request({
            method: "hardhat_reset",
            params: [
                {
                    forking: {
                        jsonRpcUrl: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_KEY}`,
                        blockNumber: blockNumber,
                    },
                },
            ],
        });
    }

    const startMockAccount = async (account) => {
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: account,
        });
    }

    const setBalance = async (user, amount) => {
        await network.provider.send("hardhat_setBalance", [
            user,
            amount,
        ]);
    }

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
    }

    const initTokens = async () => {
        wbtc = await ethers.getContractAt(
            "MockERC20",
            tokens.WBTC.baseTokenAddress
        );

        usdc = await ethers.getContractAt(
            "MockERC20",
            tokens.USDC.baseTokenAddress
        );

        usdt = await ethers.getContractAt(
            "MockERC20",
            tokens.USDT.baseTokenAddress
        );

        uni = await ethers.getContractAt(
            "MockERC20",
            tokens.UNI.baseTokenAddress
        );

        weth = await ethers.getContractAt(
            "WETH9",
            tokens.WETH.baseTokenAddress
        )

        const UniswapPair = await ethers.getContractFactory("UniswapV2Pair");

        const factory = await ethers.getContractAt(
            "UniswapV2Factory",
            tokens.FACTORY
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

    const getWeight = function(weight) {
        return ethers.utils.hexZeroPad(weight, 2).slice(2);
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


});

