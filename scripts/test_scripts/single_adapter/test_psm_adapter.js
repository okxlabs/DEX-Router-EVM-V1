const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

async function execute() {

    // Network Main
    await setForkBlockNumber(16069291);

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

    const PSMNetwork = "0x89B78CfA322F6C5dE0aBcEecab66Aee45393cC5A";

    PSMAdapter = await ethers.getContractFactory("PSMAdapter");
    psmAdapter = await PSMAdapter.deploy(PSMNetwork, tokenConfig.tokens.USDC.baseTokenAddress, tokenConfig.tokens.DAI.baseTokenAddress);
    await psmAdapter.deployed();

    console.log(`psmAdapter deployed: ${psmAdapter.address}`);

    await DAI.connect(account).transfer(psmAdapter.address, '3511833240000000000000000');
    console.log("before DAI Balance: " + await DAI.balanceOf(psmAdapter.address));
    console.log("before USDC Balance: " + await USDC.balanceOf(psmAdapter.address));

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            tokenConfig.tokens.DAI.baseTokenAddress,
            tokenConfig.tokens.USDC.baseTokenAddress
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

    await ethers.provider.send('evm_increaseTime', [10]);
    await ethers.provider.send('evm_mine');

    console.log("before DAI Balance: " + await DAI.balanceOf(psmAdapter.address));
    console.log("before USDC Balance: " + await USDC.balanceOf(psmAdapter.address));

    moreinfo2 =  ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
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
