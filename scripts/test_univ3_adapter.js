const { config } = require("dotenv");
const { ethers } = require("hardhat");
require("./tools");
const { getConfig } = require("./config");
tokenConfig = getConfig("eth");

async function execute_10000_InEth() {
    // Compare TX
    // https://cn.etherscan.com/tx/0xc45267e87258446ea5f8040b95b465ab08280a215c58afeea6ffd49c608a923e
    await setForkBlockNumber(14480328);

    const accountAddress = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270"
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress)

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    UniV3Adapter = await ethers.getContractFactory("UniV3Adapter");
    univ3Adapter = await UniV3Adapter.deploy(WETH.address);
    await univ3Adapter.deployed();

    RND = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.token.RND.baseTokenAddress
    )

    const poolAddr = "0x96b0837489d046A4f5aA9ac2FC9e086bD14Bac1E";

    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before RND Balance: " + await RND.balanceOf(account.address));

    // transfer 0.27 WETH to poolAddr
    await WETH.connect(account).transfer(univ3Adapter.address, ethers.utils.parseEther('0.27'));

    // WETH to RND token pool
    rxResult = await univ3Adapter.sellBase(
        account.address,
        poolAddr,
        ethers.utils.defaultAbiCoder.encode(
            ["uint160", "bytes"],
            [
                // "888971540474059905480051",
                0,
                ethers.utils.defaultAbiCoder.encode(
                    ["address", "address", "uint24"],
                    [
                        WETH.address,
                        RND.address,
                        10000
                    ]
                )
            ]
        )
    );

    console.log(rxResult);

    console.log("after WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("after RND Balance: " + await RND.balanceOf(account.address));
}

async function execute_10000_OutE() {
    // Compare TX
    // https://cn.etherscan.com/tx/0x081b1c212cf9cb160b95b124797bd1aba59187c99ff097a7b45df434641c7dea
    await setForkBlockNumber(14480161);

    const accountAddress = "0x6dcb9e95c6a5fe25e2bcd98fd793d89db386466c"
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress)

    // set account balance 0.6 eth
    await setBalance(accountAddress, "0x53444835ec580000");

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    UniV3Adapter = await ethers.getContractFactory("UniV3Adapter");
    univ3Adapter = await UniV3Adapter.deploy(WETH.address);
    await univ3Adapter.deployed();

    RND = await ethers.getContractAt(
        "MockERC20",
        config.token.RND
    )

    const poolAddr = "0x96b0837489d046A4f5aA9ac2FC9e086bD14Bac1E";

    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before RND Balance: " + await RND.balanceOf(account.address));

    // transfer 150000000 RND to poolAddr
    await RND.connect(account).transfer(univ3Adapter.address, ethers.utils.parseEther('150000000'));

    // RND to WETH token pool
    rxResult = await univ3Adapter.sellBase(
        account.address,
        poolAddr,
        ethers.utils.defaultAbiCoder.encode(
            ["uint160", "bytes"],
            [
                "916040352311236163014697",
                ethers.utils.defaultAbiCoder.encode(
                    ["address", "address", "uint24"],
                    [
                        RND.address,
                        WETH.address,
                        10000
                    ]
                )
            ]
        )
    );

    console.log(rxResult);

    console.log("after WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("after RND Balance: " + await RND.balanceOf(account.address));
}

