const { getPullInfosToBeSigned, multipleQuotes } = require("./pmm/quoter");
const { ethers } = require("hardhat");


async function main(){
    // const ETH = { address: '0x0000000000000000000000000000000000000000'}
    // 1. prepare accounts and chain id
    const [owner, alice, bob] = await ethers.getSigners();
    console.log("bob", bob.address);
    const { chainId }  = await ethers.provider.getNetwork();

    // 2. prepare mock tokens
    let wbtc, usdt, weth;
    await initMockTokens();

    const PMMAdapter = await ethers.getContractFactory("TokenApproveProxy");
    const pMMAdapter = await PMMAdapter.deploy();

    // 3. prepare marketMaker
    let marketMaker;
    MarketMaker = await ethers.getContractFactory("MarketMaker");
    // TODO 这里等 marketMaker 合约之后更换为 marketMaker.initialize 初始化
    marketMaker = await MarketMaker.deploy(    
        // weth.address, alice.address, owner.address, 0
    );
    await marketMaker.deployed();
    marketMaker.initialize(weth.address, alice.address, owner.address, 0);
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

    await wbtc.connect(bob).approve(tokenApprove.address, ethers.utils.parseEther('2'));

    // 5. prepare quotes
    let rfq = [
        {
            "pathIndex": 100000000000000,
            "fromTokenAddress": usdt.address, 
            "toTokenAddress": wbtc.address, 
            "fromTokenAmount": '50000000000000000000000', 
            "toTokenAmountMin": '1000000000000000000',
            "chainId": chainId
        }
    ]
    let infosToBeSigned = getPullInfosToBeSigned(rfq);
    let quote = multipleQuotes(infosToBeSigned.pullInfosToBeSigned, infosToBeSigned.chainId);

    // 6. construct of input of funciton swap
    let infos = quote[0].infos;
    let request = [
        infos.pathIndex, 
        infos.payer, 
        infos.fromTokenAddress, 
        infos.toTokenAddress, 
        infos.fromTokenAmountMax, 
        infos.toTokenAmountMax, 
        infos.salt, 
        infos.deadLine, 
        infos.isPushOrder
    ];
    let signature = quote[0].signature;

    // 7. swap
    await marketMaker.connect(alice).swap(
        alice.address,
        ethers.utils.parseEther('50000'),
        request,
        signature
    );

    // 8. check balance
    let alice_wbtc_bal = await wbtc.balanceOf(alice.address);
    console.log("alice_get_wbtc", Number(alice_wbtc_bal));
    console.log("bob_paid_wbtc", infos.toTokenAmountMax);

    async function initMockTokens() {
        // alice has 50000 usdt, bob has 2 wbtc
        // alice want to buy 1 wbtc with her 50000 usdt, and bob is willing to provide pmm liquidity
        const MockERC20 = await ethers.getContractFactory("MockERC20");
    
        usdt = await MockERC20.deploy('USDT', 'USDT', ethers.utils.parseEther('10000000000'));
        await usdt.deployed();
        await usdt.transfer(alice.address, ethers.utils.parseEther('50000'));
        await usdt.transfer(bob.address, ethers.utils.parseEther('0'));
    
        wbtc = await MockERC20.deploy('WBTC', 'WBTC', ethers.utils.parseEther('10000000000'));
        await wbtc.deployed();
        await wbtc.transfer(alice.address, ethers.utils.parseEther('0'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('2'));
    
        weth = await MockERC20.deploy('WETH', 'WETH', ethers.utils.parseEther('10000000000'));
        await wbtc.deployed();
        await wbtc.transfer(alice.address, ethers.utils.parseEther('0'));
        await wbtc.transfer(bob.address, ethers.utils.parseEther('0'));
    
    }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });