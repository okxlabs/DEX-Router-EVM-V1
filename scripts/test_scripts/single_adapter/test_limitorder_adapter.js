const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");

async function execute() {

    // Network Main
    await setForkBlockNumber(16230174);

    const tokenConfig = getConfig("eth");

    const accountAddress = "0x56178a0d5F301bAf6CF3e1Cd53d9863437345Bf9";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )
    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    const aggV5Addr = "0x1111111254eeb25477b68fb85ed929f73a960582";

    LimitAdapter = await ethers.getContractFactory("LimitOrderAdapter");
    limitAdapter = await LimitAdapter.deploy(aggV5Addr);
    await limitAdapter.deployed();

    console.log(`limitAdapter deployed: ${limitAdapter.address}`);

    await WETH.connect(account).transfer(limitAdapter.address, '2000000000000000');
    console.log("before WETH Balance: " + await WETH.balanceOf(limitAdapter.address));
    console.log("before USDC Balance: " + await USDC.balanceOf(limitAdapter.address));

    moreinfo =  ethers.utils.defaultAbiCoder.encode(
        ["tuple(uint256, address, address, address, address, address, uint256, uint256, uint256, bytes)", "bytes", "uint256","uint256"],
        [
            [
                "128790960776",
                "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
                "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
                "0x819Dcc3C4f25463d879249828BF4f700201cCBfb",
                "0x8290dBccb15b5A516dEEE2805C58e56075d6605E",
                "0x0000000000000000000000000000000000000000",
                "200000000",
                "154320000000000000",
                "12078056109444544136644881178716611325260305918824174400514173937123328",
                "0xbf15fcd8000000000000000000000000303389f541ff2d620e42832f180a08e767b28e10000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000242cc2878d0063a3139e00000000000000819dcc3c4f25463d879249828bf4f700201ccbfb00000000000000000000000000000000000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000819dcc3c4f25463d879249828bf4f700201ccbfb0000000000000000000000001111111254eeb25477b68fb85ed929f73a960582ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000000000000000000000000000000000000000000000000000000063a31399000000000000000000000000000000000000000000000000000000000000001c58dff824e26f7b00ed6d2a0d019b219bd8cf733f453ee8e0a4cb73820d9d8e3f1fa3de10c12ddc4d7ec5829772ef1a526e63f7a508ac71243660d6bcb3cae5068290dbccb15b5a516deee2805c58e56075d6605e819dcc3c4f25463d879249828bf4f700201ccbfb"
            ],
            "0x419b8ffc0e0dcd8f81e3b6a4899e432469774202c893388c7bffc44f3fa1bf332488fbbaff4e098b6e580e36e442d46199d579274afd4b72862b2b42b9a026e71c",
            "57896044618658097711785492504343953926634992332820282019728792003956567399023",
            "2592016"
        ]
    )

    rxResult = await limitAdapter.sellQuote(
        limitAdapter.address,
        limitAdapter.address,
        moreinfo
    );
    console.log(rxResult);

    console.log("after WETH Balance: " + await WETH.balanceOf(limitAdapter.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(limitAdapter.address));
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
