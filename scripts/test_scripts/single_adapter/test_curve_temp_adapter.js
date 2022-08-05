const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth");


async function main() {
    const MockCurvePool = await ethers.getContractAt("MockCurvePool", "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7");
    
    
    await MockCurvePool.debugMessgage();
    // const result = await MockCurvePool.calc_token_amount([100000000000000000000000,0,0], true);
    // console.log(result);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
