const { getPullInfosToBeSigned, getPushInfosToBeSigned, multipleQuotes } = require("../quoter");
const { ethers } = require("hardhat");
const { expect } = require('chai');


async function main(){
    // const ETH = { address: '0x0000000000000000000000000000000000000000'}
    // 1. prepare accounts and chain id
    const [owner, alice, bob] = await ethers.getSigners();
    console.log("bob", bob.address);
    const { chainId }  = await ethers.provider.getNetwork();

    // 2. prepare mock tokens
    let wbtc, usdt, weth;
    await initMockTokens();

    // 3. prepare pmm adapter
    let pmmAdapter;
    PMMAdapter = await ethers.getContractFactory("PMMAdapter");
    pmmAdapter = await PMMAdapter.deploy(weth.address, alice.address, owner.address, 0);
    await pmmAdapter.deployed();
    console.log("pmmAdapter",pmmAdapter.address);
    await pmmAdapter.connect(bob).setOperator(bob.address);
    await wbtc.connect(bob).approve(pmmAdapter.address, ethers.utils.parseEther('2'));

    // 4. prepare quotes
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
    console.log(quote);


    // 5. construct of input of funciton swap
    // struct PMMSwapRequest {
    //     uint256 pathIndex;
    //     address payer;
    //     address fromToken;
    //     address toToken;
    //     uint256 fromTokenAmountMax;
    //     uint256 toTokenAmountMax;
    //     uint256 salt;
    //     uint256 deadLine;
    //     bool    isPushOrder;
    // }
    // function swap(
    //     address to,    
    //     uint256 actualAmountRequest,                   
    //     PMMSwapRequest memory request,
    //     bytes memory signature
    // ) external onlyRouter returns(bool)

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
    console.log("request",request);
    console.log("signature",signature);
    
    // 3. swap
    await pmmAdapter.connect(alice).swap(
        alice.address,
        ethers.utils.parseEther('50000'),
        request,
        signature
    );
    // await amount.wait();
    // console.log("amount",amount);


    // 4. check balance
    let alice_wbtc_bal = await wbtc.balanceOf(alice.address);
    console.log("alice_wbtc_bal",alice_wbtc_bal);


    async function  initMockTokens (){
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