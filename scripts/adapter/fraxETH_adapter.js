
const { ethers, upgrades } = require("hardhat");

async function main() {
    fraxETHAdapter = await ethers.getContractFactory("fraxETHAdapter");
    fraxETHAdapter = await fraxETHAdapter.deploy(
      "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", //WETH
      "0xbAFA44EFE7901E04E39Dad13167D089C559c1138", //frxETHMinter
      "0xac3E018457B222d93114458476f3E3416Abbe38F", //sfrxETH
      "0x5E8422345238F34275888049021821E8E08CAa1f" //frxETH
    );
    await fraxETHAdapter.deployed();
    console.log("fraxETHAdapter: ", fraxETHAdapter.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
