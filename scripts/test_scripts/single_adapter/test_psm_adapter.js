const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

async function execute() {

    // Network Main
    await setForkBlockNumber(16780761);

    const tokenConfig = getConfig("eth");

    const accountAddress = "0x56178a0d5f301baf6cf3e1cd53d9863437345bf9";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    )
    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )
    //GUSD = await ethers.getContractAt(
    //    "MockERC20",
    //    tokenConfig.tokens.GUSD.baseTokenAddress
    //)
    //USDP = await ethers.getContractAt(
    //    "MockERC20",
    //   tokenConfig.tokens.USDP.baseTokenAddress
    //)

    const PSMUSDCNetwork = "0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A";
    const PSMGUSDNetwork = "0x204659B2Fd2aD5723975c362Ce2230Fba11d3900";
    const PSMUSDPNetwork = "0x961Ae24a1Ceba861D1FDf723794f6024Dc5485Cf";

    PSMAdapter = await ethers.getContractFactory("PSMAdapter");
    psmAdapter = await PSMAdapter.deploy(PSMUSDCNetwork, PSMGUSDNetwork, PSMUSDPNetwork, tokenConfig.tokens.USDC.baseTokenAddress, tokenConfig.tokens.GUSD.baseTokenAddress, tokenConfig.tokens.USDP.baseTokenAddress, tokenConfig.tokens.DAI.baseTokenAddress);
    await psmAdapter.deployed();

    console.log(`psmAdapter deployed: ${psmAdapter.address}`);

    await DAI.connect(account).transfer(psmAdapter.address, '1234000000000000000000');
    console.log("before DAI Balance: " + await DAI.balanceOf(psmAdapter.address));
    console.log("before USDC Balance: " + await USDC.balanceOf(psmAdapter.address));
    //console.log("before GUSD Balance: " + await GUSD.balanceOf(psmAdapter.address));
    //console.log("before USDP Balance: " + await USDP.balanceOf(psmAdapter.address));

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            tokenConfig.tokens.DAI.baseTokenAddress,
            tokenConfig.tokens.USDC.baseTokenAddress
            //tokenConfig.tokens.GUSD.baseTokenAddress
            //tokenConfig.tokens.USDP.baseTokenAddress
        ]
    )

    rxResult = await psmAdapter.sellQuote(
        psmAdapter.address,
        psmAdapter.address,
        moreinfo
    );
    // console.log(rxResult);

    console.log("after DAI Balance: " + await DAI.balanceOf(psmAdapter.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(psmAdapter.address));
    //console.log("after GUSD Balance: " + await GUSD.balanceOf(psmAdapter.address));
    //console.log("after USDP Balance: " + await USDP.balanceOf(psmAdapter.address));

    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine');

    console.log("before DAI Balance: " + await DAI.balanceOf(psmAdapter.address));
    console.log("before USDC Balance: " + await USDC.balanceOf(psmAdapter.address));
    //console.log("before GUSD Balance: " + await GUSD.balanceOf(psmAdapter.address));
    //console.log("before USDP Balance: " + await USDP.balanceOf(psmAdapter.address));

    moreinfo2 =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            //tokenConfig.tokens.GUSD.baseTokenAddress,
            //tokenConfig.tokens.USDP.baseTokenAddress,
            tokenConfig.tokens.USDC.baseTokenAddress,
            tokenConfig.tokens.DAI.baseTokenAddress
        ]
    )

    rxResult = await psmAdapter.sellBase(
        psmAdapter.address,
        psmAdapter.address,
        moreinfo2
    );
    // console.log(rxResult);
    console.log("after DAI Balance: " + await DAI.balanceOf(psmAdapter.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(psmAdapter.address));
    //console.log("after GUSD Balance: " + await GUSD.balanceOf(psmAdapter.address));
    //console.log("after USDP Balance: " + await USDP.balanceOf(psmAdapter.address));
}

async function main() {
    await execute();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
