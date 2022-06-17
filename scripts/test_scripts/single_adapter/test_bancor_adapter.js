const { config } = require("dotenv");
const { ethers } = require("hardhat");
require("../../tools");
const { getConfig } = require("../../config");
tokenConfig = getConfig("eth");

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
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    BancorAdapter = await ethers.getContractFactory("BancorAdapter");
    bancorAdapter = await BancorAdapter.deploy(BancorNetwork, WETH.address);
    await bancorAdapter.deployed();

    // console.log(`bancorAdapter deployed: ${bancorAdapter.address}`);

    MPH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.MPH.baseTokenAddress
    )
    BNT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.BNT.baseTokenAddress
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
        tokenConfig.tokens.WETH.baseTokenAddress
    )
    BNT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.BNT.baseTokenAddress
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
        tokenConfig.tokens.WETH.baseTokenAddress
    )
    BNT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.BNT.baseTokenAddress
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



async function debug() {

    // debug address(this): 0xf090f16dec8b6d24082edd25b1c8d26f2bc86128
    // debug poolAddress: 0x79d89b87468a59b9895b31e3a373dc5973d60065
    // debug adapter fromToken address: 0xdac17f958d2ee523a2206206994597c13d831ec7
    // debug adapter fromToken balance Of: 1500862747328
    // debug sourceToken: 0xdac17f958d2ee523a2206206994597c13d831ec7
    // debug targetToken: 0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c
  
    const poolAddress = "0x79d89b87468a59b9895b31e3a373dc5973d60065";
    const accountAddress = "0xeea81c4416d71cef071224611359f6f99a4c4294";
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress);
  
  
    sourceToken = await ethers.getContractAt(
      "MockERC20",
      "0xdac17f958d2ee523a2206206994597c13d831ec7"
    )
    
    targetToken = await ethers.getContractAt(
      "MockERC20",
      "0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c"
    )
  
    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    const ETH = { address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" }
    const BancorNetwork = "0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0";

    BancorAdapter = await ethers.getContractFactory("BancorAdapter");
    BancorAdapter = await BancorAdapter.deploy(BancorNetwork, WETH.address);
    await BancorAdapter.deployed();
  
    console.log("before sourceToken Balance: " + await sourceToken.balanceOf(account.address));
    await sourceToken.connect(account).transfer(BancorAdapter.address, 1500862747328);
  
    console.log("before sourceToken Balance: " + await sourceToken.balanceOf(BancorAdapter.address));
    console.log("before targetToken Balance: " + await targetToken.balanceOf(account.address));
  
    // WETH to LPAL token pool vault
    rxResult = await BancorAdapter.sellBase(
      account.address,                                // receive token address
      poolAddress,   // AAVE-WETH Pool
      ethers.utils.defaultAbiCoder.encode(
        ["address", "address"],
        [
          "0xdac17f958d2ee523a2206206994597c13d831ec7",                               // from token address 
          "0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c"                               // to token address
        ]
      )
    );
    // console.log(rxResult);
  
    console.log("after usdt balance: " + await sourceToken.balanceOf(account.address));
    console.log("after bnt  balance: " + await targetToken.balanceOf(account.address));
  
  }
async function main() {
    // // // ERC20 -> ERC20
    // await executeMPH2BNT();

    // // WETH -> ETH -> ERC20
    // await executeETH2BNT();

    // // ERC20 -> ETH -> WETH
    // await executeBNT2ETH();

    await debug();
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });