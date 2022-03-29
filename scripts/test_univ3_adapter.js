const { ethers } = require("hardhat");
require("./tools");

async function execute() {
    // Compare TX
    // https://cn.etherscan.com/tx/0xb63ee1e2e75ca9fbd87eccebd1f61ef324ed4085b223c20d1f6ff67f178c2f01
    await setForkBlockNumber(14478631);

    const accountAddress = "0x9199Cc44CF7850FE40081ea6F2b010Fee1088270"
    await startMockAccount([accountAddress]);
    const account = await ethers.getSigner(accountAddress)

    WETH = await ethers.getContractAt(
        "MockERC20",
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    )

    UniV3Adapter = await ethers.getContractFactory("UniV3Adapter");
    univ3Adapter = await UniV3Adapter.deploy(WETH.address);
    await univ3Adapter.deployed();

    RND = await ethers.getContractAt(
        "MockERC20",
        "0x1c7E83f8C581a967940DBfa7984744646AE46b29"
    )

    const poolAddr = "0x96b0837489d046A4f5aA9ac2FC9e086bD14Bac1E";

    console.log("before WETH Balance: " + await WETH.balanceOf(account.address));
    console.log("before RND Balance: " + await RND.balanceOf(account.address));

    // transfer 1.5 WETH to poolAddr
    await WETH.connect(account).transfer(poolAddr, ethers.utils.parseEther('1.5'));

    // WETH to RND token pool
    rxResult = await univ3Adapter.sellQuote(
        account.address,
        poolAddr,
        ethers.utils.defaultAbiCoder.encode(
            ["uint160", "bytes"],
            [
                "888971540474059905480051",
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

async function main() {
  await execute();
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
