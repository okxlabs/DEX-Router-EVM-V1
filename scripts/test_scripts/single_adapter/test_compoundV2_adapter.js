const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, startMockAccount, setBalance } = require("../../tools/chain");
// 2050-07-19 17:52:02
const DDL = 2541837122
const ETH_ADDR = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"

async function deployContract() {
    const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    CompoundAdapter = await ethers.getContractFactory("CompoundAdapter");
    CompoundAdapter = await CompoundAdapter.deploy(WETH);
    await CompoundAdapter.deployed();
    return CompoundAdapter
}



// compare tx: https://etherscan.io/tx/0x08dcecac14fd6ef7195fa3e1df654b802538a8caad3f45fe6ef7fe1f0f776291


async function executeMintCEther() {
    let tokenConfig = getConfig("eth")

    await setForkNetWorkAndBlockNumber("eth", 17235969 - 1);

    const CompoundAdapter = await deployContract();


    const accountAddr = "0x1000000000000000110000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"
    const cETHAddr = "0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5"


    const WETH = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.WETH.baseTokenAddress
    );

    const cETH = await ethers.getContractAt(
        "MockERC20",
        cETHAddr
    );


    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('20'));

    await WETH.connect(account).deposit({ value: ethers.BigNumber.from("10000000000000000000") }); //10 ether



    console.log(
        "before cETH balance: " + (await cETH.balanceOf(account.address))
    );
    console.log(
        "before WETH balance: " + (await WETH.balanceOf(account.address))
    );

    await WETH.connect(account).transfer(
        CompoundAdapter.address,
        ethers.BigNumber.from("10000000000000000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bool"],
        [
            ETH_ADDR,
            cETH.address,
            true
        ]
    );
    await CompoundAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after cETH balance: " + (await cETH.balanceOf(account.address))
    );
    console.log(
        "after WETH balance: " + (await WETH.balanceOf(account.address))
    );
}

// compare tx: https://etherscan.io/tx/0x08dcecac14fd6ef7195fa3e1df654b802538a8caad3f45fe6ef7fe1f0f776291


async function executeRedeemCEther() {
    let tokenConfig = getConfig("eth")

    await setForkNetWorkAndBlockNumber("eth", 17235969 - 1);

    const CompoundAdapter = await deployContract();

    const accountSource = "0x2BABa0Cba8241fDA56871589835e0B05EC64cA41"
    const accountAddr = "0x1000000000000000110000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"
    const cETHAddr = "0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5"


    const WETH = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.WETH.baseTokenAddress
    );

    const cETH = await ethers.getContractAt(
        "MockERC20",
        cETHAddr
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await cETH.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("49791284557")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('20'));

    console.log(
        "before cETH balance: " + (await cETH.balanceOf(account.address))
    );
    console.log(
        "before WETH balance: " + (await WETH.balanceOf(account.address))
    );

    await cETH.connect(account).transfer(
        CompoundAdapter.address,
        ethers.BigNumber.from("49791284557")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bool"],
        [
            cETH.address,
            ETH_ADDR,
            false
        ]
    );
    await CompoundAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after cETH balance: " + (await cETH.balanceOf(account.address))
    );
    console.log(
        "after WETH balance: " + (await WETH.balanceOf(account.address))
    );
}



// compare tx: https://etherscan.io/tx/0xcd4dbe1770444a6d1ea9a5f14aebe416659eefd0bb3cf910151449cd91816439


async function executeMintCToken() {
    let tokenConfig = getConfig("eth")

    await setForkNetWorkAndBlockNumber("eth", 17225818 - 1);

    const CompoundAdapter = await deployContract();

    const accountSource = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7"
    const accountAddr = "0x1000000000000000110000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"
    const cDaiAddr = "0x5d3a536e4d6dbd6114cc1ead35777bab948e3643"





    const DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    );

    const cDAI = await ethers.getContractAt(
        "MockERC20",
        cDaiAddr
    );

    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await DAI.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("10000000000000000000")
    );


    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('20'));




    console.log(
        "before cDAI balance: " + (await cDAI.balanceOf(account.address))
    );
    console.log(
        "before DAI balance: " + (await DAI.balanceOf(account.address))
    );

    await DAI.connect(account).transfer(
        CompoundAdapter.address,
        ethers.BigNumber.from("10000000000000000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bool"],
        [
            DAI.address,
            cDAI.address,
            true
        ]
    );
    await CompoundAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after cDAI balance: " + (await cDAI.balanceOf(account.address))
    );
    console.log(
        "after DAI balance: " + (await DAI.balanceOf(account.address))
    );
}

// compare tx: https://etherscan.io/tx/0xcd4dbe1770444a6d1ea9a5f14aebe416659eefd0bb3cf910151449cd91816439


async function executeRedeemCToken() {
    let tokenConfig = getConfig("eth")

    await setForkNetWorkAndBlockNumber("eth", 17225818 - 1);

    const CompoundAdapter = await deployContract();

    const accountSource = "0x01d127D90513CCB6071F83eFE15611C4d9890668"
    const accountAddr = "0x1000000000000000110000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"
    const cDaiAddr = "0x5d3a536e4d6dbd6114cc1ead35777bab948e3643"





    const DAI = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.DAI.baseTokenAddress
    );

    const cDAI = await ethers.getContractAt(
        "MockERC20",
        cDaiAddr
    );

    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await cDAI.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("44973277243")
    );


    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('20'));




    console.log(
        "before cDAI balance: " + (await cDAI.balanceOf(account.address))
    );
    console.log(
        "before DAI balance: " + (await DAI.balanceOf(account.address))
    );

    await cDAI.connect(account).transfer(
        CompoundAdapter.address,
        ethers.BigNumber.from("44973277243")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bool"],
        [
            cDAI.address,
            DAI.address,
            false
        ]
    );
    await CompoundAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after cDAI balance: " + (await cDAI.balanceOf(account.address))
    );
    console.log(
        "after DAI balance: " + (await DAI.balanceOf(account.address))
    );
}
async function main() {

    console.log("==== checking mint cETH ====== ")
    await executeMintCEther();
    console.log("==== checking redeem cETH ====== ")
    await executeRedeemCEther();
    console.log("==== checking mint cToken ====== ")
    await executeMintCToken();
    console.log("==== checking redeem cToken ====== ")
    await executeRedeemCToken();





}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
