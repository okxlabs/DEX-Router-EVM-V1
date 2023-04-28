const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, startMockAccount, setBalance } = require("../../tools/chain");
// 2050-07-19 17:52:02
const DDL = 2541837122

async function deployContract() {
    const router = "0x10f4A785F458Bc144e3706575924889954946639"
    MeshswapAdapter = await ethers.getContractFactory("MeshswapAdapter");
    MeshswapAdapter = await MeshswapAdapter.deploy(router);
    await MeshswapAdapter.deployed();
    return MeshswapAdapter
}



// compare tx: 0x104421ceafb3748352a5f5db0e876b5059aac951a5638c091852a499ddc7f68d
// network polygon

async function executeERC20ToERC20() {
    let tokenConfig = getConfig("polygon")

    await setForkNetWorkAndBlockNumber("polygon", 41884740 - 1);

    const MeshswapAdapter = await deployContract();

    const accountSource = "0x2Aa6845F7E84b2cC1619C823Bf4F6b04EC733F2C"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"


    const WMATIC = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.WMATIC.baseTokenAddress
    );

    const USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));


    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));

    await USDT.connect(accountS).transfer(
        account.address,
        ethers.BigNumber.from("240000000")
    );

    console.log(
        "before USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "before WMATIC balance: " + (await WMATIC.balanceOf(account.address))
    );

    await USDT.connect(account).transfer(
        MeshswapAdapter.address,
        ethers.BigNumber.from("240000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            USDT.address,
            WMATIC.address,
            DDL
        ]
    );
    await MeshswapAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "after WMATIC balance: " + (await WMATIC.balanceOf(account.address))
    );
}

// tx: 0x104421ceafb3748352a5f5db0e876b5059aac951a5638c091852a499ddc7f68d
// polygon
async function executeETHToERC20() {
    let tokenConfig = getConfig("polygon")

    await setForkNetWorkAndBlockNumber("polygon", 41884740 - 1);
    const MeshswapAdapter = await deployContract()



    const accountSource = "0x2Aa6845F7E84b2cC1619C823Bf4F6b04EC733F2C"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"


    const WMATIC = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.WMATIC.baseTokenAddress
    );

    const USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "before MATIC balance: " + (await ethers.provider.getBalance(accountAddr))
    );
    const amount = ethers.utils.parseEther("1");
    await WMATIC.connect(account).deposit({ value: amount });

    await WMATIC.connect(account).transfer(
        MeshswapAdapter.address,
        amount
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
            USDT.address,
            DDL
        ]
    );
    await MeshswapAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "after WMATIC balance: " + (await WMATIC.balanceOf(account.address))
    );
}

// tx: 0x104421ceafb3748352a5f5db0e876b5059aac951a5638c091852a499ddc7f68d
// polygon
async function executeERC20ToETH() {
    let tokenConfig = getConfig("polygon")

    await setForkNetWorkAndBlockNumber("polygon", 41884740 - 1);
    const MeshswapAdapter = await deployContract()



    const accountSource = "0x2Aa6845F7E84b2cC1619C823Bf4F6b04EC733F2C"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"


    const WMATIC = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.WMATIC.baseTokenAddress
    );

    const USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));

    await USDT.connect(accountS).transfer(
        account.address,
        ethers.BigNumber.from("240000000")
    );
    console.log(
        "before USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "before WMATIC balance: " + (await WMATIC.balanceOf(account.address))
    );
    const amount = ethers.BigNumber.from("240000000");

    await USDT.connect(account).transfer(
        MeshswapAdapter.address,
        amount
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            USDT.address,
            "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
            DDL
        ]
    );
    await MeshswapAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after USDT balance: " + (await USDT.balanceOf(account.address))
    );
    console.log(
        "after WMATIC balance: " + (await WMATIC.balanceOf(account.address))
    );
}

async function main() {

    console.log("==== checking ERC20 to ERC20 ====== ")
    await executeERC20ToERC20();
    console.log("==== checking ETH to ERC20 ====== ")
    await executeETHToERC20();
    console.log("==== checking ERC20 to ETH ====== ")
    await executeERC20ToETH();





}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
