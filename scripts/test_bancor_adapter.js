const { config } = require("dotenv");
const { ethers } = require("hardhat");
require("./tools");
const { getConfig } = require("./config");
config = getConfig("eth");

// blocknumber: 14395835
async function executeMPH2BNT() {
    await setForkBlockNumber(14395835);

    const accountAddress = "0x9b29b87b8428fab4228a16d8d38a6482cb7e68eb"
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress)

    // const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
    const BancorNetwork = "0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0";

    WETH = await ethers.getContractAt(
        "MockERC20",
        config.token.WETH
    )

    BancorAdapter = await ethers.getContractFactory("BancorAdapter");
    bancorAdapter = await BancorAdapter.deploy(BancorNetwork, WETH.address);
    await bancorAdapter.deployed();

    // console.log(`bancorAdapter deployed: ${bancorAdapter.address}`);

    MPH = await ethers.getContractAt(
        "MockERC20",
        config.token.MPH
    )
    BNT = await ethers.getContractAt(
        "MockERC20",
        config.token.BNT
    )

    // transfer 100 MPH to bancorAdapter
    await MPH.connect(account).transfer(bancorAdapter.address, ethers.utils.parseEther('100'));
    console.log("before mph balance: " + await MPH.balanceOf(bancorAdapter.address));
    console.log("before btn balance: " + await BNT.balanceOf(bancorAdapter.address));

    // MPH exchange to BNT
    rxResult = await bancorAdapter.sellQuote(
        bancorAdapter.address,
        bancorAdapter.address,
        ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                MPH.address,
                BNT.address
            ]
        )
    );
    // console.log(rxResult);

    // targetReserveBalance * sourceAmount / sourceReserveBalance + sourceAmount
    // 
    console.log("after mph balance: " + await MPH.balanceOf(bancorAdapter.address));
    console.log("after btn balance: " + await BNT.balanceOf(bancorAdapter.address));
}

// blocknumber: 14429782
async function executeETH2BNT() {
    await setForkBlockNumber(14429782);

    // impersonateAccount account
    const accountAddr = "0x49ce02683191fb39490583a7047b280109cab9c1"
    const account = await ethers.getSigner(accountAddr);
    await startMockAccount([accountAddr]);

    // set account balance 0.6 eth
    await setBalance(accountAddr, "0x53444835ec580000");

    const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
    const BancorNetwork = "0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0";

    WETH = await ethers.getContractAt(
        "MockERC20",
        config.token.WETH
    )
    BNT = await ethers.getContractAt(
        "MockERC20",
        config.token.BNT
    )

    BancorAdapter = await ethers.getContractFactory("BancorAdapter");
    bancorAdapter = await BancorAdapter.deploy(BancorNetwork, WETH.address);
    await bancorAdapter.deployed();

    // console.log(`bancorAdapter deployed: ${bancorAdapter.address}`);

    mockBancor = await ethers.getContractAt(
        "MockBancor",
        "0x4c9a2bd661d640da3634a4988a9bd2bc0f18e5a9"
    );
    // r = await mockBancor.reserveBalance(ETH.address + "");
    // console.log(r + "");
    // r = await mockBancor.reserveBalance(BNT.address + "");
    // console.log(r + "");
    // r = await mockBancor.conversionFee();
    // console.log(r + "");

    // r = await getArrayData(mockBancor.address, 7);
    // console.log(r);

    // 0x00000000000009216b91bc772d68063800000000002aa3dbe145a3f8253dfbce
    // r = await getStorageAt(mockBancor.address, 5);
    // console.log(r);

    // balance0 = ethers.utils.hexZeroPad(ethers.BigNumber.from('40117792083912952383032').toHexString(), 16);
    // balance1 = ethers.utils.hexZeroPad(ethers.BigNumber.from('51548686230035037998152654').toHexString(), 16);
    // adjustBalance = combine2Uint128('40117792083912952383032', '51548686230035037998152654');
    // // change reserves
    // await setStorageAt(mockBancor.address, "0x5", adjustBalance);

    // const owner = await ethers.getSigner(ownerAddr);
    // await impersonateAccount([ownerAddr]);
    // await mockBancor.connect(owner).setConversionFee(2000);

    await WETH.connect(account).transfer(bancorAdapter.address, ethers.utils.parseEther('0.4'));

    console.log("before weth balance: " + await WETH.balanceOf(bancorAdapter.address));
    console.log("before bnt  balance: " + await BNT.balanceOf(bancorAdapter.address));

    rxResult = await bancorAdapter.sellBase(
        bancorAdapter.address,
        bancorAdapter.address,
        ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                ETH.address,
                BNT.address
            ]
        )
    );
    // console.log(rxResult);

    // targetAmount: targetReserveBalance * sourceAmount / (sourceReserveBalance + sourceAmount)
    // 50501462456674053205716100 * 400000000000000000 / (41536194569038260154218 + 400000000000000000) = 486332237687278140000
    // fee: targetAmount.mul(_conversionFee) / PPM_RESOLUTION
    // 486332237687278140000 * 1000 / 1000000 = 486332237687278140
    // user receive amount
    // 486332237687278140000 - 486332237687278140 = 485845905449590850000
    // after weth balance: 0
    console.log("after weth balance: " + await WETH.balanceOf(bancorAdapter.address));
    // after bnt  balance: 485845905449590857665
    console.log("after bnt  balance: " + await BNT.balanceOf(bancorAdapter.address));
}

// blocknumber: 14453688
async function executeBNT2ETH() {
    await setForkBlockNumber(14453688);

    // impersonateAccount account
    const accountAddr = "0x0000a0756737268a633cd9296f1b154cf74430b6"
    const account = await ethers.getSigner(accountAddr);
    await startMockAccount([accountAddr]);

    // set account balance 0.6 eth
    await setBalance(accountAddr, "0x53444835ec580000");

    const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
    const BancorNetwork = "0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0";
    
    WETH = await ethers.getContractAt(
        "MockERC20",
        config.token.WETH
    )
    BNT = await ethers.getContractAt(
        "MockERC20",
        config.token.BNT
    )

    BancorAdapter = await ethers.getContractFactory("BancorAdapter");
    bancorAdapter = await BancorAdapter.deploy(BancorNetwork, WETH.address);
    await bancorAdapter.deployed();

    // console.log(`bancorAdapter deployed: ${bancorAdapter.address}`);

    // const mockBancor = await ethers.getContractAt(
    //     "MockBancor",
    //     "0x4c9a2bd661d640da3634a4988a9bd2bc0f18e5a9"
    // );
    // r = await mockBancor.reserveBalance(ETH.address + "");
    // console.log(r + "");
    // r = await mockBancor.reserveBalance(BNT.address + "");
    // console.log(r + "");
    // r = await mockBancor.conversionFee();
    // console.log(r + "");

    // r = await getArrayData(mockBancor.address, 7);
    // console.log(r);

    // 0x00000000000009216b91bc772d68063800000000002aa3dbe145a3f8253dfbce
    // r = await getStorageAt(mockBancor.address, 5);
    // console.log(r);

    // balance0 = ethers.utils.hexZeroPad(ethers.BigNumber.from('40117792083912952383032').toHexString(), 16);
    // balance1 = ethers.utils.hexZeroPad(ethers.BigNumber.from('51548686230035037998152654').toHexString(), 16);
    // adjustBalance = combine2Uint128('40117792083912952383032', '51548686230035037998152654');
    // // change reserves
    // await setStorageAt(mockBancor.address, "0x5", adjustBalance);

    // const owner = await ethers.getSigner(ownerAddr);
    // const ownerAddr = "0x1647f8480c65528aff347602460c3ff9429cef4d"
    // await impersonateAccount([ownerAddr]);
    // await mockBancor.connect(owner).setConversionFee(2000);

    await BNT.connect(account).transfer(bancorAdapter.address, ethers.utils.parseEther('5'));

    console.log("before weth balance: " + await WETH.balanceOf(account.address));
    console.log("before bnt  balance: " + await BNT.balanceOf(bancorAdapter.address));

    rxResult = await bancorAdapter.sellBase(
        account.address,
        bancorAdapter.address,
        ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                BNT.address,
                ETH.address
            ]
        )
    );
    // console.log(rxResult);

    // targetAmount: targetReserveBalance * sourceAmount / (sourceReserveBalance + sourceAmount)
    // 50501462456674053205716100 * 400000000000000000 / (41536194569038260154218 + 400000000000000000) = 486332237687278140000
    // fee: targetAmount.mul(_conversionFee) / PPM_RESOLUTION
    // 486332237687278140000 * 1000 / 1000000 = 486332237687278140
    // user receive amount
    // 486332237687278140000 - 486332237687278140 = 485845905449590850000
    // after weth balance: 0
    console.log("after weth balance: " + await WETH.balanceOf(account.address));
    // after bnt  balance: 485845905449590857665
    console.log("after bnt  balance: " + await BNT.balanceOf(bancorAdapter.address));
}

async function main() {
    // ERC20 -> ERC20
    await executeMPH2BNT();

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