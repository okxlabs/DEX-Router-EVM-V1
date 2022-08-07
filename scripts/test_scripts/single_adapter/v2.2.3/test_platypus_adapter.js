const { ethers } = require("hardhat");
const {BigNumber,BigNumberish} =require("ethers");
require("../../tools");
const { getConfig } = require("../../config");
const { USDC } = require("../../config/okc/tokens");

tokenConfig = getConfig("avax");

async function deployContract() {
    const PlatypusAdapter = await ethers.getContractFactory("PlatypusAdapter");
    const platypusAdapter = await PlatypusAdapter.deploy(tokenConfig.tokens.WAVAX.baseTokenAddress);
    await platypusAdapter.deployed();

    return platypusAdapter
}

// swap usdc to usdt in main pool
async function execute1() {
    // fork network
    // await setForkNetWork("avax", 17351078)
    // deploy adapter
    const platypusAdapter = await deployContract()
    console.log(platypusAdapter.address)
    // mock account
    // const userAddress = "0x1df3cc53e85481d503eada1c7593a1999d7cc786"
    // await startMockAccount([userAddress])
    // const userSigner = await ethers.getSigner(userAddress)

    // const pool = "0x66357dCaCe80431aee0A7507e2E361B7e2402370"  // main pool
    
    // const usdc = await ethers.getContractAt(
    //     "MockERC20",
    //     tokenConfig.tokens.USDC.baseTokenAddress
    // )
    // const usdt = await ethers.getContractAt(
    //     "MockERC20",
    //     tokenConfig.tokens.USDT.baseTokenAddress
    // )

    // // transfer token
    // await usdc.connect(userSigner).transfer(platypusAdapter.address,40000000000)
    // // start status
    // usdcAmountBefore = await usdc.balanceOf(platypusAdapter.address)
    // usdtAmountBefore = await usdt.balanceOf(platypusAdapter.address)
    // console.log("USDC before balance: ", usdcAmountBefore.toString())
    // console.log("USDT before balance: ", usdtAmountBefore.toString())

    // // swap
    // const moreInfo=await ethers.utils.defaultAbiCoder.encode(
    //     ['address','address'],
    //     [
    //         tokenConfig.tokens.USDC.baseTokenAddress,
    //         tokenConfig.tokens.USDT.baseTokenAddress
    //     ]
    // )
    // await platypusAdapter.sellBase(
    //     platypusAdapter.address,
    //     pool,
    //     moreInfo
    // )
    // // end status
    // usdcAmountBefore = await usdc.balanceOf(platypusAdapter.address)
    // usdtAmountBefore = await usdt.balanceOf(platypusAdapter.address)
    // console.log("USDC after balance: ", usdcAmountBefore.toString())
    // console.log("USDT after balance: ", usdtAmountBefore.toString())
}

// swap avax to savax in alt pool (swapFromETH)
async function execute2() {
    // tx = "0xb3536c11c73dab89e0a6f7d4ef6d6ea2d073de35e688cde3b1b9c81e92bd1032"
    // fork network
    // await setForkNetWork( "avax", 17317563)
    // deploy adapter
    const platypusAdapter = await deployContract()
    console.log(platypusAdapter.address)
    // mock account
    const userAddress = "0x04e45ee310048f79d0eb1d7efedaa45c1973dcc1"
    await startMockAccount([userAddress])
    const userSigner = await ethers.getSigner(userAddress)

    const pool = "0x4658EA7e9960D6158a261104aAA160cC953bb6ba"  // savax pool
    
    // const usdc = await ethers.getContractAt(
    //     "MockERC20",
    //     tokenConfig.tokens.USDC.baseTokenAddress
    // )
    const savax = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.SAVAX.baseTokenAddress
    )

    // transfer native token
    const amountAvax=await ethers.utils.parseEther('2.6')
    const tx = await userSigner.sendTransaction({
        to:platypusAdapter.address,
        value:amountAvax
    })
    await tx.wait()
    // start status
    const avaxAmountBefore = await ethers.provider.getBalance(platypusAdapter.address)
    const savaxAmountBefore = await savax.balanceOf(platypusAdapter.address)
    console.log("avax before balance: ", avaxAmountBefore.toString())
    console.log("savax before balance: ", savaxAmountBefore.toString())

    // swap
    const moreInfo=await ethers.utils.defaultAbiCoder.encode(
        ['address','address'],
        [
            '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
            tokenConfig.tokens.SAVAX.baseTokenAddress
        ]
    )
    await platypusAdapter.sellBase(
        platypusAdapter.address,
        pool,
        moreInfo
    )
    // end status
    const avaxAmountAfter = await ethers.provider.getBalance(platypusAdapter.address)
    const savaxAmountAfter = await savax.balanceOf(platypusAdapter.address)
    console.log("avax after balance: ", avaxAmountAfter.toString())
    console.log("savax after balance: ", savaxAmountAfter.toString())
}

// swap savax to avax in alt pool (swapToETH)
async function execute3() {
    // tx = "0xb6b42ea522e0c20cc841e131429b5dffc32ea2e2df0a7aefba0047e1169dca11"
    // fork network
    // await setForkNetWork( "avax", 17351168)
    // deploy adapter
    const platypusAdapter = await deployContract()
    console.log(platypusAdapter.address)
    // mock account
    const userAddress = "0x5472ae1401fc0b4f16ddbbbcc6dd637fc2ee69b8"
    await startMockAccount([userAddress])
    const userSigner = await ethers.getSigner(userAddress)

    const pool = "0x4658EA7e9960D6158a261104aAA160cC953bb6ba"  // savax pool
    
    // const usdc = await ethers.getContractAt(
    //     "MockERC20",
    //     tokenConfig.tokens.USDC.baseTokenAddress
    // )
    const savax = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.SAVAX.baseTokenAddress
    )

    // transfer savax token
    await savax.connect(userSigner).transfer(platypusAdapter.address,11977315399197257153n)
    // start status
    avaxAmountBefore = await ethers.provider.getBalance(platypusAdapter.address)
    savaxAmountBefore = await savax.balanceOf(platypusAdapter.address)
    console.log("avax before balance: ", avaxAmountBefore.toString())
    console.log("savax before balance: ", savaxAmountBefore.toString())

    // swap
    const moreInfo=await ethers.utils.defaultAbiCoder.encode(
        ['address','address'],
        [
            tokenConfig.tokens.SAVAX.baseTokenAddress,
            '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'
            
        ]
    )
    await platypusAdapter.sellBase(
        platypusAdapter.address,
        pool,
        moreInfo
    )
    // end status
    avaxAmountBefore = await ethers.provider.getBalance(platypusAdapter.address)
    savaxAmountBefore = await savax.balanceOf(platypusAdapter.address)
    console.log("avax after balance: ", avaxAmountBefore.toString())
    console.log("savax after balance: ", savaxAmountBefore.toString())
}


async function main() {
    console.log("==== swap usdc to usdt in main pool ====== ")
    await execute1()
    // console.log("==== swap avax to savax alt pool ====== ")
    // await execute2()
    // console.log("==== swap savax to avax alt pool ====== ")
    // await execute3()
}
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });

