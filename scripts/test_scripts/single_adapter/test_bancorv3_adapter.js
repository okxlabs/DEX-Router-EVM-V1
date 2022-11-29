const { config } = require("dotenv");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth");

const FOREVER = '2000000000';

// blocknumber: 16042024
async function executeLPL2DAI() {
    await setForkBlockNumber(16042024);

    const accountAddress = "0x13d1ba88e50443dd6e97f4b44b0986453fc24c97"
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress)

    // const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
    const BancorNetworkV3 = "0xeEF417e1D5CC832e619ae18D2F140De2999dD4fB";
    const BancorNetworkV3Info = "0x8E303D296851B320e6a697bAcB979d13c9D6E760";

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    BancorV3Adapter = await ethers.getContractFactory("BancorV3Adapter");
    bancorV3Adapter = await BancorV3Adapter.deploy(BancorNetworkV3, BancorNetworkV3Info, WETH.address);
    await bancorV3Adapter.deployed();

    console.log(`bancorV3Adapter deployed: ${bancorV3Adapter.address}`);

    LPL = await ethers.getContractAt(
        "MockERC20",
        "0x99295f1141d58A99e939F7bE6BBe734916a875B8"
    )
    DAI = await ethers.getContractAt(
        "MockERC20",
        "0x6B175474E89094C44Da98b954EedeAC495271d0F"
    )

    // transfer 2500 LPL to bancorAdapter
    await LPL.connect(account).transfer(bancorV3Adapter.address, ethers.utils.parseEther('2500'));
    console.log("before LPL balance: " + await LPL.balanceOf(bancorV3Adapter.address));
    console.log("before DAI balance: " + await DAI.balanceOf(bancorV3Adapter.address));

    // LPL exchange to DAI
    rxResult = await bancorV3Adapter.sellQuote(
        bancorV3Adapter.address,
        bancorV3Adapter.address,
        ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [
                LPL.address,
                DAI.address,
                FOREVER
            ]
        )
    );
    // console.log(rxResult);

    // targetReserveBalance * sourceAmount / sourceReserveBalance + sourceAmount
    //
    console.log("after lpl balance: " + await LPL.balanceOf(bancorV3Adapter.address));
    console.log("after dai balance: " + await DAI.balanceOf(bancorV3Adapter.address));
}

// blocknumber: 16037043
async function executeETH2BNT() {
    await setForkBlockNumber(16037043);

    // impersonateAccount account
    const accountAddr = "0x23D2dDAE7A638Ef8F07A482e31a7f08Ba57c1277"
    const account = await ethers.getSigner(accountAddr);
    await startMockAccount([accountAddr]);

    // set account balance 0.6 eth
    await setBalance(accountAddr, "0x53444835ec580000");

    const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
    const BancorNetworkV3 = "0xeEF417e1D5CC832e619ae18D2F140De2999dD4fB";
    const BancorNetworkV3Info = "0x8E303D296851B320e6a697bAcB979d13c9D6E760";

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    BancorV3Adapter = await ethers.getContractFactory("BancorV3Adapter");
    bancorV3Adapter = await BancorV3Adapter.deploy(BancorNetworkV3, BancorNetworkV3Info, WETH.address);
    await bancorV3Adapter.deployed();

    console.log(`bancorV3Adapter deployed: ${bancorV3Adapter.address}`);

    BNT = await ethers.getContractAt(
        "MockERC20",
        "0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C"
    )

    await WETH.connect(account).transfer(bancorV3Adapter.address, ethers.utils.parseEther('0.21'));

    console.log("before weth balance: " + await WETH.balanceOf(bancorV3Adapter.address));
    console.log("before bnt  balance: " + await BNT.balanceOf(bancorV3Adapter.address));

    rxResult = await bancorV3Adapter.sellBase(
        bancorV3Adapter.address,
        bancorV3Adapter.address,
        ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [
                WETH.address,
                BNT.address,
                FOREVER
            ]
        )
    );
    console.log("after weth balance: " + await WETH.balanceOf(bancorV3Adapter.address));
    console.log("after bnt  balance: " + await BNT.balanceOf(bancorV3Adapter.address));
}

// blocknumber: 16037044
async function executeBNT2ETH() {
    await setForkBlockNumber(16037044);

    // impersonateAccount account
    const accountAddr = "0xF977814e90dA44bFA03b6295A0616a897441aceC"
    const account = await ethers.getSigner(accountAddr);
    await startMockAccount([accountAddr]);

    // set account balance 0.6 eth
    // await setBalance(accountAddr, "0x53444835ec580000");

    const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
    const BancorNetworkV3 = "0xeEF417e1D5CC832e619ae18D2F140De2999dD4fB";
    const BancorNetworkV3Info = "0x8E303D296851B320e6a697bAcB979d13c9D6E760";

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    BancorV3Adapter = await ethers.getContractFactory("BancorV3Adapter");
    bancorV3Adapter = await BancorV3Adapter.deploy(BancorNetworkV3, BancorNetworkV3Info, WETH.address);
    await bancorV3Adapter.deployed();

    console.log(`bancorV3Adapter deployed: ${bancorV3Adapter.address}`);

    BNT = await ethers.getContractAt(
        "MockERC20",
        "0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C"
    )

    await BNT.connect(account).transfer(bancorV3Adapter.address, ethers.utils.parseEther('6833.53'));

    console.log("before weth balance: " + await WETH.balanceOf(bancorV3Adapter.address));
    console.log("before bnt  balance: " + await BNT.balanceOf(bancorV3Adapter.address));

    rxResult = await bancorV3Adapter.sellBase(
        "0x72eCDa3288801ECCac7918db9a986e2c7451cD7D",
        bancorV3Adapter.address,
        ethers.utils.defaultAbiCoder.encode(
            ["address", "address", "uint256"],
            [
                BNT.address,
                WETH.address,
                FOREVER
            ]
        )
    );
    console.log("after weth balance: " + await WETH.balanceOf("0x72eCDa3288801ECCac7918db9a986e2c7451cD7D"));
    console.log("after bnt  balance: " + await BNT.balanceOf(bancorV3Adapter.address));
}


async function main() {
    // // ERC20 -> ERC20
    await executeLPL2DAI();

    // WETH -> ETH -> ERC20
    await executeETH2BNT();

    // ERC20 -> ETH -> WETH
    await executeBNT2ETH();

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });