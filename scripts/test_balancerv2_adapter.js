const { config } = require("dotenv");
const { ethers } = require("hardhat");
require("./tools");
const { getConfig } = require("./config");
tokenConfig = getConfig("eth");

async function executeWETH2IPAL() {
  // Network Main
  // tx at 14436484 
  await setForkBlockNumber(14436483);

  const accountAddress = "0x260edfea92898a3c918a80212e937e6033f8489e";
  await startMockAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress);

  // set account balance 0.6 eth
  await setBalance(accountAddress, "0x53444835ec580000");

  WETH = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.WETH.baseTokenAddress
  )
  IPAL = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.IPAL.baseTokenAddress
  )

  const balancerVault = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";
  
  BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
  balancerV2Adapter = await BalancerV2Adapter.deploy(balancerVault ,WETH.address);
  await balancerV2Adapter.deployed();

  // transfer 100 WETH to bancorAdapter
  await WETH.connect(account).transfer(balancerV2Adapter.address, ethers.utils.parseEther('3.5'));

  console.log("before WETH Balance: " + await WETH.balanceOf(balancerV2Adapter.address));
  console.log("before IPAL Balance: " + await IPAL.balanceOf(account.address));

  // WETH to LPAL token pool vault
  rxResult = await balancerV2Adapter.sellBase(
    account.address,                                // receive token address
    balancerVault,                                  // balancer v2 vault address
    ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "bytes32"],
      [
        WETH.address,                               // from token address 
        IPAL.address,                               // to token address
        "0x54b7d8cbb8057c5990ed5a7a94febee61d6b583700020000000000000000016f"  // pool id
      ]
    )
  );
  // console.log(rxResult);

  console.log("after WETH Balance: " + await WETH.balanceOf(balancerV2Adapter.address));
  console.log("after IPAL Balance: " + await IPAL.balanceOf(account.address));
}

async function executeETH2DAI() {
  // Network Main
  // tx at 14436484 
  await setForkBlockNumber(14436483);

  const accountAddress = "0x260edfea92898a3c918a80212e937e6033f8489e"
  await startMockAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress)

  // set account balance 0.6 eth
  await setBalance(accountAddress, "0x53444835ec580000");

  WETH = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.WETH.baseTokenAddress
  )
  DAI = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.DAI.baseTokenAddress
  )
  
  const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
  const balancerVault = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";

  BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
  balancerV2Adapter = await BalancerV2Adapter.deploy(balancerVault, WETH.address);
  await balancerV2Adapter.deployed();

  // transfer 100 WETH to bancorAdapter
  await WETH.connect(account).transfer(balancerV2Adapter.address, ethers.utils.parseEther('3.5'));

  console.log("before WETH Balance: " + await WETH.balanceOf(balancerV2Adapter.address));
  console.log("before DAI Balance: " + await DAI.balanceOf(account.address));

  // WETH to LPAL token pool vault
  rxResult = await balancerV2Adapter.sellBase(
    account.address,                                // receive token address
    balancerVault,                                  // balancer v2 vault address
    ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "bytes32"],
      [
        ETH.address,                                // from token address 
        DAI.address,                                // to token address
        "0x0b09dea16768f0799065c475be02919503cb2a3500020000000000000000001a"  // pool id
      ]
    )
  );
  // console.log(rxResult);

  console.log("after WETH Balance: " + await WETH.balanceOf(balancerV2Adapter.address));
  console.log("after DAI Balance: " + await DAI.balanceOf(account.address));
}

async function executeDAI2ETH() {
  // Network Main
  // tx at 14436484 
  await setForkBlockNumber(14436483);

  const accountAddress = "0x260edfea92898a3c918a80212e937e6033f8489e"
  await startMockAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress)

  // set account balance 0.6 eth
  await setBalance(accountAddress, "0x53444835ec580000");

  WETH = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.WETH.baseTokenAddress
  )
  DAI = await ethers.getContractAt(
    "MockERC20",
    tokenConfig.tokens.DAI.baseTokenAddress
  )
  const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
  const balancerVault = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";

  BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
  balancerV2Adapter = await BalancerV2Adapter.deploy(balancerVault ,WETH.address);
  await balancerV2Adapter.deployed();
  
  // mock DAI holder
  const daiHolderAddr = "0x28C6c06298d514Db089934071355E5743bf21d60"
  startMockAccount([daiHolderAddr])
  const daiHolder = await ethers.getSigner(daiHolderAddr)

  // transfer 100 DAI to balancerV2Adapter
  await DAI.connect(daiHolder).transfer(balancerV2Adapter.address, ethers.utils.parseEther('100'));

  console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
  console.log("before DAI Balance: " + await DAI.balanceOf(balancerV2Adapter.address));

  // DAI to ETH token pool vault
  rxResult = await balancerV2Adapter.sellBase(
    account.address,                                // receive token address
    balancerVault,                                  // balancer v2 vault address
    ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "bytes32"],
      [
        DAI.address,                                // from token address 
        ETH.address,                                // to token address
        "0x0b09dea16768f0799065c475be02919503cb2a3500020000000000000000001a"  // pool id
      ]
    )
  );
  // console.log(rxResult);

  console.log("after WETH Balance: " + await WETH.balanceOf(account.address));
  console.log("after DAI Balance: " + await DAI.balanceOf(balancerV2Adapter.address));
}

async function main() {
  // ERC20 -> ERC20
  await executeWETH2IPAL();

  // WETH -> ETH -> ERC20
  await executeETH2DAI();

  // ERC20 -> ETH -> WETH
  await executeDAI2ETH();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
