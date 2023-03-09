const { ethers } = require("hardhat");
const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function main() {
    const PSMUSDCNetwork = "0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A";
    const PSMGUSDNetwork = "0x204659B2Fd2aD5723975c362Ce2230Fba11d3900";
    const PSMUSDPNetwork = "0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf";
    const USDC = tokenConfig.tokens.USDC.baseTokenAddress;
    const GUSD = tokenConfig.tokens.GUSD.baseTokenAddress;
    const USDP = tokenConfig.tokens.USDP.baseTokenAddress;
    const DAI = tokenConfig.tokens.DAI.baseTokenAddress;

    PSMAdapter = await ethers.getContractFactory("PSMAdapter");
    psmAdapter = await PSMAdapter.deploy(PSMUSDCNetwork, PSMGUSDNetwork, PSMUSDPNetwork, USDC, GUSD, USDP, DAI);
    await psmAdapter.deployed();

    console.log(`psmAdapter deployed: ${psmAdapter.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
