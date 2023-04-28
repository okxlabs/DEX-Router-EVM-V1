const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, startMockAccount, setBalance } = require("../../tools/chain");
// 2050-07-19 17:52:02
const DDL = 2541837122

async function deployContract() {
    IronswapAdapter = await ethers.getContractFactory("IronswapAdapter");
    IronswapAdapter = await IronswapAdapter.deploy();
    await IronswapAdapter.deployed();
    return IronswapAdapter
}



// compare tx: 0x2696b1f30b5262c341f75ab273f7ee2d1a41d1f98e74656da11f7d52a1b2477c
// network polygon

async function executeERC20ToERC20() {
    let tokenConfig = getConfig("polygon")

    await setForkNetWorkAndBlockNumber("polygon", 41935169 - 1);

    const IronswapAdapter = await deployContract();

    const accountSource = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x837503e8A8753ae17fB8C8151B8e6f586defCb57"


    const USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );

    const USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('100'));


    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('100'));

    await USDC.connect(accountS).transfer(
        account.address,
        ethers.BigNumber.from("1000")
    );

    console.log(
        "before USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "before USDC balance: " + (await USDC.balanceOf(account.address))
    );

    await USDC.connect(account).transfer(
        IronswapAdapter.address,
        ethers.BigNumber.from("1000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
            USDC.address,
            USDT.address
        ]
    );
    await IronswapAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "after USDC balance: " + (await USDC.balanceOf(account.address))
    );
}

async function main() {

    console.log("==== checking ERC20 to ERC20 ====== ")
    await executeERC20ToERC20();




}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
