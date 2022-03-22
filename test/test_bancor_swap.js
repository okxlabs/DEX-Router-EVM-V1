const { ethers } = require("hardhat");

//block-number 14395835
// async function main() {
//
//     await hre.network.provider.request({
//         method: "hardhat_impersonateAccount",
//         params: ["0x9b29b87b8428fab4228a16d8d38a6482cb7e68eb"],
//     });
//
//     const signer = await ethers.getSigner("0x9b29b87b8428fab4228a16d8d38a6482cb7e68eb")
//     // r = await signer.getBalance();
//     // console.log("balance : " + r);
//
//     BancorAdapter = await ethers.getContractFactory("BancorAdapter");
//     bancorAdapter = await upgrades.deployProxy(BancorAdapter);
//     await bancorAdapter.deployed();
//
//     console.log(`bancorAdapter deployed: ${bancorAdapter.address}`);
//
//     mph = await ethers.getContractAt(
//         "MockERC20",
//         "0x8888801aF4d980682e47f1A9036e589479e835C5"
//     )
//     bnt = await ethers.getContractAt(
//         "MockERC20",
//         "0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C"
//     )
//
//     await mph.connect(signer).transfer(bancorAdapter.address, ethers.utils.parseEther('100'));
//     console.log(await mph.balanceOf(bancorAdapter.address) + "")
//     console.log(await bnt.balanceOf(bancorAdapter.address) + "")
//     r = await bancorAdapter.sellQuote(
//         bancorAdapter.address,
//         "0xdf3fdfbce72da4fd42e7cfde7249e15357c7d808",
//         ethers.utils.defaultAbiCoder.encode(
//             ["address", "address"],
//             [
//                 "0x8888801aF4d980682e47f1A9036e589479e835C5",
//                 "0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C"
//             ]
//         )
//     );
//     console.log(r);
//     console.log(await mph.balanceOf(bancorAdapter.address) + "")
//     console.log(await bnt.balanceOf(bancorAdapter.address) + "")
// }

//block-number 14429782
async function main() {

    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: ["0x49ce02683191fb39490583a7047b280109cab9c1"],
    });

    const signer = await ethers.getSigner("0x49ce02683191fb39490583a7047b280109cab9c1")
    // r = await signer.getBalance();
    // console.log("balance : " + r);

    BancorAdapter = await ethers.getContractFactory("BancorAdapter");
    bancorAdapter = await upgrades.deployProxy(BancorAdapter);
    await bancorAdapter.deployed();

    console.log(`bancorAdapter deployed: ${bancorAdapter.address}`);

    mph = await ethers.getContractAt(
        "MockERC20",
        "0x8888801aF4d980682e47f1A9036e589479e835C5"
    )
    bnt = await ethers.getContractAt(
        "MockERC20",
        "0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C"
    )
    weth = await ethers.getContractAt(
        "MockERC20",
        "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    )

    await weth.connect(signer).transfer(bancorAdapter.address, ethers.utils.parseEther('0.4'));
    console.log(await weth.balanceOf(bancorAdapter.address) + "")
    console.log(await bnt.balanceOf(bancorAdapter.address) + "")
    r = await bancorAdapter.sellBase(
        bancorAdapter.address,
        "0x4c9a2bD661D640dA3634A4988a9Bd2Bc0f18e5a9",
        ethers.utils.defaultAbiCoder.encode(
            ["address", "address"],
            [
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
                "0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C"
            ]
        )
    );
    console.log(r);
    console.log(await weth.balanceOf(bancorAdapter.address) + "")
    console.log(await bnt.balanceOf(bancorAdapter.address) + "")
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });