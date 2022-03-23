const { ethers } = require("hardhat");
require("./utils");

async function executeDAI2WETH() {
  // Network Main
  // tx at 14436484 
  await setForkBlockNumber(14436483);

  const accountAddress = "0x260edfea92898a3c918a80212e937e6033f8489e"
  await impersonateAccount([accountAddress]);
  const account = await ethers.getSigner(accountAddress)

  // set account balance 0.6 eth
  await setBalance(accountAddress, "0x53444835ec580000");

  BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
  balancerV2Adapter = await BalancerV2Adapter.deploy();
  await balancerV2Adapter.deployed();

  WETH = await ethers.getContractAt(
    "MockERC20",
    "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
  )
  IPAL = await ethers.getContractAt(
    "MockERC20",
    "0x12E457a5FC7707d0FDDA849068DF6e664d7a8569"
  )

  balancerVault = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";

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

async function main() {
  await executeDAI2WETH();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
