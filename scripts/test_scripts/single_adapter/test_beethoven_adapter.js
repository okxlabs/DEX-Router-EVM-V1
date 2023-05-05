const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, startMockAccount, setBalance } = require("../../tools/chain");
// 2050-07-19 17:52:02
const DDL = 2541837122
const ADDR_ETH = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"

async function deployContractFtm() {
    const WFTM = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83"
    const vault = "0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce"
    BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
    BalancerV2Adapter = await BalancerV2Adapter.deploy(vault, WFTM);
    await BalancerV2Adapter.deployed();
    return BalancerV2Adapter
}

async function deployContractOp() {
    const WETH = "0x4200000000000000000000000000000000000006"
    const vault = "0xBA12222222228d8Ba445958a75a0704d566BF2C8"
    BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
    BalancerV2Adapter = await BalancerV2Adapter.deploy(vault, WETH);
    await BalancerV2Adapter.deployed();
    return BalancerV2Adapter
}



// compare tx: https://openchain.xyz/trace/fantom/0x161d8ba8e3d6cb6f1c66aaffd06d57d30e8f0b4b33ca87bba0438aa218514c5f

async function executeERC20ToERC20_Ftm() {
    let tokenConfig = getConfig("ftm")

    await setForkNetWorkAndBlockNumber("fantom", 61426332 - 1);

    const BalancerV2Adapter = await deployContractFtm();

    const accountSource = "0x546a14FD9b296cA55BfBDD5DFB28Dad158ef4ff8"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"

    const poolId = "0x56ad84b777ff732de69e85813daee1393a9ffe1000020000000000000000060e"


    const USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );

    const WFTM = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WFTM.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await USDC.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("285000000")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before WFTM balance: " + (await WFTM.balanceOf(account.address))
    );
    console.log(
        "before USDC balance: " + (await USDC.balanceOf(account.address))
    );

    await USDC.connect(account).transfer(
        BalancerV2Adapter.address,
        ethers.BigNumber.from("285000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            USDC.address,
            WFTM.address,
            poolId
        ]
    );
    await BalancerV2Adapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after WFTM balance: " + (await WFTM.balanceOf(account.address))
    );
    console.log(
        "after USDC balance: " + (await USDC.balanceOf(account.address))
    );
}

// compare tx: https://openchain.xyz/trace/fantom/0x161d8ba8e3d6cb6f1c66aaffd06d57d30e8f0b4b33ca87bba0438aa218514c5f

async function executeERC20ToETH_Ftm() {
    let tokenConfig = getConfig("ftm")

    await setForkNetWorkAndBlockNumber("fantom", 61426332 - 1);

    const BalancerV2Adapter = await deployContractFtm();

    const accountSource = "0x546a14FD9b296cA55BfBDD5DFB28Dad158ef4ff8"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"


    const poolId = "0x56ad84b777ff732de69e85813daee1393a9ffe1000020000000000000000060e"


    const USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );

    const WFTM = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WFTM.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await USDC.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("285000000")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before WFTM balance: " + (await WFTM.balanceOf(account.address))
    );
    console.log(
        "before USDC balance: " + (await USDC.balanceOf(account.address))
    );

    await USDC.connect(account).transfer(
        BalancerV2Adapter.address,
        ethers.BigNumber.from("285000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            USDC.address,
            ADDR_ETH,
            poolId
        ]
    );
    await BalancerV2Adapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after WFTM balance: " + (await WFTM.balanceOf(account.address))
    );
    console.log(
        "after USDC balance: " + (await USDC.balanceOf(account.address))
    );
}
// compare tx: https://openchain.xyz/trace/fantom/0x161d8ba8e3d6cb6f1c66aaffd06d57d30e8f0b4b33ca87bba0438aa218514c5f

async function executeETHToERC20_Ftm() {
    let tokenConfig = getConfig("ftm")

    await setForkNetWorkAndBlockNumber("fantom", 61426332 - 1);

    const BalancerV2Adapter = await deployContractFtm();

    const accountSource = "0x546a14FD9b296cA55BfBDD5DFB28Dad158ef4ff8"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"

    const poolId = "0x56ad84b777ff732de69e85813daee1393a9ffe1000020000000000000000060e"


    const USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    );

    const WFTM = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WFTM.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await WFTM.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("642314901734154832376")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before WFTM balance: " + (await WFTM.balanceOf(account.address))
    );
    console.log(
        "before USDC balance: " + (await USDC.balanceOf(account.address))
    );

    await WFTM.connect(account).transfer(
        BalancerV2Adapter.address,
        ethers.BigNumber.from("642314901734154832376")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            ADDR_ETH,
            USDC.address,
            poolId
        ]
    );
    await BalancerV2Adapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after WFTM balance: " + (await WFTM.balanceOf(account.address))
    );
    console.log(
        "after USDC balance: " + (await USDC.balanceOf(account.address))
    );
}

