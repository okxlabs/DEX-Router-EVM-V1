/*
** 功能：
** 1. 将主网合约fork到测试网络中
** 2. 提供代理合约升级的功能，便于增加console.log进行交易分析
** 3. 可以在测试网络中使用脚本生成的calldata，也可以使用外部的calldata
**
** 注意事项：
** 1. 需要将hardhat.config.js 中的 hardhat 网络的 chainId 改为 66
** 2. 根据需要修改fork的区块高度
** 3. 需要将 openzeppelin 合约包拷贝到 contracts 目录下，需要生成 ProxyAdmin 实例
** 4. 检查节点状态是否正常
**
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
const okcdevDeployed = require("../../../scripts/deployed/okc_dev");
require ('../../../scripts/tools');


describe("Integration Test Forking OKC Mainnet", function() {
    this.timeout(10000);

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

        UniswapPair = await ethers.getContractFactory("UniswapV2Pair");

        factory = await ethers.getContractAt(
            "UniswapV2Factory",
            okcdevDeployed.base.cheeryFactory            // cherry factory
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

        marketMakerProxyAdmin = await ethers.getContractAt(
            "ProxyAdmin",
            okcdevDeployed.base.marketMakerProxyAdmin
        );
        
        dexRouterProxyAdmin = await ethers.getContractAt(
            "ProxyAdmin",
            okcdevDeployed.base.dexRouterProxyAdmin
        );
    }

    const setForkBlockNumber = async (targetBlockNumber) => {
        await network.provider.request({
            method: "hardhat_reset",
            params: [
                {
                    forking: {
                        jsonRpcUrl: `http://35.73.164.192:26659`,
                        // jsonRpcUrl: `https://exchainrpc.okex.org`,
                        blockNumber: targetBlockNumber,
                    },
                },
            ],
        });
    }

    beforeEach(async function() {

        await setForkBlockNumber(12117580);

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
                "pmmAdapter": marketMaker.address,
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



        // external calldata swap
        let calldata = '0xce8c4316800000000000000000000000382bb369d343125bfb2117af9c149795c6c65c50000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000000000000000000002710cdc1f3400000000000000000000000000000000000000000000000000000022f9b6dd3433b80000000000000000000000000000000000000000000000000000000062bc2f960000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000002710cdc1f34000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000002370c17e71a00000000000000000000000000032fe03fbdaf63c8151a9ea3802969321a81ab17b000000000000000000000000382bb369d343125bfb2117af9c149795c6c65c500000000000000000000000008f8526dbfd6e38e3d8307702ca8469bae6c56c1500000000000000000000000000000000000000000000000004b7ec32d7a2000000000000000000000000000000000000000000000000000000470de4df8200000000000000000000000000000000000000000000000000000000000062bc216e0000000000000000000000000000000000000000000000000000000062bc2f7e0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000004d8d82f269a2704867b6caf58d6e8389e3066ec90000000000000000000000000000000000000000000000000000a15dd0664c1bee0464023d34613de2974aab58928d4953a7f24a8a6274577f024d32bd1707f323c75f2f60310d5d85594679792d49c5933e5a1fd25e594420d854867183471862c3fc90c1acb94d1a5878002418a63e6b53f93807eaa1208d7beffe018dda4b76fe5fa5009f0fe8f48c37ec9b7d8c0aaefb4fa8026d279ed2aca0f312e197300000000000000000000000000000000000000000000000000000000000000000';
        let transaction = {
            to: dexRouter.address,
            data: calldata,
            gasLimit: 10000000,
            value: ethers.utils.parseEther('0.01')
        }

        let txres = await bob.call(transaction);
        console.log("txres",txres);

        // // let txres = await bob.sendTransaction(transaction);
        // // let receipt = await txres.wait();
        // // console.log("receipt", receipt);

    })


});












