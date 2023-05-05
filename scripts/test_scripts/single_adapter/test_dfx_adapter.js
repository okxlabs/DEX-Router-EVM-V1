const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, startMockAccount, setBalance } = require("../../tools/chain");
// 2050-07-19 17:52:02
const DDL = 2541837122

async function deployContract() {

    ShellAdapter = await ethers.getContractFactory("ShellAdapter");
    ShellAdapter = await ShellAdapter.deploy();
    await ShellAdapter.deployed();
    return ShellAdapter
}




// https://polygonscan.com/tx/0x1ee14eccbb46c2ff1b65d39e93532b627e4fa47203cd9c3a7bff44b603185803

async function executeERC20ToERC20() {
    let tokenConfig = getConfig("polygon")

    await setForkNetWorkAndBlockNumber("polygon", 42287944 - 1);

    const ShellAdapter = await deployContract();

    const accountSource = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f"
    const accountAddr = "0x1000000000000000000001000000000000000000"
    const poolAddr = "0xAAb708fBd208Ac262821E229ded16234277b2B13"
    const trybAddr = "0x4Fb71290Ac171E1d144F7221D882BECAc7196EB5"



    const USDC = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.USDC.baseTokenAddress
    );

    const TRYB = await ethers.getContractAt(
        "MockERC20",
        trybAddr
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await USDC.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("1000000")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before TRYB balance: " + (await TRYB.balanceOf(account.address))
    );
    console.log(
        "before USDC balance: " + (await USDC.balanceOf(account.address))
    );

    await USDC.connect(account).transfer(
        ShellAdapter.address,
        ethers.BigNumber.from("1000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            USDC.address,
            TRYB.address,
            DDL
        ]
    );
    await ShellAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after TRYB balance: " + (await TRYB.balanceOf(account.address))
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