// tx: https://openchain.xyz/trace/optimism/0x83da7f5777dd10d0d6eb5f338ba8459be24b9da88621d88f330d18042bf423da
async function executeERC20ToERC20_Op() {
    let tokenConfig = getConfig("op")

    await setForkNetWorkAndBlockNumber("op", 96246507 - 1);

    const BalancerV2Adapter = await deployContractOp();

    const accountSource = "0x115BeA76cD38F2384C6484B63989D41810428135"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"

    const poolId = "0x4fd63966879300cafafbb35d157dc5229278ed2300020000000000000000002b"


    const rETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.rETH.baseTokenAddress
    );

    const WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await rETH.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("1000000")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before WETH balance: " + (await WETH.balanceOf(account.address))
    );
    console.log(
        "before rETH balance: " + (await rETH.balanceOf(account.address))
    );

    await rETH.connect(account).transfer(
        BalancerV2Adapter.address,
        ethers.BigNumber.from("1000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            rETH.address,
            WETH.address,
            poolId
        ]
    );

    await BalancerV2Adapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after WETH balance: " + (await WETH.balanceOf(account.address))
    );
    console.log(
        "after rETH balance: " + (await rETH.balanceOf(account.address))
    );
}
// tx: https://openchain.xyz/trace/optimism/0x83da7f5777dd10d0d6eb5f338ba8459be24b9da88621d88f330d18042bf423da
async function executeERC20ToETH_Op() {
    let tokenConfig = getConfig("op")

    await setForkNetWorkAndBlockNumber("op", 96246507 - 1);

    const BalancerV2Adapter = await deployContractOp();

    const accountSource = "0x115BeA76cD38F2384C6484B63989D41810428135"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"

    const poolId = "0x4fd63966879300cafafbb35d157dc5229278ed2300020000000000000000002b"


    const rETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.rETH.baseTokenAddress
    );

    const WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await rETH.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("1000000")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before WETH balance: " + (await WETH.balanceOf(account.address))
    );
    console.log(
        "before rETH balance: " + (await rETH.balanceOf(account.address))
    );

    await rETH.connect(account).transfer(
        BalancerV2Adapter.address,
        ethers.BigNumber.from("1000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            rETH.address,
            ADDR_ETH,
            poolId
        ]
    );

    await BalancerV2Adapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after WETH balance: " + (await WETH.balanceOf(account.address))
    );
    console.log(
        "after rETH balance: " + (await rETH.balanceOf(account.address))
    );
}
// tx: https://openchain.xyz/trace/optimism/0x83da7f5777dd10d0d6eb5f338ba8459be24b9da88621d88f330d18042bf423da
async function executeETHToERC20_Op() {
    let tokenConfig = getConfig("op")

    await setForkNetWorkAndBlockNumber("op", 96246507 - 1);

    const BalancerV2Adapter = await deployContractOp();

    const accountSource = "0x115BeA76cD38F2384C6484B63989D41810428135"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"

    const poolId = "0x4fd63966879300cafafbb35d157dc5229278ed2300020000000000000000002b"


    const rETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.rETH.baseTokenAddress
    );

    const WETH = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.WETH.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));


    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));

    await WETH.connect(account).deposit(
        { value: ethers.BigNumber.from("1000000") }
    );



    console.log(
        "before WETH balance: " + (await WETH.balanceOf(account.address))
    );
    console.log(
        "before rETH balance: " + (await rETH.balanceOf(account.address))
    );

    await WETH.connect(account).transfer(
        BalancerV2Adapter.address,
        ethers.BigNumber.from("1000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            ADDR_ETH,
            rETH.address,
            poolId
        ]
    );

    await BalancerV2Adapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after WETH balance: " + (await WETH.balanceOf(account.address))
    );
    console.log(
        "after rETH balance: " + (await rETH.balanceOf(account.address))
    );
}

async function main() {

    console.log("==== checking ERC20 to ERC20 FTM ====== ")
    await executeERC20ToERC20_Ftm();
    console.log("==== checking ETH to ERC20 FTM ====== ")
    await executeETHToERC20_Ftm();
    console.log("==== checking ERC20 to ETH FTM ====== ")
    await executeERC20ToETH_Ftm();
    console.log("==== checking ERC20 to ERC20 Op ====== ")
    await executeERC20ToERC20_Op();
    console.log("==== checking ETH to ERC20 Op ====== ")
    await executeETHToERC20_Op();
    console.log("==== checking ERC20 to ETH Op ====== ")
    await executeERC20ToETH_Op();




}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