async function execute_3000() {
    // Compare TX
    // https://etherscan.io/tx/0xee9aaad70cb0a57b5e5c8e863846e72bd0847409ba6e7a52d7f36b23c7978109
    await setForkBlockNumber(14480567);

    const accountAddress = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270"
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress)

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    UniV3Adapter = await ethers.getContractFactory("UniV3Adapter");
    univ3Adapter = await UniV3Adapter.deploy(WETH.address);
    await univ3Adapter.deployed();

    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    const poolAddr = "0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8";

    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before USDC Balance: " + await USDC.balanceOf(account.address));

    // transfer 0.06325 WETH to poolAddr
    await WETH.connect(account).transfer(univ3Adapter.address, ethers.utils.parseEther('0.06325'));

    // WETH to USDC token pool 0.3%
    rxResult = await univ3Adapter.sellBase(
        account.address,
        poolAddr,
        ethers.utils.defaultAbiCoder.encode(
            ["uint160", "bytes"],
            [
                "1353119835187591902566005712305392",
                ethers.utils.defaultAbiCoder.encode(
                    ["address", "address", "uint24"],
                    [
                        WETH.address,
                        USDC.address,
                        3000
                    ]
                )
            ]
        )
    );

    console.log(rxResult);

    console.log("after WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(account.address));

    // transfer 216.193399 USDC to poolAddr
    await USDC.connect(account).transfer(univ3Adapter.address, ethers.utils.parseUnits('216.193399', 6));

    // USDC to WETH token pool 0.3%
    rxResult = await univ3Adapter.sellBase(
        account.address,
        poolAddr,
        ethers.utils.defaultAbiCoder.encode(
            ["uint160", "bytes"],
            [
                0,
                ethers.utils.defaultAbiCoder.encode(
                    ["address", "address", "uint24"],
                    [
                        USDC.address,
                        WETH.address,
                        3000
                    ]
                )
            ]
        )
    );

    console.log(rxResult);

    console.log("after WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(account.address));
}

async function execute_500() {
    // Compare TX
    // https://etherscan.io/tx/0xb76bb67f47e87e44e2fa5624dd664182e393c55be88c3daae541e6a061256ad5
    await setForkBlockNumber(14480632);

    const accountAddress = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270"
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress)

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    UniV3Adapter = await ethers.getContractFactory("UniV3Adapter");
    univ3Adapter = await UniV3Adapter.deploy(WETH.address);
    await univ3Adapter.deployed();

    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    const poolAddr = "0x88e6a0c2ddd26feeb64f039a2c41296fcb3f5640";

    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before USDC Balance: " + await USDC.balanceOf(account.address));

    // transfer 1.5 WETH to poolAddr
    await WETH.connect(account).transfer(univ3Adapter.address, ethers.utils.parseEther('1.5'));

    // WETH to USDC token pool 0.05%
    rxResult = await univ3Adapter.sellBase(
        account.address,
        poolAddr,
        ethers.utils.defaultAbiCoder.encode(
            ["uint160", "bytes"],
            [
                "1352677154677147303342166828249157",
                ethers.utils.defaultAbiCoder.encode(
                    ["address", "address", "uint24"],
                    [
                        WETH.address,
                        USDC.address,
                        500
                    ]
                )
            ]
        )
    );

    console.log(rxResult);

    console.log("after WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(account.address));

    // transfer 5143.348549 USDC to poolAddr
    await USDC.connect(account).transfer(univ3Adapter.address, ethers.utils.parseUnits('5143.348549', 6));

    // USDC to WETH token pool 0.05%
    rxResult = await univ3Adapter.sellBase(
        account.address,
        poolAddr,
        ethers.utils.defaultAbiCoder.encode(
            ["uint160", "bytes"],
            [
                0,
                ethers.utils.defaultAbiCoder.encode(
                    ["address", "address", "uint24"],
                    [
                        USDC.address,
                        WETH.address,
                        500
                    ]
                )
            ]
        )
    );

    console.log(rxResult);

    console.log("after WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(account.address));
}

async function execute_100() {
    // Compare TX
    // https://etherscan.io/tx/0x3bf9cb1c7a24b532bdf9b9feb7678511d4cdc0f2d0df2c51d4d18c30c42cc5e5
    await setForkBlockNumber(14480619);

    const accountAddress = "0x29feaa65869e737ad53bfc2325bd8ffed8d27a07"
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress)

    WETH = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.WETH.baseTokenAddress
    )

    UniV3Adapter = await ethers.getContractFactory("UniV3Adapter");
    univ3Adapter = await UniV3Adapter.deploy(WETH.address);
    await univ3Adapter.deployed();

    USDT = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDT.baseTokenAddress
    )
    USDC = await ethers.getContractAt(
        "MockERC20",
        tokenConfig.tokens.USDC.baseTokenAddress
    )

    const poolAddr = "0x3416cf6c708da44db2624d63ea0aaef7113527c6";

    console.log("before USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("before USDC Balance: " + await USDC.balanceOf(account.address));

    // transfer 230000 USDT to poolAddr
    await USDT.connect(account).transfer(univ3Adapter.address, ethers.utils.parseUnits('230000', 6));

    // USDT to USDC token pool 0.01%
    rxResult = await univ3Adapter.sellBase(
        account.address,
        poolAddr,
        ethers.utils.defaultAbiCoder.encode(
            ["uint160", "bytes"],
            [
                "79201721839612352613078275827",
                ethers.utils.defaultAbiCoder.encode(
                    ["address", "address", "uint24"],
                    [
                        USDT.address,
                        USDC.address,
                        100
                    ]
                )
            ]
        )
    );

    console.log(rxResult);

    console.log("after USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(account.address));

    // transfer 230130.773044 USDC to poolAddr
    await USDC.connect(account).transfer(univ3Adapter.address, ethers.utils.parseUnits('230130.773044', 6));

    // USDC to WETH token pool 0.05%
    rxResult = await univ3Adapter.sellBase(
        account.address,
        poolAddr,
        ethers.utils.defaultAbiCoder.encode(
            ["uint160", "bytes"],
            [
                0,
                ethers.utils.defaultAbiCoder.encode(
                    ["address", "address", "uint24"],
                    [
                        USDC.address,
                        USDT.address,
                        100
                    ]
                )
            ]
        )
    );

    console.log(rxResult);

    console.log("after USDT Balance: " + await USDT.balanceOf(account.address));
    console.log("after USDC Balance: " + await USDC.balanceOf(account.address));
}

async function main() {
  await execute_100();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
