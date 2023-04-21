const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, startMockAccount, setBalance } = require("../../tools/chain");
// 2050-07-19 17:52:02
const DDL = 2541837122

async function deployContract() {
  SynapseAdapter = await ethers.getContractFactory("SynapseAdapter");
  SynapseAdapter = await SynapseAdapter.deploy();
  await SynapseAdapter.deployed();
  return SynapseAdapter
}
// only 2 pools on AVAX: avETH_nETH pool, nUSD_USDC_USDT_DAI pool


// pool: avETH_nETH  0xE27BFf97CE92C3e1Ff7AA9f86781FDd6D48F5eE9
// compare tx:
// https://openchain.xyz/trace/avalanche/0x8ceebc587e9984672951078c4c25ef6d963c765c12a62f53ae25ef7a4eeb06ab
// network AVAX

async function executeTwoCryto_avax() {
  let tokenConfig = getConfig("avax")

  await setForkNetWorkAndBlockNumber("avax", 28943877 - 1);
  const SynapseAdapter = await deployContract()

  const bridgeAddr = "0xc05e61d0e7a63d27546389b7ad62fdff5a91aace" // it is a bridge address, which contains lots of nUSD
  const accountAddr = "0x1000000000000000000000000000000000000000" // it is an empty addr
  const poolAddr = "0x77a7e60555bC18B4Be44C181b2575eee46212d44"

  await startMockAccount([bridgeAddr])
  const bridge = await ethers.getSigner(bridgeAddr)
  await setBalance(bridgeAddr, ethers.utils.parseEther('1'))


  const nETH = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.nETH.baseTokenAddress
  );

  const avETH = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.avETH.baseTokenAddress
  );

  await nETH.connect(bridge).transfer(
    accountAddr,
    ethers.BigNumber.from("1658718422835266934") //0.4903 ether
  );


  await startMockAccount([accountAddr])
  const account = await ethers.getSigner(accountAddr)
  // 1. set ETH balance to avoid balance insufficient error
  await setBalance(accountAddr, ethers.utils.parseEther('1'));

  console.log(
    "before avETH balance: " + (await avETH.balanceOf(account.address))
  );
  console.log(
    "before nETH balance: " + (await nETH.balanceOf(account.address))
  );
  // 2. transfer avETH to adapter addr
  await nETH.connect(account).transfer(
    SynapseAdapter.address,
    ethers.BigNumber.from("1658718422835266934") //0.4903 ether
  );

  let moreInfo = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256"],
    [
      nETH.address,
      avETH.address,
      DDL
    ]
  );
  // 4. call adapter sellQuote func. it is the same as sellBase, since Index is queryed on chain.
  await SynapseAdapter.sellQuote(
    account.address,
    poolAddr,
    moreInfo
  );

  console.log(
    "after avETH balance: " + (await avETH.balanceOf(account.address))
  );
  console.log(
    "after nETH balance: " + (await nETH.balanceOf(account.address)) //expected: 1658920214014726668
  );
}
// pool: nUSD_USDT_USDC_DAI
// tx: https://openchain.xyz/trace/avalanche/0x5ff48f104b8306493f52c413e36990ca271e5b9efe970d182a1f46b75d21fe88
// poolAddr: 0xED2a7edd7413021d440b09D654f3b87712abAB66
async function executeFourCryto_avax() {
  let tokenConfig = getConfig("avax")

  await setForkNetWorkAndBlockNumber("avax", 28947615 - 1);
  const SynapseAdapter = await deployContract()

  const bridgeAddr = "0xc05e61d0e7a63d27546389b7ad62fdff5a91aace" // it is a bridge address, which contains lots of nUSD
  const accountAddr = "0x1000000000000000000000000000000000000000" // it is an empty addr
  const poolAddr = "0xED2a7edd7413021d440b09D654f3b87712abAB66"

  await startMockAccount([bridgeAddr])
  const bridge = await ethers.getSigner(bridgeAddr)
  await setBalance(bridgeAddr, ethers.utils.parseEther('1'))


  const nUSD = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.nUSD.baseTokenAddress
  );

  const USDC_e = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.USDC_e.baseTokenAddress
  );

  await nUSD.connect(bridge).transfer(
    accountAddr,
    ethers.BigNumber.from("552058317664969956326")
  );


  await startMockAccount([accountAddr])
  const account = await ethers.getSigner(accountAddr)
  // 1. set ETH balance to avoid balance insufficient error
  await setBalance(accountAddr, ethers.utils.parseEther('1'));

  console.log(
    "before USDC_e balance: " + (await USDC_e.balanceOf(account.address))
  );
  console.log(
    "before nUSD balance: " + (await nUSD.balanceOf(account.address))
  );
  // 2. transfer nUSD to adapter addr
  await nUSD.connect(account).transfer(
    SynapseAdapter.address,
    ethers.BigNumber.from("552058317664969956326")
  );

  let moreInfo = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256"],
    [
      nUSD.address,
      USDC_e.address,
      DDL
    ]
  );
  // 4. call adapter sellQuote func. it is the same as sellBase, since Index is queryed on chain.
  await SynapseAdapter.sellBase(
    account.address,
    poolAddr,
    moreInfo
  );

  console.log(
    "after USDC_e balance: " + (await USDC_e.balanceOf(account.address))
  );
  console.log(
    "after nUSD balance: " + (await nUSD.balanceOf(account.address)) //expected: 553252162
  );
}

// tx: https://openchain.xyz/trace/avalanche/0x1989bd63514507fb0e69e94761a99fab6334b55de029516646b4055ebee3ccd7
// swap nETH for WETH.e, which will first swap nETH for avETH, then withdraw avETH to WETH.e

// according to the following issue, it is a bug for hardhat because hardhat forking will not change the chainId. and we dont have a way to alter it.
// so take the workaround here for the SynapseAdapter, because it has a chainId requirement.
// https://github.com/NomicFoundation/hardhat/issues/2305
// if u want to the following A2B, B2A edge case test, it is suggest to modify the hardhat.config.js, under the networks.hardhat.chainId from 31337 to 43114
async function executeEdgecaseA2B_avax() {
  let tokenConfig = getConfig("avax")
  hre.network.config.chainId = 43114
  console.log()
  await setForkNetWorkAndBlockNumber("avax", 28973514 - 1);

  console.log(await hre.network.provider.request({
    method: "eth_chainId"
  }))
  const SynapseAdapter = await deployContract()

  const accountAddr = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f" // it is an empty addr
  const poolAddr = "0x77a7e60555bC18B4Be44C181b2575eee46212d44"

  const nETH = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.nETH.baseTokenAddress
  );

  const avETH = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.avETH.baseTokenAddress
  );

  const WETH_e = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.WETH_e.baseTokenAddress
  );

  await startMockAccount([accountAddr])
  const account = await ethers.getSigner(accountAddr)
  // 1. set ETH balance to avoid balance insufficient error
  await setBalance(accountAddr, ethers.utils.parseEther('1'));

  console.log(
    "before WETH_e balance: " + (await WETH_e.balanceOf(account.address))
  );
  console.log(
    "before nETH balance: " + (await nETH.balanceOf(account.address))
  );

  await nETH.connect(account).transfer(
    SynapseAdapter.address,
    ethers.BigNumber.from("998021822202497") //0.4903 ether
  );

  let moreInfo = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256"],
    [
      nETH.address,
      WETH_e.address,
      DDL
    ]
  );
  // console.log(moreInfo)
  // 4. call adapter sellQuote func. it is the same as sellBase, since Index is queryed on chain.
  await SynapseAdapter.sellQuote(
    account.address,
    poolAddr,
    moreInfo
  );

  console.log(
    "after WETH_e balance: " + (await WETH_e.balanceOf(account.address))
  );
  console.log(
    "after nETH balance: " + (await nETH.balanceOf(account.address)) //expected: 1658920214014726668
  );
}

// tx: https://openchain.xyz/trace/avalanche/0x5a30286b0384b13896d3b9e76b8a542d97c99201c4a18e2dfadc1836643be792
// swap WETH.e for nETH
// modify the hardhat.config.js,  under the networks.hardhat.chainId from 31337 to 43114
async function executeEdgecaseB2A_avax() {
  let tokenConfig = getConfig("avax")
  hre.network.config.chainId = 43114

  await setForkNetWorkAndBlockNumber("avax", 28977118 - 1);

  console.log(await hre.network.provider.request({
    method: "eth_chainId"
  }))
  const SynapseAdapter = await deployContract()

  const accountAddr = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f"
  const poolAddr = "0x77a7e60555bC18B4Be44C181b2575eee46212d44"

  const nETH = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.nETH.baseTokenAddress
  );

  const avETH = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.avETH.baseTokenAddress
  );

  const WETH_e = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.WETH_e.baseTokenAddress
  );

  await startMockAccount([accountAddr])
  const account = await ethers.getSigner(accountAddr)
  // 1. set ETH balance to avoid balance insufficient error
  await setBalance(accountAddr, ethers.utils.parseEther('1'));

  console.log(
    "before WETH_e balance: " + (await WETH_e.balanceOf(account.address))
  );
  console.log(
    "before nETH balance: " + (await nETH.balanceOf(account.address))
  );

  await WETH_e.connect(account).transfer(
    SynapseAdapter.address,
    ethers.BigNumber.from("998136053535787") //0.4903 ether
  );

  let moreInfo = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256"],
    [
      WETH_e.address,
      nETH.address,
      DDL
    ]
  );
  // console.log(moreInfo)
  // 4. call adapter sellQuote func. it is the same as sellBase, since Index is queryed on chain.
  await SynapseAdapter.sellQuote(
    account.address,
    poolAddr,
    moreInfo
  );

  console.log(
    "after WETH_e balance: " + (await WETH_e.balanceOf(account.address))
  );
  console.log(
    "after nETH balance: " + (await nETH.balanceOf(account.address)) //expected: 1658920214014726668
  );
}


// pool: WETH_nETH  0xE27BFf97CE92C3e1Ff7AA9f86781FDd6D48F5eE9
// compare tx:
// https://openchain.xyz/trace/optimism/0x1b195ebea3cd529458eb65c64df835f667c45453c82b25cf4648fb8b866cb3e7
// network OP

// As Synapse.finance only has two pools, namely WETH_nETH and USDC_nUSD, which belong to the same category, there is no need for further investigation.

async function executeTwoCryto_op() {
  let tokenConfig = getConfig("op")

  await setForkNetWorkAndBlockNumber("op", 92137548 - 1);
  const SynapseAdapter = await deployContract()

  const accountAddr = "0x6dD91BdaB368282dc4Ea4f4beFc831b78a7C38C0"
  const poolAddr = "0xE27BFf97CE92C3e1Ff7AA9f86781FDd6D48F5eE9"

  await startMockAccount([accountAddr])
  const account = await ethers.getSigner(accountAddr)
  // 1. set ETH balance to avoid balance insufficient error
  await setBalance(accountAddr, ethers.utils.parseEther('1'));


  const nETH = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.nETH.baseTokenAddress
  );

  const WETH = await ethers.getContractAt(
    "WETH9",
    tokenConfig.tokens.WETH_SYNAPSE.baseTokenAddress
  );
  // 2. deposit ETH to mint WETH
  await WETH.connect(account).deposit(
    { value: ethers.BigNumber.from("490300000000000000") }
  );

  console.log(
    "before WETH balance: " + (await WETH.balanceOf(account.address))
  );
  console.log(
    "before nETH balance: " + (await nETH.balanceOf(account.address))
  );
  // 3. transfer WETH to adapter addr
  await WETH.connect(account).transfer(
    SynapseAdapter.address,
    ethers.BigNumber.from("490300000000000000") //0.4903 ether
  );

  let moreInfo = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256"],
    [
      WETH.address,
      nETH.address,
      DDL
    ]
  );
  // 4. call adapter sellQuote func. it is the same as sellBase, since Index is queryed on chain.
  await SynapseAdapter.sellQuote(
    account.address,
    poolAddr,
    moreInfo
  );

  console.log(
    "after WETH balance: " + (await WETH.balanceOf(account.address))
  );
  console.log(
    "after nETH balance: " + (await nETH.balanceOf(account.address)) //expected: 490087092059470272
  );
}

