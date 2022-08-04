/*
** 功能：
** 1. 将主网合约fork到测试网络中
** 2. 提供代理合约升级的功能，便于增加console.log进行交易分析
** 3. 可以在测试网络中使用脚本生成的calldata，也可以使用外部的calldata
**
** 注意事项：
** 1. 需要将hardhat.config.js 中的 hardhat 网络的 chainId 改为 66(okc)
** 2. 根据需要修改fork的区块高度
** 3. 需要将 openzeppelin 合约包拷贝到 contracts 目录下，需要生成 ProxyAdmin 实例
** 4. 检查节点状态是否正常
** 5. 检查代币授权
** 
*/
const { 
    multipleQuotes, 
    getPullInfosToBeSigned_paidByOKCMockAccount,
} = require("../../pmm/quoter");
const { ethers, upgrades, network} = require("hardhat");
const hre = require("hardhat");

const { BigNumber } = require('ethers')
const { expect } = require("chai");
const bscdevDeployed = require("../../../scripts/deployed/bsc_dev");
require ('../../../scripts/tools');


describe("Integration Test Forking BSC Mainnet", function() {
    this.timeout(20000);

    let wokt, wbtc, usdt, weth, factory, router;
    let alice, bob, singer;
    const OKT = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
    const FOREVER = '2000000000';

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

    const startMockAccount = async (account) => {
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: account,
        });
    }

    const initAccounts = async () => {
        // moc alice as user
        let accountAddress = "0x98FAFc37e930c3C9326EDa1B5B75227f2563cFF6";
        startMockAccount([accountAddress]);
        alice = await ethers.getSigner(accountAddress);

        // mock bob as market maker
        accountAddress = "0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6";
        startMockAccount([accountAddress]);
        bob = await ethers.getSigner(accountAddress);

        accountAddress = "0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6";
        startMockAccount([accountAddress]);
        proxyOwner = await ethers.getSigner(accountAddress);

    }

    const initTokens = async () => {
        btck = await ethers.getContractAt(
            "MockERC20",
            bscdevDeployed.tokens.btck
        );

        usdc = await ethers.getContractAt(
            "MockERC20",
            bscdevDeployed.tokens.usdc
        );

        usdt = await ethers.getContractAt(
            "MockERC20",
            bscdevDeployed.tokens.usdt
        );

        wokt = await ethers.getContractAt(
            "WETH9",
            bscdevDeployed.tokens.wokt
        );

        UniswapPair = await ethers.getContractFactory("UniswapV2Pair");

        factory = await ethers.getContractAt(
            "UniswapV2Factory",
            bscdevDeployed.base.cheeryFactory            // cherry factory
        );

        pair = await factory.connect(alice).getPair(usdt.address, wokt.address);
        lpUSDCBTCK = await UniswapPair.attach(pair);

        pair = await factory.getPair(usdc.address, usdt.address)
        lpUSDCUSDT = await UniswapPair.attach(pair);
        // console.log("lpUSDCUSDT", lpUSDCUSDT.address);

        pair = await factory.getPair(usdt.address, btck.address)
        lpUSDTBTCK = await UniswapPair.attach(pair);
        // console.log("lpUSDTWBTC", lpUSDTWBTC.address);

        pair = await factory.getPair(wokt.address, usdt.address)
        lpWOKTUSDT = await UniswapPair.attach(pair);
    
    }

    const initContract = async () => {
        dexRouter = await ethers.getContractAt(
            "DexRouter",
            bscdevDeployed.base.dexRouter
        );

        tokenApprove = await ethers.getContractAt(
            "TokenApprove",
            bscdevDeployed.base.tokenApprove
        );

        uniAdapter = await ethers.getContractAt(
            "UniAdapter",
            bscdevDeployed.adapter.uniV2
        );

        marketMaker = await ethers.getContractAt(
            "MarketMaker",
            bscdevDeployed.base.marketMaker
        );

        pmmAdapter = await ethers.getContractAt(
            "PMMAdapter",
            bscdevDeployed.base.pmmAdapter
        );

        marketMakerProxyAdmin = await ethers.getContractAt(
            "ProxyAdmin",
            bscdevDeployed.base.marketMakerProxyAdmin
        );
        
        dexRouterProxyAdmin = await ethers.getContractAt(
            "ProxyAdmin",
            bscdevDeployed.base.dexRouterProxyAdmin
        );
    }

    const setForkBlockNumber = async (targetBlockNumber) => {
        await network.provider.request({
            method: "hardhat_reset",
            params: [
                {
                    forking: {
                        jsonRpcUrl: "https://rpc.ankr.com/bsc",
                        // jsonRpcUrl: "https://bsc-dataseed.binance.org",
                        // jsonRpcUrl: "https://bscrpc.com	",

                        blockNumber: targetBlockNumber,
                    },
                },
            ],
        });
    }

    beforeEach(async function() {
        console.log("000");

        await setForkBlockNumber(11095297);
        console.log("111");
        await initAccounts();

        [, , singer] = await ethers.getSigners();

        await initTokens();

        await initContract();


    });

    it("fork and upgrade", async () => {

        const { chainId }  = await ethers.provider.getNetwork();

        // 1. 更新marketMaker为可以打印日志的实例
        const MarketMakerLog = await ethers.getContractFactory("MarketMaker");
        const marketMakerLog = await MarketMakerLog.deploy();
        await marketMakerLog.deployed();
        await marketMakerProxyAdmin.connect(proxyOwner).upgrade(marketMaker.address, marketMakerLog.address);

        // 2. 更新dexRouter为可以打印日志的实例
        const DexRouterLog = await ethers.getContractFactory("DexRouter");
        const dexRouterLog = await DexRouterLog.deploy();
        await dexRouterLog.deployed();
        await dexRouterProxyAdmin.connect(proxyOwner).upgrade(dexRouter.address, dexRouterLog.address);
            
        // 3. prepare local quotes
        let source = await getSource(lpWOKTUSDT, wokt.address, usdt.address);
        // let source = "0000000000000000000000000000000000000000000000000000000000000000";
        let rfq = [
            {
                "pathIndex": '202000000000000001',
                "fromTokenAddress": wokt.address, 
                "toTokenAddress": usdt.address, 
                "fromTokenAmount": ethers.utils.parseEther('0.001'), 
                "toTokenAmountMin": ethers.utils.parseEther('0.025'),
                "chainId": chainId,
                "marketMaker": marketMaker.address,
                "pmmAdapter": pmmAdapter.address,
                "source": source
            }
        ]
        let infosToBeSigned = getPullInfosToBeSigned_paidByOKCMockAccount(rfq);
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
  
        // 7. swap
        await marketMaker.connect(bob).setOperator(singer.address);
        let markerAmount = ethers.utils.parseEther('10');
        await usdt.connect(bob).approve(tokenApprove.address, markerAmount);
        let bobUsdtbal = await usdt.connect(bob).balanceOf(bob.address);
        let swapAmount = ethers.utils.parseEther('0.0001');
        // await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x80' + '0000000000000000000000' + OKT.slice(2),
            usdt.address,
            swapAmount,
            ethers.utils.parseEther('0.00015'),
            FOREVER
        ]
        const layers = [[]];
        const batchesAmount = [swapAmount];

        // // local calldata swap
        // let res = await dexRouter.connect(alice).smartSwap(
        //     baseRequest,
        //     batchesAmount,
        //     layers,
        //     pmmRequests,
        //     {
        //         value: ethers.utils.parseEther('0.0001')
        //     }
        // );
        // // let receipt = await res.wait();
        // // console.log("receipt.logs", receipt.logs);
        // console.log("res", res.data);



        // mock user
        let userAccount = "0x93791409a358de76a7e0f08eca08923aa229739a";
        startMockAccount([userAccount]);
        user = await ethers.getSigner(userAccount);
        // external calldata swap
        let calldata = '0xce8c4316000000000000000000000000ea8c5b9c537f3ebbcc8f2df0573f2d084e9e2bdb000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000e84d000000000000000000000000000000000000000000000000000ca8c6d05341070000000000000000000000000000000000000000000000000000000062bb907b0000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000007a00000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000e84d00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000240000000000000000000000000000000000000000000000000000000000000042000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000160000000000000000000000000ea8c5b9c537f3ebbcc8f2df0573f2d084e9e2bdb00000000000000000000000000000000000000000000000000000000000000010000000000000000000000001cb017ec34ccd9b808e4f125163807885ab703380000000000000000000000000000000000000000000000000000000000000001000000000000000000000000203da29e2253133cc62e16c9c12887163fbfc4d20000000000000000000000000000000000000000000000000000000000000001800000000000000000002710203da29e2253133cc62e16c9c12887163fbfc4d2000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000001600000000000000000000000002170ed0880ac9a755fd29b2688956bd959f933f80000000000000000000000000000000000000000000000000000000000000001000000000000000000000000363fb85314c5d7baf27e9e5ac3b6e8bda9ae9b85000000000000000000000000000000000000000000000000000000000000000100000000000000000000000063b30de1a998e9e64fd58a21f68d323b9bcd8f85000000000000000000000000000000000000000000000000000000000000000100000000000000000000271063b30de1a998e9e64fd58a21f68d323b9bcd8f85000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000016000000000000000000000000055d398326f99059ff775485246999027b319795500000000000000000000000000000000000000000000000000000000000000010000000000000000000000001cb017ec34ccd9b808e4f125163807885ab70338000000000000000000000000000000000000000000000000000000000000000100000000000000000000000016b9a82891338f9ba80e2d6970fdda79d1eb0dae000000000000000000000000000000000000000000000000000000000000000100000000000000000000271016b9a82891338f9ba80e2d6970fdda79d1eb0dae00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';
        let transaction = {
            to: dexRouter.address,
            data: calldata,
            gasLimit: 10000000,
            value: ethers.utils.parseEther('0.01')
        }

        let txres = await user.call(transaction);
        console.log("txres",txres);

        // // let txres = await user.sendTransaction(transaction);
        // // let receipt = await txres.wait();
        // // console.log("receipt", receipt);

    })


});












