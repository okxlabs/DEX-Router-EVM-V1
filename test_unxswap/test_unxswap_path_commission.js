const { ethers, upgrades } = require('hardhat')
const { BigNumber } = require('ethers')
const { expect } = require('chai')
const { getPermitDigest, sign } = require('./signatures')
const pmm_params = require("../test_pmm/pmm/pmm_params");


const ethDeployed = require("../scripts/deployed/eth");

require ('../scripts/tools');

//
// You need to change the address in the Unxswap contract before running the test case
//
describe("Unxswap swap test with commission", function() {
  this.timeout(300000);

  const ETH = { address: '0x0000000000000000000000000000000000000000' }
  const FOREVER = '2000000000';
  let wbtc, weth, dot, bnb, usdc, usdt;
  let router, tokenApprove, dexRouter, xBridge, wNativeRelayer;
  let owner, alice, bob;
  let cBridge = "0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820";

  const feeReceiver = "0x94d3af948652ea2b272870ffa10da3250e0a34c3" // unibot address
  const fee = ethers.BigNumber.from(100).toHexString()
  const commissionFlag = "0x3ca20afc2aaa"
  const commissionInfo = "0x"+commissionFlag.replace('0x','')+'0000000000'+fee.replace('0x','')+feeReceiver.replace('0x','')
  // const commissionInfo = "0x3ca20afc2aaa00000000006494d3af948652ea2b272870ffa10da3250e0a34c3"; // unibot address, with commission fee 100/10000

  before(async function() {
    [owner, alice, bob, liquidity, tom] = await ethers.getSigners();
    await setForkBlockNumber(16094434); 

    await initWeth();
    await initTokenApproveProxy();
    await initDexRouter();
    await initMockXBridge();
    await initWNativeRelayer();

  });

  beforeEach(async function() {
    await initMockTokens();
    await initUniSwap();
    


    const pairs = [
      [weth, usdt, ethers.utils.parseEther('100'), ethers.utils.parseEther('300000')],
      [wbtc, usdt, ethers.utils.parseEther('100'), ethers.utils.parseEther('4000000')],
      [wbtc, weth, ethers.utils.parseEther('10'), ethers.utils.parseEther('100')],
      [weth, dot, ethers.utils.parseEther('10'), ethers.utils.parseEther('100')],
      [dot,  usdt, ethers.utils.parseEther('100'), ethers.utils.parseEther('3000')],
      [wbtc, dot, ethers.utils.parseEther('10'), ethers.utils.parseEther('10000')],
      [usdt, usdc, ethers.utils.parseEther('10000'), ethers.utils.parseEther('10000')],
      [bnb, wbtc, ethers.utils.parseEther('100'), ethers.utils.parseEther('100000')],
    ]
    for (let i = 0; i < pairs.length; i++) {
      await addLiquidity(
          pairs[i][0],
          pairs[i][1],
          pairs[i][2],
          pairs[i][3],
      );
    }
  });

  it("ERC20 token single pool exchange with commission fee 100", async () => {
    const reserves = await lpWBTCUSDT.getReserves();
    const token0 = await lpWBTCUSDT.token0();
    if (await lpWBTCUSDT.token0() == wbtc.address) {
      expect(reserves[0]).to.be.eq("100000000000000000000");
      expect(reserves[1]).to.be.eq("4000000000000000000000000");
    } else {
      expect(reserves[1]).to.be.eq("100000000000000000000");
      expect(reserves[0]).to.be.eq("4000000000000000000000000");
    }

    sourceToken = wbtc;
    targetToken = usdt;
    const totalAmount = ethers.utils.parseEther('0.1');
    const commissionAmount = totalAmount.mul(fee).div(10000)
    const fromTokenAmount = totalAmount.sub(commissionAmount)
    // 0x4 WETH -> ETH; 0x8 reverse pair
    flag = sourceToken.address == token0 ? '0x0' : "0x8";
    poolAddr = lpWBTCUSDT.address.toString().replace('0x', '');
    poolFee = Number(997000000).toString(16).replace('0x', '');
    pool0 = flag + '000000000000000' + poolFee + poolAddr;

    await sourceToken.connect(alice).approve(tokenApprove.address, totalAmount);

    let rawInfo = await dexRouter.connect(alice).populateTransaction.unxswapByOrderId(
        sourceToken.address,
        fromTokenAmount,
        0,
        [pool0]
    );
    rawInfo.data = rawInfo.data + commissionInfo.replace('0x','')
    let tx = await alice.sendTransaction(rawInfo)
    let receipt = await tx.wait();
    console.log("receipt", receipt.cumulativeGasUsed);

    const amount = getAmountOut(fromTokenAmount, "4000000000000000000000000", "100000000000000000000");
    expect(await usdt.balanceOf(alice.address)).to.be.equal(amount);
    // commission fee
    expect(await wbtc.balanceOf(feeReceiver)).to.be.equal(commissionAmount)
  });

  it("WETH token single pool exchange with commissionfee 100", async () => {
    const token0 = await lpWETHUSDT.token0();
    reserves = await lpWETHUSDT.getReserves();
    if (token0 == weth.address) {
      expect(reserves[1]).to.be.eq("300000000000000000000000");
      expect(reserves[0]).to.be.eq("100000000000000000000");
    } else {
      expect(reserves[0]).to.be.eq("300000000000000000000000");
      expect(reserves[1]).to.be.eq("100000000000000000000");
    }

    sourceToken = weth;
    targetToken = usdt;
    const totalAmount = ethers.utils.parseEther('0.1');
    const commissionAmount = totalAmount.mul(fee).div(10000)
    const fromTokenAmount = totalAmount.sub(commissionAmount)
    // 0x4 WETH -> ETH 0x8 reverse pair
    flag = sourceToken.address == token0 ? '0x0' : "0x8";
    poolAddr = lpWETHUSDT.address.toString().replace('0x', '');
    poolFee = Number(997000000).toString(16).replace('0x', '');
    pool0 = flag + '000000000000000' + poolFee + poolAddr;

    //await sourceToken.connect(bob).transfer(alice.address, fromTokenAmount);
    await weth.connect(liquidity).deposit({ value: totalAmount });
    await weth.connect(liquidity).transfer(alice.address, totalAmount); // sourceToken = weth
    await sourceToken.connect(alice).approve(tokenApprove.address, totalAmount);

    let rawInfo = await dexRouter.connect(alice).populateTransaction.unxswapByOrderId(
      sourceToken.address,
      fromTokenAmount,
      0,
      [pool0]
  );
    rawInfo.data = rawInfo.data + commissionInfo.replace('0x','')
    let tx = await alice.sendTransaction(rawInfo)
    let receipt = await tx.wait()
    console.log("receipt", receipt.cumulativeGasUsed);
    // reveiveAmount = fromTokenAmount * 997 * r0 / (r1 * 1000 + fromTokenAmount * 997);
    expect(await usdt.balanceOf(alice.address)).to.be.equal("295817019727018840593");
    expect(await weth.balanceOf(feeReceiver)).to.be.equal(commissionAmount);
  });

  it("multi-pool token exchange with commissionfee 100", async () => {
    const token00 = await lpWBTCUSDT.token0();
    let reserves = await lpWBTCUSDT.getReserves();
    if (await lpWBTCUSDT.token0() == wbtc.address) {
      expect(reserves[0]).to.be.eq("100000000000000000000");
      expect(reserves[1]).to.be.eq("4000000000000000000000000");
    } else {
      expect(reserves[1]).to.be.eq("100000000000000000000");
      expect(reserves[0]).to.be.eq("4000000000000000000000000");
    }

    const token10 = await lpWETHUSDT.token0();
    reserves = await lpWETHUSDT.getReserves();
    if (token10 == weth.address) {
      expect(reserves[1]).to.be.eq("300000000000000000000000");
      expect(reserves[0]).to.be.eq("100000000000000000000");
    } else {
      expect(reserves[0]).to.be.eq("300000000000000000000000");
      expect(reserves[1]).to.be.eq("100000000000000000000");
    }

    sourceToken = wbtc;
    middleToken = usdt;
    targetToken = weth;

    // Bob transfer 0.1 ether wbtc to Alice
    await sourceToken.connect(bob).transfer(alice.address, ethers.utils.parseEther('0.1'));
    const totalAmount = ethers.utils.parseEther('0.1');
    const commissionAmount = totalAmount.mul(fee).div(10000)
    const fromTokenAmount = totalAmount.sub(commissionAmount)
    // 0x4: WETH -> ETH 0x8: reverse pair
    flag0 = sourceToken.address == token00 ? '0x0' : "0x8";
    flag1 = middleToken.address == token10 ? '0x0' : "0x8";
    poolAddr0 = lpWBTCUSDT.address.toString().replace('0x', '');
    poolAddr1 = lpWETHUSDT.address.toString().replace('0x', '');
    poolFee = Number(997000000).toString(16).replace('0x', '');
    pool0 = flag0 + '000000000000000' + poolFee + poolAddr0;
    pool1 = flag1 + '000000000000000' + poolFee + poolAddr1;

    await sourceToken.connect(alice).approve(tokenApprove.address, totalAmount);

    let rawInfo = await dexRouter.connect(alice).populateTransaction.unxswapByOrderId(
        sourceToken.address,
        fromTokenAmount,
        0,
        [pool0, pool1]
  );
    rawInfo.data = rawInfo.data + commissionInfo.replace('0x','')
    let tx = await alice.sendTransaction(rawInfo)
    let receipt = await tx.wait();
    console.log("receipt", receipt.cumulativeGasUsed);
    // const rev = fromTokenAmount * 997 * r0 / (r1 * 1000 + fromTokenAmount * 997);
    expect(await targetToken.balanceOf(alice.address)).to.be.equal("1293838473066507532");
    expect(await sourceToken.balanceOf(feeReceiver)).to.be.equal(commissionAmount)
  });

  it("if the source token is ETH, it should be successfully converted with commissionfee 100", async () => {
    const token0 = await lpWETHUSDT.token0();
    const reserves = await lpWETHUSDT.getReserves();
    if (token0 == weth.address) {
      expect(reserves[1]).to.be.eq("300000000000000000000000");
      expect(reserves[0]).to.be.eq("100000000000000000000");
    } else {
      expect(reserves[0]).to.be.eq("300000000000000000000000");
      expect(reserves[1]).to.be.eq("100000000000000000000");
    }

    sourceToken = ETH;
    targetToken = usdt;
    const totalAmount = ethers.utils.parseEther('0.1');
    const commissionAmount = totalAmount.mul(fee).div(10000)
    const fromTokenAmount = totalAmount.sub(commissionAmount)
    // 0x4 WETH -> ETH 0x8 reverse pair
    flag = token0 == weth.address ? '0x0' : '0x8'
    poolAddr = lpWETHUSDT.address.toString().replace('0x', '');
    poolFee = Number(997000000).toString(16).replace('0x', '');
    pool0 = flag + '000000000000000' + poolFee + poolAddr;
    // await sourceToken.connect(bob).approve(tokenApprove.address, fromTokenAmount);
    let rawInfo = await dexRouter.connect(alice).populateTransaction.unxswapByOrderId(
        sourceToken.address,
        fromTokenAmount,
        0,
        [pool0],
        {
          value: ethers.utils.parseEther('0.1')
        }
    );
    rawInfo.data = rawInfo.data + commissionInfo.replace('0x','')
    let tx = await alice.sendTransaction(rawInfo)
    let receipt = await tx.wait();

    console.log("receipt", receipt.cumulativeGasUsed);
    // const rev = fromTokenAmount * fee * r0 / (r1 * 1000 + fromTokenAmount * fee);
    expect(await targetToken.balanceOf(alice.address)).to.be.equal("295817019727018840593");
    expect(await ethers.provider.getBalance(feeReceiver)).to.be.equal(commissionAmount)
  });

  it("if the target token is ETH, it should be successfully converted with commission fee 100", async () => {

    const token0 = await lpWETHUSDT.token0();
    const reserves = await lpWETHUSDT.getReserves();
    if (token0 == weth.address) {
      expect(reserves[1]).to.be.eq("300000000000000000000000");
      expect(reserves[0]).to.be.eq("100000000000000000000");
    } else {
      expect(reserves[0]).to.be.eq("300000000000000000000000");
      expect(reserves[1]).to.be.eq("100000000000000000000");
    }

    sourceToken = usdt;
    targetToken = ETH;
    const totalAmount = ethers.utils.parseEther('3000');
    const commissionAmount = totalAmount.mul(fee).div(10000)
    const fromTokenAmount = totalAmount.sub(commissionAmount)
    // 0x4 WETH -> ETH 0x8 reverse pair
    flag = sourceToken.address == token0 ? "0x4" : "0xc";
    poolAddr = lpWETHUSDT.address.toString().replace('0x', '');
    poolFee = Number(997000000).toString(16).replace('0x', '');
    pool0 = flag + '000000000000000' + poolFee + poolAddr;

    await sourceToken.connect(bob).transfer(alice.address, totalAmount);
    await sourceToken.connect(alice).approve(tokenApprove.address, totalAmount);
    const beforeBalance = await ethers.provider.getBalance(alice.address);
    let rawInfo = await dexRouter.connect(alice).populateTransaction.unxswapTo(
        sourceToken.address,
        fromTokenAmount,
        0,
        tom.address,
        [pool0]
    );
    rawInfo.data = rawInfo.data + commissionInfo.replace('0x','')
    let tx = await alice.sendTransaction(rawInfo)
    let receipt = await tx.wait();
    console.log("receipt", receipt.cumulativeGasUsed);

    const costGas = await getTransactionCost(tx)
    const afterBalance = await ethers.provider.getBalance(tom.address);

    // const rev = fromTokenAmount * 997 * r0 / (r1 * 1000 + fromTokenAmount * 997);
    expect(afterBalance).to.be.equal(BigNumber.from('10000977382937195004150'));
    // console.log(await sourceToken.balanceOf(feeReceiver))
    // console.log(commissionAmount)
    expect(await sourceToken.balanceOf(feeReceiver)).to.be.equal(commissionAmount)
  })

  it("ERC20 token single pool exchange with order id", async () => {
    const reserves = await lpWBTCUSDT.getReserves();
    const token0 = await lpWBTCUSDT.token0();
    if (await lpWBTCUSDT.token0() == wbtc.address) {
      expect(reserves[0]).to.be.eq("100000000000000000000");
      expect(reserves[1]).to.be.eq("4000000000000000000000000");
    } else {
      expect(reserves[1]).to.be.eq("100000000000000000000");
      expect(reserves[0]).to.be.eq("4000000000000000000000000");
    }

    sourceToken = wbtc;
    targetToken = usdt;
    const totalAmount = ethers.utils.parseEther('0.1');
    const commissionAmount = totalAmount.mul(fee).div(10000)
    const fromTokenAmount = totalAmount.sub(commissionAmount)
    // 0x4 WETH -> ETH 0x8 reverse pair
    flag = sourceToken.address == token0 ? '0x0' : "0x8";
    poolAddr = lpWBTCUSDT.address.toString().replace('0x', '');
    poolFee = Number(997000000).toString(16).replace('0x', '');
    pool0 = flag + '000000000000000' + poolFee + poolAddr;

    await sourceToken.connect(alice).approve(tokenApprove.address, totalAmount);

    const orderId = "000000000000000000000001";
    let rawInfo = await dexRouter.connect(alice).populateTransaction.unxswapTo(
        "0x" + orderId + sourceToken.address.replace("0x", ""),
        fromTokenAmount,
        0,
        tom.address,
        [pool0]
    );
    rawInfo.data = rawInfo.data + commissionInfo.replace('0x','')
    let tx = await alice.sendTransaction(rawInfo)
    let receipt = await tx.wait();
    console.log("receipt", receipt.cumulativeGasUsed);    
    const iface = new ethers.utils.Interface(["event SwapOrderId(uint256 id)"]);
    expect(receipt.logs[0].topics[0]).to.be.equal(iface.getEventTopic("SwapOrderId(uint256)"))
    // expect(receipt.events[0].event).to.be.eq("SwapOrderId");
    // reveiveAmount = fromTokenAmount * 997 * r0 / (r1 * 1000 + fromTokenAmount * 997);
    const amount = getAmountOut(fromTokenAmount, "4000000000000000000000000", "100000000000000000000");
    expect(await targetToken.balanceOf(tom.address)).to.be.equal(amount);
    expect(await sourceToken.balanceOf(feeReceiver)).to.be.equal(commissionAmount)
  });


  const initMockTokens = async () => {
    const MockERC20 = await ethers.getContractFactory("MockERC20");

    usdt = await MockERC20.deploy('USDT', 'USDT', ethers.utils.parseEther('10000000000'));
    await usdt.deployed();
    await usdt.transfer(alice.address, ethers.utils.parseEther('0'));
    await usdt.transfer(bob.address, ethers.utils.parseEther('100000000'));

    wbtc = await MockERC20.deploy('WBTC', 'WBTC', ethers.utils.parseEther('10000000000'));
    await wbtc.deployed();
    await wbtc.transfer(alice.address, ethers.utils.parseEther('10'));
    await wbtc.transfer(bob.address, ethers.utils.parseEther('100000000'));

    const PermitToken = await ethers.getContractFactory("ERC20PermitMock");
    dot = await PermitToken.deploy('DOT', 'DOT',  ethers.utils.parseEther('10000000000'));
    await dot.deployed();
    await dot.transfer(alice.address, ethers.utils.parseEther('0'));
    await dot.transfer(owner.address, ethers.utils.parseEther('100000000'));
    await dot.transfer(bob.address, ethers.utils.parseEther('100000000'));

    bnb = await MockERC20.deploy('BNB', 'BNB', ethers.utils.parseEther('10000000000'));
    await bnb.deployed();
    await bnb.transfer(alice.address, ethers.utils.parseEther('100'));
    await bnb.transfer(bob.address, ethers.utils.parseEther('100000000'));

    usdc = await MockERC20.deploy('USDC', 'USDC', ethers.utils.parseEther('10000000000'));
    await usdc.deployed();
    await usdc.transfer(alice.address, ethers.utils.parseEther('0'));
    await usdc.transfer(bob.address, ethers.utils.parseEther('100000000'));
  }

  const initUniSwap = async () => {
    const UniswapV2Factory = await ethers.getContractFactory("UniswapV2Factory");
    factory = await UniswapV2Factory.deploy(owner.address);
    await factory.deployed();
    const UniswapV2Router = await ethers.getContractFactory("UniswapRouter");
    router = await UniswapV2Router.deploy(factory.address, weth.address);
    await router.deployed();

    await factory.createPair(wbtc.address, dot.address);
    await factory.createPair(wbtc.address, usdt.address);
    await factory.createPair(wbtc.address, usdc.address);
    await factory.createPair(wbtc.address, weth.address);
    await factory.createPair(wbtc.address, bnb.address);
    await factory.createPair(dot.address,  usdt.address);
    await factory.createPair(dot.address,  weth.address);
    await factory.createPair(usdt.address, weth.address);
    await factory.createPair(bnb.address,  usdc.address);
    await factory.createPair(bnb.address,  usdt.address);
    await factory.createPair(bnb.address,  weth.address);
    const UniswapPair = await ethers.getContractFactory("UniswapV2Pair");

    pair = await factory.getPair(wbtc.address, dot.address)
    lpWBTCDOT = await UniswapPair.attach(pair);

    pair = await factory.getPair(dot.address, usdt.address)
    lpDOTUSDT = await UniswapPair.attach(pair);

    pair = await factory.getPair(wbtc.address, bnb.address);
    lpWBTCBNB = await UniswapPair.attach(pair);

    pair = await factory.getPair(wbtc.address, usdc.address);
    lpWBTCUSDC = await UniswapPair.attach(pair);

    pair = await factory.getPair(bnb.address, usdc.address);
    lpBNBUSDC = await UniswapPair.attach(pair);

    pair = await factory.getPair(wbtc.address, usdt.address);
    lpWBTCUSDT = await UniswapPair.attach(pair);

    pair = await factory.getPair(usdt.address, weth.address);
    lpWETHUSDT = await UniswapPair.attach(pair);

    pair = await factory.getPair(dot.address, weth.address);
    lpWETHDOT = await UniswapPair.attach(pair);

    pair = await factory.getPair(wbtc.address, weth.address);
    lpWBTCWETH = await UniswapPair.attach(pair);

    pair = await factory.getPair(bnb.address, weth.address);
    lpBNBWETH = await UniswapPair.attach(pair);
  }

  const addLiquidity = async (token0, token1, amount0, amount1) => {
    await token0.connect(bob).approve(router.address, amount0);
    await token1.connect(bob).approve(router.address, amount1);
    await router.connect(bob).addLiquidity(
        token0.address,
        token1.address,
        amount0,
        amount1,
        '0',
        '0',
        bob.address,
        FOREVER
    );
  }

  const initWeth = async () => {
    weth = await ethers.getContractAt(
      "WETH9",
      ethDeployed.tokens.weth
    );

    setBalance(bob.address, ethers.utils.parseEther('1100000'));

    await weth.connect(bob).deposit({ value: ethers.utils.parseEther('1000000') });
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
  }

  const initDexRouter = async () => {
    let _feeRateAndReceiver = "0x000000000000000000000000" + pmm_params.feeTo.slice(2);
    DexRouter = await ethers.getContractFactory("DexRouter");
    dexRouter = await upgrades.deployProxy(
        DexRouter
    )

    
    await dexRouter.deployed();
    await dexRouter.initializePMMRouter(_feeRateAndReceiver);

    
    // await dexRouter.setApproveProxy(tokenApproveProxy.address);
    expect(await dexRouter._WETH()).to.be.equal(weth.address);
    expect(await dexRouter._APPROVE_PROXY()).to.be.equal(tokenApproveProxy.address);

    let accountAddress = await tokenApproveProxy.owner();
    startMockAccount([accountAddress]);
    tokenApproveProxyOwner = await ethers.getSigner(accountAddress);
    setBalance(tokenApproveProxyOwner.address, '0x56bc75e2d63100000');

    await tokenApproveProxy.connect(tokenApproveProxyOwner).addProxy(dexRouter.address);
    await tokenApproveProxy.connect(tokenApproveProxyOwner).setTokenApprove(tokenApprove.address);
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
    await wNativeRelayer.connect(wNativeRelayerOwner).setCallerOk([dexRouter.address], [true]);
    expect(await dexRouter._WNATIVE_RELAY()).to.be.equal(wNativeRelayer.address);
  }

  const initMockXBridge = async () => {
    xBridge = await ethers.getContractAt(
      "MockXBridge",
      ethDeployed.base.xbridge
    );
    let accountAddress = await xBridge.admin();

    startMockAccount([accountAddress]);
    XBridgeOwner = await ethers.getSigner(accountAddress);
    setBalance(XBridgeOwner.address, '0x56bc75e2d63100000');

    await xBridge.connect(XBridgeOwner).setDexRouter(dexRouter.address);

    await xBridge.connect(XBridgeOwner).setMpc([alice.address],[true]);
    await xBridge.connect(XBridgeOwner).setApproveProxy(tokenApproveProxy.address);

    await dexRouter.setPriorityAddress(xBridge.address, true);
  }

  const getTransactionCost = async (txResult) => {
    const cumulativeGasUsed = (await txResult.wait()).cumulativeGasUsed;
    return BigNumber.from(txResult.gasPrice).mul(BigNumber.from(cumulativeGasUsed));
  };

  const getAmountOut = function(amountIn, r0, r1) {
    return ethers.BigNumber.from(amountIn.toString())
        .mul(ethers.BigNumber.from('997'))
        .mul(ethers.BigNumber.from(r0))
        .div(
            ethers.BigNumber.from(r1)
                .mul(ethers.BigNumber.from('1000'))
                .add(ethers.BigNumber.from(amountIn.toString()).mul(ethers.BigNumber.from('997')))
        );
  }
});