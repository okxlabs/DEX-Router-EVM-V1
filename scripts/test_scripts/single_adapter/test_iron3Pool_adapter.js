const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, startMockAccount, setBalance } = require("../../tools/chain");
// 2050-07-19 17:52:02
const DDL = 2541837122

async function deployContract() {
    const threePool = "0x837503e8A8753ae17fB8C8151B8e6f586defCb57"
    Ironswap3PoolLpAdapter = await ethers.getContractFactory("Ironswap3PoolLpAdapter");
    Ironswap3PoolLpAdapter = await Ironswap3PoolLpAdapter.deploy(threePool);
    await Ironswap3PoolLpAdapter.deployed();
    return Ironswap3PoolLpAdapter
}



// compare tx: 0x8551fcdf42104406c798ccbc65b78e1bafcdd1ecfac39933b7280a3c1b931751
// network polygon

async function executeSellQuote() {
    let tokenConfig = getConfig("polygon")

    await setForkNetWorkAndBlockNumber("polygon", 41935169 - 1);

    const Ironswap3PoolLpAdapter = await deployContract();

    const accountSource = "0xF977814e90dA44bFA03b6295A0616a897441aceC"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x837503e8A8753ae17fB8C8151B8e6f586defCb57"
    const lp = "0xb4d09ff3dA7f9e9A2BA029cb0A81A989fd7B8f17"


    const USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );

    const USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    );
    const LPToken = await ethers.getContractAt(
        "MockERC20",
        lp
    )
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('100'));


    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('100'));

    await USDT.connect(accountS).transfer(
        account.address,
        ethers.BigNumber.from("1000000")
    );

    console.log(
        "before USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "before LP balance: " + (await LPToken.balanceOf(account.address))
    );

    await USDT.connect(account).transfer(
        Ironswap3PoolLpAdapter.address,
        ethers.BigNumber.from("1000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address"],
        [
            USDT.address
        ]
    );
    await Ironswap3PoolLpAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "before USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "before LP balance: " + (await LPToken.balanceOf(account.address))
    );
}

// 0x6f25fc788ff27c46f9c634c89ca1e861563ab0379ed0a69e875665eb624992f6
// polygon
async function executeSellBase() {
    let tokenConfig = getConfig("polygon")

    await setForkNetWorkAndBlockNumber("polygon", 41935169 - 1);

    const Ironswap3PoolLpAdapter = await deployContract();

    const accountSource = "0x1fD1259Fa8CdC60c6E8C86cfA592CA1b8403DFaD"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x837503e8A8753ae17fB8C8151B8e6f586defCb57"
    const lp = "0xb4d09ff3dA7f9e9A2BA029cb0A81A989fd7B8f17"


    const USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );

    const USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    );
    const LPToken = await ethers.getContractAt(
        "MockERC20",
        lp
    )
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('100'));


    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('100'));

    await LPToken.connect(accountS).transfer(
        account.address,
        ethers.BigNumber.from("107481917631207")
    );

    console.log(
        "before USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "before LP balance: " + (await LPToken.balanceOf(account.address))
    );

    await LPToken.connect(account).transfer(
        Ironswap3PoolLpAdapter.address,
        ethers.BigNumber.from("107481917631207")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address"],
        [
            USDT.address
        ]
    );
    await Ironswap3PoolLpAdapter.sellBase(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "before USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "before LP balance: " + (await LPToken.balanceOf(account.address))
    );
}

async function main() {

    console.log("==== checking sell quote ====== ")
    await executeSellQuote();

    console.log("==== checking sell base ====== ")
    await executeSellBase();


}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
