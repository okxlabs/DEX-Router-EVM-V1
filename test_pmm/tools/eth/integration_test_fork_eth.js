/*
** 功能：
** 1. 将主网合约fork到测试网络中
** 2. 提供代理合约升级的功能，便于增加console.log进行交易分析，目前支持对 DexRouter，MarketMaker，XBridge的升级
** 3. 可以在测试网络中使用脚本生成的calldata，也可以使用外部的calldata
** 
**
** 注意事项：
** 1. 需要将hardhat.config.js 中的 hardhat 网络的 chainId 改为 1(okc)
** 2. 根据需要修改fork的区块高度
** 3. 需要将 openzeppelin 合约包拷贝到 contracts 目录下，需要生成 ProxyAdmin 实例
** 4. 检查节点状态是否正常
** 5. 检查代币授权
** 6. 如果需要对XBridge进行升级，需要把XBridge的合约拷贝到contracts目录下，并删除XBridge的Mock文件夹
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
const ethdevDeployed = require("../../../scripts/deployed/eth_dev");
require ('../../../scripts/tools');


describe("Integration Test Forking ETH Mainnet", function() {
    this.timeout(20000);

    let weth, wbtc, usdt, factory, marketMaker, xBridge, router;
    let alice, bob, singer;
    const ETH = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
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
    };
    const setBalance = async (user, amount) => {
        await network.provider.send("hardhat_setBalance", [
            user,
            amount,
        ]);
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

        accountAddress = "0xcBfd32FDec86F88784266221CcE8141dA7B9A9eD";
        startMockAccount([accountAddress]);
        xbridgeProxyOwner = await ethers.getSigner(accountAddress);

        accountAddress = "0xb5d85CBf7cB3EE0D56b3bB207D5Fc4B82f43F511";
        startMockAccount([accountAddress]);
        rich = await ethers.getSigner(accountAddress);

        let tx = {
            to: proxyOwner.address,
            value: ethers.utils.parseEther('100')
        }
        await rich.sendTransaction(tx);

        tx = {
            to: alice.address,
            value: ethers.utils.parseEther('100')
        }
        await rich.sendTransaction(tx);

        tx = {
            to: xbridgeProxyOwner.address,
            value: ethers.utils.parseEther('100')
        }
        await rich.sendTransaction(tx);

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

        weth = await ethers.getContractAt(
            "WETH9",
            ethdevDeployed.tokens.weth
        );

        UniswapPair = await ethers.getContractFactory("UniswapV2Pair");

        factory = await ethers.getContractAt(
            "UniswapV2Factory",
            ethdevDeployed.base.uniV2Factory            
        );
        pair = await factory.getPair(usdt.address, weth.address);

        lpUSDTWETH = await UniswapPair.attach(pair);

        pair = await factory.getPair(usdc.address, usdt.address)
        lpUSDCUSDT = await UniswapPair.attach(pair);
        // console.log("lpUSDCUSDT", lpUSDCUSDT.address);

        pair = await factory.getPair(usdt.address, wbtc.address)
        lpUSDTWBTC = await UniswapPair.attach(pair);
        // console.log("lpUSDTWBTC", lpUSDTWBTC.address);
    
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

        marketMakerProxyAdmin = await ethers.getContractAt(
            "ProxyAdmin",
            ethdevDeployed.base.marketMakerProxyAdmin
        );
        
        dexRouterProxyAdmin = await ethers.getContractAt(
            "ProxyAdmin",
            ethdevDeployed.base.dexRouterProxyAdmin
        );

        xBridge = await ethers.getContractAt(
            "XBridge",
            ethdevDeployed.base.xbridge
        );

        xBridgeProxyAdmin = await ethers.getContractAt(
            "ProxyAdmin",
            ethdevDeployed.base.xbridgeProxyAdmin
        )
    }

    const setForkBlockNumber = async (targetBlockNumber) => {
        const INFURA_KEY = process.env.INFURA_KEY || '';
        await network.provider.request({
            method: "hardhat_reset",
            params: [
                {
                    forking: {
                        // jsonRpcUrl: `http://35.75.165.133:8545`,
                        jsonRpcUrl: `https://rpc.ankr.com/eth`,
                        // jsonRpcUrl: `https://mainnet.infura.io/v3/${INFURA_KEY}`,
                        blockNumber: targetBlockNumber,
                    },
                },
            ],
        });
    }

    beforeEach(async function() {

        await setForkBlockNumber(15139532);
        await initAccounts();
        [, , singer] = await ethers.getSigners();
        await initTokens();
        await initContract();

    });

    it("fork and upgrade", async () => {

        const { chainId }  = await ethers.provider.getNetwork();
        console.log("before upgrade");

        // .151818106331917988
        // 1. 更新marketMaker为可以打印日志的实例
        const MarketMakerLog = await ethers.getContractFactory("MarketMaker");
        const marketMakerLog = await MarketMakerLog.deploy();
        await marketMakerLog.deployed();
        await marketMakerProxyAdmin.connect(proxyOwner).upgrade(marketMaker.address, marketMakerLog.address);
        console.log("upgrade market maker");

        // 2. 更新dexRouter为可以打印日志的实例
        const DexRouterLog = await ethers.getContractFactory("DexRouter");
        const dexRouterLog = await DexRouterLog.deploy();
        await dexRouterLog.deployed();
        await dexRouterProxyAdmin.connect(proxyOwner).upgrade(dexRouter.address, dexRouterLog.address);
        
        // 3. 更新xBridge为可以打印日志的实例
        const XBridgeLog = await ethers.getContractFactory("XBridge");
        const xBridgeLog = await XBridgeLog.deploy();
        await xBridgeLog.deployed();
        await xBridgeProxyAdmin.connect(xbridgeProxyOwner).upgrade(xBridge.address, xBridgeLog.address);
        console.log("xBridge.address",xBridge.address);


        // // 3. prepare local quotes
        let source = await getSource(lpUSDTWETH, weth.address, usdt.address);
        // let source = "0000000000000000000000000000000000000000000000000000000000000000";
        let rfq = [
            {
                "pathIndex": '202000000000000001',
                "fromTokenAddress": weth.address, 
                "toTokenAddress": usdt.address, 
                "fromTokenAmount": ethers.utils.parseEther('0.0001'), 
                "toTokenAmountMin": BigNumber.from("100000"),
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
        let swapAmount = ethers.utils.parseEther('0.0001');
        // await usdt.connect(alice).approve(tokenApprove.address, swapAmount);

        const baseRequest = [
            '0x80' + '0000000000000000000000' + ETH.slice(2),
            usdt.address,
            swapAmount,
            "90000",
            FOREVER
        ]
        const layers = [[]];
        const batchesAmount = [swapAmount];

         // 1. 本地生成 calldata 调用
        let bobBal = await ethers.provider.getBalance(alice.address);
        let res = await dexRouter.connect(alice).smartSwap(
            baseRequest,
            batchesAmount,
            layers,
            pmmRequests,
            {
                value: ethers.utils.parseEther('0.0001')
            }
        );
        let receipt = await res.wait();
        console.log("receipt.logs", receipt.logs);
        // console.log("res", res.data);





        // 2. 外部calldata调用

        // =================== smart swap ====================
        // let allowance = ethers.utils.parseEther('10');
        // await wokt.connect(bob).approve(tokenApprove.address, allowance);
        // console.log("000");
        // let userAddress = "0x1a23c4272309cffdd29ce043990e96f0b37c7063";
        // startMockAccount([userAddress]);
        // let user = await ethers.getSigner(userAddress);
        // let bal = await ethers.provider.getBalance(user.address);
        // console.log("user balance", bal);

        // let usdtbal = await usdt.connect(user).balanceOf(user.address);
        // let usdtAllowance = await usdt.connect(user).allowance(user.address, tokenApprove.address);
        // console.log("usdtbal",usdtbal);
        // console.log("usdtAllowance",usdtAllowance);
        // console.log("usdt address", usdt.address);
        // // 1154593766925416256
        // // 151818106331917988


        // let calldata = '0xce8c4316800000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000000000000000000000000000000000000000000000002dc6c0000000000000000000000000000000000000000000000000000967b406af3f6c0000000000000000000000000000000000000000000000000000000062cfdcbc0000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000003a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000002dc6c0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000160000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000000000001000000000000000000000000c837bbea8c7b0cac0e8928f797ceb04a34c9c06e0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000703b120f15ab77b986a24c6f9262364d02f9432f0000000000000000000000000000000000000000000000000000000000000001800000000000000000002710703b120f15ab77b986a24c6f9262364d02f9432f0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000023758f45be6000000000000000000000000000ba47381da1fe3d4a41fa09703284a0e8dc983723000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000001e84800000000000000000000000000000000000000000000000000006a94d74f4300000000000000000000000000000000000000000000000000000000000062cfce9a0000000000000000000000000000000000000000000000000000000062cfcfc60000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000000df000000000000000000000000019440199101fb45882d06ee432437ec89f406248000000000000000000000000000000000000000000000000000016c376844a7ec4bc4fa25c0ee608fc4bae5ceeba377d0ec34ea47c08a748695ac04918f8e7d3e490ebc7f8174497e6e56313001b9b3b9bd0e335180b678060cc17b534ab410a7ff6261858e8b2dea0120c8feef63b019726828a7e7e6a5b282ea150463022b99613b0c352c27b74a66cc3dd97d8ca3d113eca81ef988ef01181650580716000000000000000000000000000000000000000000000000000000000000000000';
        // let transaction = {
        //     to: dexRouter.address,
        //     data: calldata,
        //     gasLimit: 1000000,
        //     // value: ethers.utils.parseEther('0.002')
        // }

        // // // let txres = await bob.call(transaction);
        // // // console.log("txres",txres);


        // // // let txres = await bob.sendTransaction(transaction);
        // let txres = await user.sendTransaction(transaction);
        // let receipt = await txres.wait();
        // console.log("receipt", receipt);

        // ================ 跨链 =================
        // console.log("start call");
        // console.log("xBridge",xBridge.address);
        // console.log("start tx");
        // let calldata = '0x238105e30000000000000000000000000000000000000000000000000000000000000020000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200000000000000000000000021e484c5bf78a4b5dab878260b75e41aef5c3ab70000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000003800000000000000000000000000000000000000000000000000000000006acfc00000000000000000000000000000000000000000000000000016daa0dcab8ac70000000000000000000000000000000000000000000000000016daa0dcab8ac7000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001a00000000000000000000000000000000000000000000000000000000000000040000000000000000000000000ba8da9dcf11b50b03fd5284f164ef5cdef9107050000000000000000000000000615dbba33fe61a31c7ed131bda6655ed76748b10000000000000000000000000000000000000000000000000000000000000424e051c6e8800000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200000000000000000000000000000000000000000000000000000000006acfc00000000000000000000000000000000000000000000000000017e8bf902b1ac70000000000000000000000000000000000000000000000000000000062ced04a0000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001a0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000006acfc0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000023754db18fd000000000000000000000000000ba47381da1fe3d4a41fa09703284a0e8dc983723000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000001c9c380000000000000000000000000000000000000000000000000006a94d74f4300000000000000000000000000000000000000000000000000000000000062cec1fe0000000000000000000000000000000000000000000000000000000062cec32a0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000019440199101fb45882d06ee432437ec89f4062480000000000000000000000000000000000000000000000000000b17b31af4ccf03e524a55ad420fa000ccec12f72e5157893a63bd4592701ecd8bc04096c828f701ef02e8a06e5d7df417b8ec83a0cec1e07fa543312a8d1956f94b73c301307b4735fda59f1082af1c18b35c96300295d4a070708870557c76ba3b85ab3f6cca785a56b78063f229af8df42e119920dc22fdcdb39ce2652ccb0218e3aadf8c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';
        // let transaction = {
        //     to: xBridge.address,
        //     data: calldata,
        //     gasLimit: 1000000,
        //     // value: ethers.utils.parseEther('1')
        // }

        // // let txres = await bob.call(transaction);
        // // console.log("txres",txres);

        // // let txres = await bob.sendTransaction(transaction);
        // let txres = await user.sendTransaction(transaction);
        // let receipt = await txres.wait();
        // console.log("receipt", receipt);



    })




});