// total 3 pools on the arbi chain: nETH_WETH, nUSD_USDC_USDT, nUSD_MIM_USDC_USDT

// pool: WETH_nETH
// tx: https://openchain.xyz/trace/arbitrum/0x55881fa95bda7cf975bf9460dcb38b798fa4d65f71e63d0c8fa868ce78da60ed
// network: arbi
async function executeTwoCryto_arbi() {
  let tokenConfig = getConfig("arbitrum")

  await setForkNetWorkAndBlockNumber("arbitrum", 68895639 - 1);
  const SynapseAdapter = await deployContract()

  const accountRaw = "0x1026Df41A10BB5057D4F08261d907893f2D5F78B" // this addr has nETH inside
  const accountAddr = "0x1000000000000000000000000000000000000000" // it is an empty addr
  const poolAddr = "0xa067668661C84476aFcDc6fA5D758C4c01C34352"

  const nETH = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.nETH.baseTokenAddress
  );

  const WETH = await ethers.getContractAt(
    "WETH9",
    tokenConfig.tokens.WETH.baseTokenAddress
  );
  await startMockAccount([accountRaw])
  const accountR = await ethers.getSigner(accountRaw)
  // 1. set ETH balance to avoid balance insufficient error
  await setBalance(accountRaw, ethers.utils.parseEther('1'));

  await nETH.connect(accountR).transfer(
    accountAddr,
    ethers.BigNumber.from("118163140643853259")
  );

  await startMockAccount([accountAddr])
  const account = await ethers.getSigner(accountAddr)
  // 1. set ETH balance to avoid balance insufficient error
  await setBalance(accountAddr, ethers.utils.parseEther('1'));

  console.log(
    "before WETH balance: " + (await WETH.balanceOf(account.address))
  );
  console.log(
    "before nETH balance: " + (await nETH.balanceOf(account.address))
  );

  await nETH.connect(account).transfer(
    SynapseAdapter.address,
    ethers.BigNumber.from("118163140643853259")
  );

  let moreInfo = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256"],
    [
      nETH.address,
      WETH.address,
      DDL
    ]
  );
  // 4. call adapter sellQuote func. it is the same as sellBase, since Index is queryed on chain.
  await SynapseAdapter.sellQuote(
    account.address,
    poolAddr,
    moreInfo
  );

  console.log(
    "after WETH balance: " + (await WETH.balanceOf(account.address))
  );
  console.log(
    "after nETH balance: " + (await nETH.balanceOf(account.address)) //expected: 118219344071927401
  );
}
// pool: 0x9Dd329F5411466d9e0C488fF72519CA9fEf0cb40
// tx: https://openchain.xyz/trace/arbitrum/0x9b07d7552c9825d3d2ac4df696ab41c26a060884fdf52f9c09942043f2f6460d
// nUSD_USDC_USDT 
async function executeThreeCryto_arbi() {
  let tokenConfig = getConfig("arbitrum")

  await setForkNetWorkAndBlockNumber("arbitrum", 82097084 - 1);
  const SynapseAdapter = await deployContract()

  const accountRaw = "0x6F4e8eBa4D337f874Ab57478AcC2Cb5BACdc19c9" // this addr has nUSD inside
  const accountAddr = "0x1000000000000000000000000000000000000000" // it is an empty addr
  const poolAddr = "0x9Dd329F5411466d9e0C488fF72519CA9fEf0cb40"

  const nUSD = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.nUSD.baseTokenAddress
  );

  const USDC = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.USDC.baseTokenAddress
  );
  await startMockAccount([accountRaw])
  const accountR = await ethers.getSigner(accountRaw)
  // 1. set ETH balance to avoid balance insufficient error
  await setBalance(accountRaw, ethers.utils.parseEther('1'));

  await nUSD.connect(accountR).transfer(
    accountAddr,
    ethers.BigNumber.from("200757493703729848679")
  );

  await startMockAccount([accountAddr])
  const account = await ethers.getSigner(accountAddr)
  // 1. set ETH balance to avoid balance insufficient error
  await setBalance(accountAddr, ethers.utils.parseEther('1'));

  console.log(
    "before USDC balance: " + (await USDC.balanceOf(account.address))
  );
  console.log(
    "before nUSD balance: " + (await nUSD.balanceOf(account.address))
  );

  await nUSD.connect(account).transfer(
    SynapseAdapter.address,
    ethers.BigNumber.from("200757493703729848679")
  );

  let moreInfo = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256"],
    [
      nUSD.address,
      USDC.address,
      DDL
    ]
  );
  // 4. call adapter sellQuote func. it is the same as sellBase, since Index is queryed on chain.
  await SynapseAdapter.sellQuote(
    account.address,
    poolAddr,
    moreInfo
  );

  console.log(
    "after USDC balance: " + (await USDC.balanceOf(account.address))
  );
  console.log(
    "after nUSD balance: " + (await nUSD.balanceOf(account.address))
  );
}
// pool: nUSD_MIN_USDC_USDT
// tx: https://explorer.phalcon.xyz/tx/arbitrum/0x9d1f0bf913a713adfdbc907769c3021c1959ae70abac8d08d88acf4f2f93b412
async function executeFourCryto_arbi() {
  let tokenConfig = getConfig("arbitrum")

  await setForkNetWorkAndBlockNumber("arbitrum", 72082470 - 1);
  const SynapseAdapter = await deployContract()

  const accountRaw = "0xb6cfcf89a7b22988bfc96632ac2a9d6dab60d641" // this addr has USDT inside
  const accountAddr = "0x1000000000000000000000000000000000000000" // it is an empty addr
  const poolAddr = "0x0Db3FE3B770c95A0B99D1Ed6F2627933466c0Dd8"

  const USDT = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.USDT.baseTokenAddress
  );

  const USDC = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.USDC.baseTokenAddress
  );
  await startMockAccount([accountRaw])
  const accountR = await ethers.getSigner(accountRaw)
  // 1. set ETH balance to avoid balance insufficient error
  await setBalance(accountRaw, ethers.utils.parseEther('1'));

  await USDT.connect(accountR).transfer(
    accountAddr,
    ethers.BigNumber.from("1090813901")
  );

  await startMockAccount([accountAddr])
  const account = await ethers.getSigner(accountAddr)
  // 1. set ETH balance to avoid balance insufficient error
  await setBalance(accountAddr, ethers.utils.parseEther('1'));

  console.log(
    "before USDC balance: " + (await USDC.balanceOf(account.address))
  );
  console.log(
    "before USDT balance: " + (await USDT.balanceOf(account.address))
  );

  await USDT.connect(account).transfer(
    SynapseAdapter.address,
    ethers.BigNumber.from("1090813901")
  );

  let moreInfo = ethers.utils.defaultAbiCoder.encode(
    ["address", "address", "uint256"],
    [
      USDT.address,
      USDC.address,
      DDL
    ]
  );
  // 4. call adapter sellQuote func. it is the same as sellBase, since Index is queryed on chain.
  await SynapseAdapter.sellQuote(
    account.address,
    poolAddr,
    moreInfo
  );

  console.log(
    "after USDC balance: " + (await USDC.balanceOf(account.address))
  );
  console.log(
    "after USDT balance: " + (await USDT.balanceOf(account.address)) //expected: 118219344071927401
  );
}

async function main() {

  console.log("==== checking avax TwoCrypto ====== ")
  await executeTwoCryto_avax();

  console.log("==== checking avax FourCrypto ====== ")
  await executeFourCryto_avax();

  // console.log("==== checking avax EdgeCase swap nETH to WETH_e ====== ")
  // await executeEdgecaseA2B_avax();

  // console.log("==== checking avax EdgeCase swap WETH_e to nETH ====== ")
  // await executeEdgecaseB2A_avax();

  console.log("==== checking op TwoCrypto ====== ")
  await executeTwoCryto_op();

  console.log("==== checking arbi TwoCrypto ====== ")
  await executeTwoCryto_arbi();

  console.log("==== checking arbi ThreeCrypto ====== ")
  await executeThreeCryto_arbi();

  console.log("==== checking arbi FourCrypto ====== ")
  await executeFourCryto_arbi();




}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
