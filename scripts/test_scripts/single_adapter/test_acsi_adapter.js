const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
const { setForkNetWorkAndBlockNumber, startMockAccount, setBalance } = require("../../tools/chain");
// 2050-07-19 17:52:02
const DDL = 2541837122

async function deployContract() {
    const WBNB = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c"
    const vault = "0xa82f327BBbF0667356D2935C6532d164b06cEced"
    BalancerV2Adapter = await ethers.getContractFactory("BalancerV2Adapter");
    BalancerV2Adapter = await BalancerV2Adapter.deploy(vault, WBNB);
    await BalancerV2Adapter.deployed();
    return BalancerV2Adapter
}



// compare tx: 0xa64cbb4c7bebe0cfdd351f8f8443c0c03354c0705899103963c2c5fdb164b470
// network bnb

async function executeERC20ToERC20() {
    let tokenConfig = getConfig("bsc")

    await setForkNetWorkAndBlockNumber("bsc", 27643618 - 1);

    const BalancerV2Adapter = await deployContract();

    const accountSource = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"

    const poolId = "0xa22f3e51939488962aa26d42799df75f72816ce0000000000000000000000007"


    const DAI = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.DAI.baseTokenAddress
    );

    const BUSD = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.BUSD.baseTokenAddress
    );
    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));

    await DAI.connect(accountS).transfer(
        accountAddr,
        ethers.BigNumber.from("100000000000000000")
    );

    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));



    console.log(
        "before BUSD balance: " + (await BUSD.balanceOf(account.address))
    );
    console.log(
        "before DAI balance: " + (await DAI.balanceOf(account.address))
    );

    await DAI.connect(account).transfer(
        BalancerV2Adapter.address,
        ethers.BigNumber.from("100000000000000000")
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            DAI.address,
            BUSD.address,
            poolId
        ]
    );
    await BalancerV2Adapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after BUSD balance: " + (await BUSD.balanceOf(account.address))
    );
    console.log(
        "after DAI balance: " + (await DAI.balanceOf(account.address))
    );
}

// tx: 0x104421ceafb3748352a5f5db0e876b5059aac951a5638c091852a499ddc7f68d
// bnb
async function executeETHToERC20() {
    let tokenConfig = getConfig("bsc")

    await setForkNetWorkAndBlockNumber("bsc", 27643618 - 1);
    const BalancerV2Adapter = await deployContract()



    const accountSource = "0x358506b4C5c441873AdE429c5A2BE777578E2C6f"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"


    const poolId = "0x894ed9026de37afd9cce1e6c0be7d6b510e3ffe5000100000000000000000001"

    const WBNB = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.WBNB.baseTokenAddress
    );

    const BUSD = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.BUSD.baseTokenAddress
    );


    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));




    const amount = ethers.utils.parseEther("0.001");
    await WBNB.connect(account).deposit({ value: amount });

    console.log(
        "before BUSD balance: " + (await BUSD.balanceOf(account.address))
    );
    console.log(
        "before WBNB balance: " + (await WBNB.balanceOf(account.address))
    );

    await WBNB.connect(account).transfer(
        BalancerV2Adapter.address,
        amount
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
            BUSD.address,
            poolId
        ]
    );
    await BalancerV2Adapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after BUSD balance: " + (await BUSD.balanceOf(account.address))
    );
    console.log(
        "after WBNB balance: " + (await WBNB.balanceOf(account.address))
    );
}
// tx: 0x104421ceafb3748352a5f5db0e876b5059aac951a5638c091852a499ddc7f68d
// bnb
async function executeERC20ToETH() {
    let tokenConfig = getConfig("bsc")

    await setForkNetWorkAndBlockNumber("bsc", 27643618 - 1);
    const BalancerV2Adapter = await deployContract()



    const accountSource = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"
    const accountAddr = "0x1000000000000000000000000000000000000000"
    const poolAddr = "0x0000000000000000000000000000000000000000"


    const poolId = "0x894ed9026de37afd9cce1e6c0be7d6b510e3ffe5000100000000000000000001"

    const WBNB = await ethers.getContractAt(
        "WETH9",
        tokenConfig.tokens.WBNB.baseTokenAddress
    );

    const BUSD = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.BUSD.baseTokenAddress
    );


    await startMockAccount([accountSource])
    const accountS = await ethers.getSigner(accountSource)
    await setBalance(accountSource, ethers.utils.parseEther('10'));



    await startMockAccount([accountAddr])
    const account = await ethers.getSigner(accountAddr)
    await setBalance(accountAddr, ethers.utils.parseEther('10'));

    await BUSD.connect(accountS).transfer(account.address, ethers.utils.parseEther("300"))
    const amount = ethers.utils.parseEther("300");


    console.log(
        "before BUSD balance: " + (await BUSD.balanceOf(account.address))
    );
    console.log(
        "before WBNB balance: " + (await WBNB.balanceOf(account.address))
    );

    await BUSD.connect(account).transfer(
        BalancerV2Adapter.address,
        amount
    );

    let moreInfo = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "uint256"],
        [
            BUSD.address,
            "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
            poolId
        ]
    );
    await BalancerV2Adapter.sellQuote(
        account.address,
        poolAddr,
        moreInfo
    );

    console.log(
        "after BUSD balance: " + (await BUSD.balanceOf(account.address))
    );
    console.log(
        "after WBNB balance: " + (await WBNB.balanceOf(account.address))
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
