const { ethers } = require("hardhat")
const { BigNumber } = require("ethers")
const { expect } = require("chai")
const { getPermitDigest, sign } = require("./signatures")

//
// You need to change the address in the Unxswap contract before running the test case
//
describe("Unoswap swapForExactTokens test", function() {

  const ETH = { address: "0x0000000000000000000000000000000000000000" }
  const FOREVER = "2000000000"
  let wbtc, weth, dot, bnb, usdc, usdt
  let router, tokenApprove, dexRouter
  let owner, alice, bob

  before(async function() {
    [owner, alice, bob, liquidity] = await ethers.getSigners()
    await initDexRouter()
  })

  beforeEach(async function() {
    await initMockTokens()
    await initUniSwap()

    const pairs = [
      [weth, usdt, ethers.utils.parseEther("100"), ethers.utils.parseEther("300000")],
      [wbtc, usdt, ethers.utils.parseEther("100"), ethers.utils.parseEther("4000000")],
      [wbtc, weth, ethers.utils.parseEther("10"), ethers.utils.parseEther("100")],
      [weth, dot, ethers.utils.parseEther("10"), ethers.utils.parseEther("100")],
      [dot, usdt, ethers.utils.parseEther("100"), ethers.utils.parseEther("3000")],
      [wbtc, dot, ethers.utils.parseEther("10"), ethers.utils.parseEther("10000")],
      [usdt, usdc, ethers.utils.parseEther("10000"), ethers.utils.parseEther("10000")],
      [bnb, wbtc, ethers.utils.parseEther("100"), ethers.utils.parseEther("100000")]
    ]
    for (let i = 0; i < pairs.length; i++) {
      await addLiquidity(
        pairs[i][0],
        pairs[i][1],
        pairs[i][2],
        pairs[i][3]
      )
    }
  })

  it("ERC20 token single pool exchange", async () => {
    const reserves = await lpWBTCUSDT.getReserves()
    const token0 = await lpWBTCUSDT.token0()
    if (await lpWBTCUSDT.token0() == wbtc.address) {
      expect(reserves[0]).to.be.eq("100000000000000000000")
      expect(reserves[1]).to.be.eq("4000000000000000000000000")
    } else {
      expect(reserves[1]).to.be.eq("100000000000000000000")
      expect(reserves[0]).to.be.eq("4000000000000000000000000")
    }

    sourceToken = wbtc;
    targetToken = usdt;
    const amountOut = ethers.utils.parseEther("4000");
    const amountInMax = ethers.utils.parseEther("0.12");

    // 0x4 WETH -> ETH 0x8 reverse pair
    flag = sourceToken.address == token0 ? "0x0" : "0x8";
    poolAddr = lpWBTCUSDT.address.toString().replace("0x", "");
    poolFee = Number(997000000).toString(16).replace("0x", "");
    pool0 = flag + "000000000000000" + poolFee + poolAddr;

    const fromTokenBalanceBefore = await wbtc.balanceOf(alice.address);
    console.log(fromTokenBalanceBefore + "");

    // approve token approve amountInMax
    await sourceToken.connect(alice).approve(tokenApprove.address, amountInMax);
    expect(await usdt.balanceOf(alice.address)).to.be.equal("0");

    await dexRouter.connect(alice).unxswapForExactTokens(
      sourceToken.address,
      amountOut,
      amountInMax,
      [pool0]
    );

    // reveiveAmount = fromTokenAmount * 997 * r0 / (r1 * 1000 + fromTokenAmount * 997);
    expect(await usdt.balanceOf(alice.address)).to.be.equal(ethers.utils.parseEther("4000"));

    expect(await sourceToken.balanceOf(dexRouter.address)).to.be.equal("0");
    expect(await targetToken.balanceOf(dexRouter.address)).to.be.equal("0");
  })

  it("WETH token single pool exchange", async () => {
    const token0 = await lpWETHUSDT.token0()
    reserves = await lpWETHUSDT.getReserves()
    if (token0 == weth.address) {
      expect(reserves[1]).to.be.eq("300000000000000000000000")
      expect(reserves[0]).to.be.eq("100000000000000000000")
    } else {
      expect(reserves[0]).to.be.eq("300000000000000000000000")
      expect(reserves[1]).to.be.eq("100000000000000000000")
    }

    sourceToken = weth
    targetToken = usdt
    const amountOut = ethers.utils.parseEther("298.802094311970964947")
    const amountInMax = ethers.utils.parseEther("0.1")

    // 0x4 WETH -> ETH 0x8 reverse pair
    flag = sourceToken.address == token0 ? "0x0" : "0x8"
    poolAddr = lpWETHUSDT.address.toString().replace("0x", "")
    poolFee = Number(997000000).toString(16).replace("0x", "")
    pool0 = flag + "000000000000000" + poolFee + poolAddr

    await sourceToken.connect(bob).transfer(alice.address, amountInMax)
    await sourceToken.connect(alice).approve(tokenApprove.address, amountInMax)

    await dexRouter.connect(alice).unxswapForExactTokens(
      sourceToken.address,
      amountOut,
      amountInMax,
      [pool0]
    )

    // reveiveAmount = fromTokenAmount * 997 * r0 / (r1 * 1000 + fromTokenAmount * 997);
    expect(await usdt.balanceOf(alice.address)).to.be.equal("298802094311970964947")
  })

  it("multi-pool token exchange", async () => {
    const token00 = await lpWBTCUSDT.token0()
    let reserves = await lpWBTCUSDT.getReserves()
    if (await lpWBTCUSDT.token0() == wbtc.address) {
      expect(reserves[0]).to.be.eq("100000000000000000000")
      expect(reserves[1]).to.be.eq("4000000000000000000000000")
    } else {
      expect(reserves[1]).to.be.eq("100000000000000000000")
      expect(reserves[0]).to.be.eq("4000000000000000000000000")
    }

    const token10 = await lpWETHUSDT.token0()
    reserves = await lpWETHUSDT.getReserves()
    if (token10 == weth.address) {
      expect(reserves[1]).to.be.eq("300000000000000000000000")
      expect(reserves[0]).to.be.eq("100000000000000000000")
    } else {
      expect(reserves[0]).to.be.eq("300000000000000000000000")
      expect(reserves[1]).to.be.eq("100000000000000000000")
    }

    sourceToken = wbtc
    middleToken = usdt
    targetToken = weth

    const amountOut = ethers.utils.parseEther("1.306723925020281644")
    const amountInMax = ethers.utils.parseEther("0.1")

    // 0x4: WETH -> ETH 0x8: reverse pair
    flag0 = sourceToken.address == token00 ? "0x0" : "0x8"
    flag1 = middleToken.address == token10 ? "0x0" : "0x8"
    poolAddr0 = lpWBTCUSDT.address.toString().replace("0x", "")
    poolAddr1 = lpWETHUSDT.address.toString().replace("0x", "")
    poolFee = Number(997000000).toString(16).replace("0x", "")
    pool0 = flag0 + "000000000000000" + poolFee + poolAddr0
    pool1 = flag1 + "000000000000000" + poolFee + poolAddr1

    await sourceToken.connect(bob).transfer(alice.address, amountInMax)
    await sourceToken.connect(alice).approve(tokenApprove.address, amountInMax)

    await dexRouter.connect(alice).unxswapForExactTokens(
      sourceToken.address,
      amountOut,
      amountInMax,
      [pool0, pool1]
    )
    // const rev = fromTokenAmount * 997 * r0 / (r1 * 1000 + fromTokenAmount * 997);
    expect(await weth.balanceOf(alice.address)).to.be.equal("1306723925020281644")
  })

  it("if the source token is ETH, it should be successfully converted", async () => {
    const token0 = await lpWETHUSDT.token0()
    const reserves = await lpWETHUSDT.getReserves()
    if (token0 == weth.address) {
      expect(reserves[1]).to.be.eq("300000000000000000000000")
      expect(reserves[0]).to.be.eq("100000000000000000000")
    } else {
      expect(reserves[0]).to.be.eq("300000000000000000000000")
      expect(reserves[1]).to.be.eq("100000000000000000000")
    }

    sourceToken = ETH
    targetToken = usdt
    const amountOut = ethers.utils.parseEther("300");
    const amountInMax = ethers.utils.parseEther("0.5");

    // 0x4 WETH -> ETH 0x8 reverse pair
    flag = token0 == weth.address ? "0x0" : "0x8"
    poolAddr = lpWETHUSDT.address.toString().replace("0x", "")
    poolFee = Number(997000000).toString(16).replace("0x", "")
    pool0 = flag + "000000000000000" + poolFee + poolAddr

    await dexRouter.connect(alice).unxswapForExactTokens(
      sourceToken.address,
      amountOut,
      amountInMax,
      [pool0],
      {
        value: amountInMax
      }
    )

    // const rev = fromTokenAmount * fee * r0 / (r1 * 1000 + fromTokenAmount * fee);
    expect(await usdt.balanceOf(alice.address)).to.be.equal(ethers.utils.parseEther("300"));

    expect(await weth.balanceOf(dexRouter.address)).to.be.equal("0");
    expect(await ethers.getDefaultProvider().getBalance(dexRouter.address)).to.be.equal("0");
    expect(await targetToken.balanceOf(dexRouter.address)).to.be.equal("0");
  })

  it("if the target token is ETH, it should be successfully converted", async () => {
    WNativeRelayer = await ethers.getContractFactory("WNativeRelayer")
    wNativeRelayer = await WNativeRelayer.deploy()
    await wNativeRelayer.deployed()
    await wNativeRelayer.initialize(weth.address)
    await wNativeRelayer.setCallerOk([dexRouter.address], [true])
    expect(await dexRouter._WNATIVE_RELAY_32()).to.be.equal(wNativeRelayer.address)

    const token0 = await lpWETHUSDT.token0()
    const reserves = await lpWETHUSDT.getReserves()
    if (token0 == weth.address) {
      expect(reserves[1]).to.be.eq("300000000000000000000000")
      expect(reserves[0]).to.be.eq("100000000000000000000")
    } else {
      expect(reserves[0]).to.be.eq("300000000000000000000000")
      expect(reserves[1]).to.be.eq("100000000000000000000")
    }

    sourceToken = usdt
    targetToken = ETH
    const amountOut = ethers.utils.parseEther("0.987158034397061298")
    const amountInMax = ethers.utils.parseEther("3000")

    // 0x4 WETH -> ETH 0x8 reverse pair
    flag = "0xc"
    poolAddr = lpWETHUSDT.address.toString().replace("0x", "")
    poolFee = Number(997000000).toString(16).replace("0x", "")
    pool0 = flag + "000000000000000" + poolFee + poolAddr

    await sourceToken.connect(bob).transfer(alice.address, amountInMax)
    await sourceToken.connect(alice).approve(tokenApprove.address, amountInMax)

    const beforeBalance = await ethers.provider.getBalance(alice.address)
    txResult = await dexRouter.connect(alice).unxswapForExactTokens(
      sourceToken.address,
      amountOut,
      amountInMax,
      [pool0]
    )

    const costGas = await getTransactionCost(txResult)
    const afterBalance = await ethers.provider.getBalance(alice.address)

    // const rev = fromTokenAmount * 997 * r0 / (r1 * 1000 + fromTokenAmount * 997);
    expect(afterBalance).to.be.equal(BigNumber.from("987158034397061298").add(BigNumber.from(beforeBalance)).sub(costGas))
  })

  it("trader trades in permit signature mode", async () => {
    // token must support permit (EIP712)
    const token0 = await lpDOTUSDT.token0()
    reserves = await lpDOTUSDT.getReserves()
    if (await lpDOTUSDT.token1() == dot.address) {
      expect(reserves[1]).to.be.eq("4000000000000000000000000")
      expect(reserves[0]).to.be.eq("100000000000000000000")
    }

    sourceToken = dot
    targetToken = usdt
    const amountOut = ethers.utils.parseEther("2.988020943119709649")
    const amountInMax = ethers.utils.parseEther("0.1")

    // 0x4 WETH -> ETH 0x8 reverse pair
    flag = token0 == dot.address ? "0x0" : "0x8"
    poolAddr = lpDOTUSDT.address.toString().replace("0x", "")
    poolFee = Number(997000000).toString(16).replace("0x", "")
    pool0 = flag + "000000000000000" + poolFee + poolAddr

    let { chainId } = await ethers.provider.getNetwork()
    const nonce = await dot.nonces(owner.address)

    const approve = {
      owner: owner.address,
      spender: tokenApprove.address,
      value: amountInMax
    }
    const deadline = 200000000000000
    // Get the EIP712 digest
    const digest = getPermitDigest(
      await sourceToken.name(), sourceToken.address, chainId, approve, nonce, deadline
    )

    const mnemonic = "test test test test test test test test test test test junk"
    const walletMnemonic = ethers.Wallet.fromMnemonic(mnemonic)
    const ownerPrivateKey = Buffer.from(walletMnemonic.privateKey.replace("0x", ""), "hex")
    const { v, r, s } = sign(digest, ownerPrivateKey)

    //  0000000000000000000000003e4d12af4b6e47015804b990df8aa0de4e3fc866
    //  0000000000000000000000001111111254fb6c44bac0bed2854e76f90643097d
    //  ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    //  00000000000000000000000000000000000000000000000000000000621d4f63
    //  000000000000000000000000000000000000000000000000000000000000001c
    //  72ae3038adcab303d0993b456e8d718ece7f02d88d6b3e555e9745021f7bb1ab
    //  479631220d2549f7f658f8534ff412c3e90fc6a355458342bfd08edcba9e0081

    const signdata = await ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "uint256", "uint256", "uint8", "bytes32", "bytes32"],
      [
        approve.owner,
        approve.spender,
        approve.value,
        deadline,
        v,
        r,
        s
      ]
    )

    const beforeBalance = await usdt.balanceOf(owner.address)
    await dexRouter.connect(owner).unxswapForExactTokensWithPermxit(
      sourceToken.address,
      amountOut,
      amountInMax,
      [pool0],
      signdata
    )
    const afterBalance = await usdt.balanceOf(owner.address)

    // reveiveAmount = fromTokenAmount * 997 * r0 / (r1 * 1000 + fromTokenAmount * 997);
    expect(afterBalance.sub(beforeBalance)).to.be.equal("2988020943119709649")

    // Re-using the same sig doesn't work since the nonce has been incremented
    // on the contract level for replay-protection
    await expect(
      sourceToken.permxit(approve.owner, approve.spender, approve.value, deadline, v, r, s)
    ).to.be.revertedWith("ERC20Permit: invalid signature")
  })

  const initMockTokens = async () => {
    const MockERC20 = await ethers.getContractFactory("MockERC20")

    usdt = await MockERC20.deploy("USDT", "USDT", ethers.utils.parseEther("10000000000"))
    await usdt.deployed()
    await usdt.transfer(alice.address, ethers.utils.parseEther("0"))
    await usdt.transfer(bob.address, ethers.utils.parseEther("100000000"))

    wbtc = await MockERC20.deploy("WBTC", "WBTC", ethers.utils.parseEther("10000000000"))
    await wbtc.deployed()
    await wbtc.transfer(alice.address, ethers.utils.parseEther("10"))
    await wbtc.transfer(bob.address, ethers.utils.parseEther("100000000"))

    const PermitToken = await ethers.getContractFactory("ERC20PermitMock")
    dot = await PermitToken.deploy("DOT", "DOT", ethers.utils.parseEther("10000000000"))
    await dot.deployed()
    await dot.transfer(alice.address, ethers.utils.parseEther("0"))
    await dot.transfer(owner.address, ethers.utils.parseEther("100000000"))
    await dot.transfer(bob.address, ethers.utils.parseEther("100000000"))

    bnb = await MockERC20.deploy("BNB", "BNB", ethers.utils.parseEther("10000000000"))
    await bnb.deployed()
    await bnb.transfer(alice.address, ethers.utils.parseEther("100"))
    await bnb.transfer(bob.address, ethers.utils.parseEther("100000000"))

    usdc = await MockERC20.deploy("USDC", "USDC", ethers.utils.parseEther("10000000000"))
    await usdc.deployed()
    await usdc.transfer(alice.address, ethers.utils.parseEther("0"))
    await usdc.transfer(bob.address, ethers.utils.parseEther("100000000"))
  }

  const initUniSwap = async () => {
    UniAdapter = await ethers.getContractFactory("UniAdapter")
    uniAdapter = await UniAdapter.deploy()

    const UniswapV2Factory = await ethers.getContractFactory("UniswapV2Factory")
    factory = await UniswapV2Factory.deploy(owner.address)
    await factory.deployed()
    const UniswapV2Router = await ethers.getContractFactory("UniswapRouter")
    router = await UniswapV2Router.deploy(factory.address, weth.address)
    await router.deployed()

    await factory.createPair(wbtc.address, dot.address)
    await factory.createPair(wbtc.address, usdt.address)
    await factory.createPair(wbtc.address, usdc.address)
    await factory.createPair(wbtc.address, weth.address)
    await factory.createPair(wbtc.address, bnb.address)
    await factory.createPair(dot.address, usdt.address)
    await factory.createPair(dot.address, weth.address)
    await factory.createPair(usdt.address, weth.address)
    await factory.createPair(bnb.address, usdc.address)
    await factory.createPair(bnb.address, usdt.address)
    await factory.createPair(bnb.address, weth.address)
    const UniswapPair = await ethers.getContractFactory("UniswapV2Pair")

    pair = await factory.getPair(wbtc.address, dot.address)
    lpWBTCDOT = await UniswapPair.attach(pair)

    pair = await factory.getPair(dot.address, usdt.address)
    lpDOTUSDT = await UniswapPair.attach(pair)

    pair = await factory.getPair(wbtc.address, bnb.address)
    lpWBTCBNB = await UniswapPair.attach(pair)

    pair = await factory.getPair(wbtc.address, usdc.address)
    lpWBTCUSDC = await UniswapPair.attach(pair)

    pair = await factory.getPair(bnb.address, usdc.address)
    lpBNBUSDC = await UniswapPair.attach(pair)

    pair = await factory.getPair(wbtc.address, usdt.address)
    lpWBTCUSDT = await UniswapPair.attach(pair)

    pair = await factory.getPair(usdt.address, weth.address)
    lpWETHUSDT = await UniswapPair.attach(pair)

    pair = await factory.getPair(dot.address, weth.address)
    lpWETHDOT = await UniswapPair.attach(pair)

    pair = await factory.getPair(wbtc.address, weth.address)
    lpWBTCWETH = await UniswapPair.attach(pair)

    pair = await factory.getPair(bnb.address, weth.address)
    lpBNBWETH = await UniswapPair.attach(pair)
  }

  const addLiquidity = async (token0, token1, amount0, amount1) => {
    await token0.connect(bob).approve(router.address, amount0)
    await token1.connect(bob).approve(router.address, amount1)
    await router.connect(bob).addLiquidity(
      token0.address,
      token1.address,
      amount0,
      amount1,
      "0",
      "0",
      bob.address,
      FOREVER
    )
  }

  const initDexRouter = async () => {
    const WETH9 = await ethers.getContractFactory("WETH9")
    weth = await WETH9.deploy()
    await weth.connect(liquidity).deposit({ value: ethers.utils.parseEther("1000") })
    await weth.connect(liquidity).transfer(bob.address, ethers.utils.parseEther("1000"))
    await weth.connect(bob).deposit({ value: ethers.utils.parseEther("1000") })

    TokenApproveProxy = await ethers.getContractFactory("TokenApproveProxy")
    tokenApproveProxy = await TokenApproveProxy.deploy()
    await tokenApproveProxy.initialize()
    await tokenApproveProxy.deployed()

    TokenApprove = await ethers.getContractFactory("TokenApprove")
    tokenApprove = await TokenApprove.deploy()
    await tokenApprove.initialize(tokenApproveProxy.address)
    await tokenApprove.deployed()

    DexRouter = await ethers.getContractFactory("DexRouter")
    dexRouter = await upgrades.deployProxy(
      DexRouter
    )
    await dexRouter.deployed()
    await dexRouter.setApproveProxy(tokenApproveProxy.address)

    expect(await dexRouter._WETH()).to.be.equal(weth.address)
    expect(await dexRouter._APPROVE_PROXY_32()).to.be.equal(tokenApproveProxy.address)

    await tokenApproveProxy.addProxy(dexRouter.address)
    await tokenApproveProxy.setTokenApprove(tokenApprove.address)
  }

  const getTransactionCost = async (txResult) => {
    const cumulativeGasUsed = (await txResult.wait()).cumulativeGasUsed
    return BigNumber.from(txResult.gasPrice).mul(BigNumber.from(cumulativeGasUsed))
  }

  // fromTokenAmount * 997 * r0 / (r1 * 1000 + fromTokenAmount * 997)
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
})
