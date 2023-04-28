const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, startMockAccount, setBalance } = require("../../tools/chain");
// 2050-07-19 17:52:02
const DDL = 2541837122

async function deployContract() {
    const WAVAX = "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7"
    PlatypusAdapter = await ethers.getContractFactory("PlatypusAdapter");
    PlatypusAdapter = await PlatypusAdapter.deploy(WAVAX);
    await PlatypusAdapter.deployed();
    return PlatypusAdapter
}



// compare tx: 0xcaedbccc7c79aadb67bc25855234760699db144a64478b46bcb58dc883ed1603
// network avax

async function executeERC20ToERC20() {
    let tokenConfig = getConfig("avax")

    await setForkNetWorkAndBlockNumber("avax", 28659294 - 1);

    const PlatypusAdapter = await deployContract();

    const accountSource = "0xD94fb9394DBF776A292631a537CD2D80b7Be9481"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x91BB10D68C72d64a7cE10482b453153eEa03322C"

    const tsd = "0x4fbf0429599460D327BD5F55625E30E4fC066095"


    const TSD = await ethers.getContractAt(
        "MockERC20",
        tsd
    );

    const USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));


    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));

    await USDC.connect(accountS).transfer(
        account.address,
        ethers.BigNumber.from("10000000")
    );

    console.log(
        "before USDC balance: " + (await USDC.balanceOf(account.address))
    );
    console.log(
        "before TSD balance: " + (await TSD.balanceOf(account.address))
    );

    await USDC.connect(account).transfer(
        PlatypusAdapter.address,
        ethers.BigNumber.from("10000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            USDC.address,
            TSD.address,
            DDL
        ]
    );
    await PlatypusAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after USDC balance: " + (await USDC.balanceOf(account.address))
    );
    console.log(
        "after TSD balance: " + (await TSD.balanceOf(account.address))
    );
}

// tx: 0x2229b961e7835f3d9e5a20b80eeb9700f9ff5a868296784d057eec0868e0d852
// avax
async function executeETHToERC20() {
    let tokenConfig = getConfig("avax")

    await setForkNetWorkAndBlockNumber("avax", 29237484 - 1);

    const PlatypusAdapter = await deployContract();

    const accountSource = "0xD94fb9394DBF776A292631a537CD2D80b7Be9481"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0xDeD29DF6b2193B885F45B5F5027ed405291A96C1"


    const ankrAvax = "0xc3344870d52688874b06d844E0C36cc39FC727F6";
    const ETH_ADDRESS = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";


    const WAVAX = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.WAVAX.baseTokenAddress
    );

    const ANKRAVAX = await ethers.getContractAt(
        "MockERC20",
        ankrAvax
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));


    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));

    await WAVAX.connect(account).deposit({
        value: ethers.utils.parseEther("0.0001")
    });

    console.log(
        "before ANKRAVAX balance: " + (await ANKRAVAX.balanceOf(account.address))
    );
    console.log(
        "before WAVAX balance: " + (await WAVAX.balanceOf(account.address))
    );

    await WAVAX.connect(account).transfer(
        PlatypusAdapter.address,
        ethers.utils.parseEther("0.0001")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            ETH_ADDRESS,
            ankrAvax,
            DDL
        ]
    );
    await PlatypusAdapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "before ANKRAVAX balance: " + (await ANKRAVAX.balanceOf(account.address))
    );
    console.log(
        "before WAVAX balance: " + (await WAVAX.balanceOf(account.address))
    );
}

// tx: 0xd761a1ea453389c212c1d3347db908f24f91b138434331bb26b56d50034bee07
// avax
async function executeERC20ToETH() {
    let tokenConfig = getConfig("avax")

    await setForkNetWorkAndBlockNumber("avax", 29238137 - 1);

    const PlatypusAdapter = await deployContract();

    const accountSource = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0xDeD29DF6b2193B885F45B5F5027ed405291A96C1"


    const ankrAvax = "0xc3344870d52688874b06d844E0C36cc39FC727F6";
    const ETH_ADDRESS = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";


    const WAVAX = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.WAVAX.baseTokenAddress
    );

    const ANKRAVAX = await ethers.getContractAt(
        "MockERC20",
        ankrAvax
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));


    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    await ANKRAVAX.connect(accountS).transfer(
        account.address,
        ethers.BigNumber.from("10000000000000")
    );

    console.log(
        "before ANKRAVAX balance: " + (await ANKRAVAX.balanceOf(account.address))
    );
    console.log(
        "before WAVAX balance: " + (await WAVAX.balanceOf(account.address))
    );

    await ANKRAVAX.connect(account).transfer(
        PlatypusAdapter.address,
        ethers.BigNumber.from("10000000000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            ANKRAVAX.address,
            ETH_ADDRESS,
            DDL
        ]
    );
    await PlatypusAdapter.sellBase(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "before ANKRAVAX balance: " + (await ANKRAVAX.balanceOf(account.address))
    );
    console.log(
        "before WAVAX balance: " + (await WAVAX.balanceOf(account.address))
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
