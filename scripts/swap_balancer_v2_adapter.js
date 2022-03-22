const { ethers } = require("hardhat");

async function main() {
  // Network Kovan

  const balancerV2AdapterAddr = "0xe361B183bC598b6b8B06333Ad8Adf2454A70A11F";

  balancerV2Adapter = await ethers.getContractAt(
    "BalancerV2Adapter",
    balancerV2AdapterAddr
  );

  toAddr = "0xe361B183bC598b6b8B06333Ad8Adf2454A70A11F";
  vaultAddr = "0xBA12222222228d8Ba445958a75a0704d566BF2C8";

  // LINK -> DAI is 2 token pool
  // r = await balancerV2Adapter.sellBase(
  //   toAddr,                                        // receive token address
  //   vaultAddr,                                     // balancer v2 vault address
  //   ethers.utils.defaultAbiCoder.encode(
  //     ["address", "address", "bytes32"],
  //     [
  //       "0xa36085F69e2889c224210F603D836748e7dC0088",  // from token address
  //       "0x04DF6e4121c27713ED22341E7c7Df330F56f289B",  // to token address
  //       "0x2291627599a7441d53c4645d7b12720026c336180002000000000000000003b4"  // pool id
  //     ]
  //   )
  // );

  // DAI -> WETH is 3 token pool vault
  r = await balancerV2Adapter.sellBase(
    toAddr,                                        // receive token address
    "0xBA12222222228d8Ba445958a75a0704d566BF2C8",  // balancer v2 vault address
    ethers.utils.defaultAbiCoder.encode(
      ["address", "address", "bytes32"],
      [
        "0x04DF6e4121c27713ED22341E7c7Df330F56f289B",  // from token address 
        "0xdFCeA9088c8A88A76FF74892C1457C17dfeef9C1",  // to token address
        "0x37a6fc079cad790e556baedda879358e076ef1b3000100000000000000000348"  // pool id
      ]
    )
  );
  console.log(r)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
