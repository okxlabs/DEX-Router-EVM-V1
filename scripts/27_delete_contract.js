const { ethers } = require("hardhat");
const deployed = require('./deployed');

async function main() {
    console.log(deployed);

    let contracts_eth = [
        "0xece0731756ab28e18c0c30b4c112501df5df81ec",
        "0x9d284e4b10f453a96b7f6299bb83ca48763ddc04",
        "0x15033134e98d6d60d5311986739bf46abcc72673",
        "0x55b35bf627944396f9950dd6bddadb5218110c76",
        "0x49b8092ce1c5db0ebf06a4ab5b21689450ceebda",
        "0x85f19d5d598fdbbd2ff02b74e1bd838434e2543c",
        "0x3a8eeb7c6120b69d1405af57ec625bcffa4c1787",
        "0x17096bc3fc2a35565897d9e81f4cde57e62167bc",
        "0xa0bd835f35bd241d786c4857cd1ec74d8bafaa45",
        "0x128a920a3721a63494170115f0b8964db8301008",
        "0xb79835c960f56fca5087e4e441c1271e7fcc48ae",
        "0xbdc23b7a719f682dca7056f8b126575782d2d4b4",
        "0x45b0a206a0ee358d929ceee782d63b2d7e748540",
        "0x6cea74418a513c95d0efa4d75349cb1f6ee7a335",
        "0xeb43104991fc7ec173a295a54276f2a575824ae3",
        "0x838a5832eb19cfce692809f5b2de44b15380cda2",
        "0x191b0e61ccbf3b26df76ca4321d9dee4c960e91e",
        "0xeD45294a96f94dD746aCb391910Aa3820a295fA6"]
    let contracts = [
        "0x838a5832eb19cfce692809f5b2de44b15380cda2",
        "0xb5666343ec776fcb65fd5ad879f64415e351d7c9",
        "0x478c2f5b9b7a4c24b5f7d4c4f727dbc67d2f8382",
        "0xb5ea4cd719d4c73e062d6195b17f703792543904",
        "0x5c9e126d741938a3f37341160f20a982ea584e30",
        "0xa920ee175fdf91cf88124e02ba17b1c087b24d56",
        "0xc8a514128358498f26ccddcc35926c0b16e153e3",
        "0x43c9361709be9ce6b1e33ac31426b08dbc09e58a",
        "0xf3de3c0d654fda23dad170f0f320a92172509127",
        "0xf73bd29daf60dfe09608d46f5e8eae87284fd3d3",
        "0xeD45294a96f94dD746aCb391910Aa3820a295fA6",
    ]
    for (let i = 0; i < contracts.length; i++) {
        let contract = contracts[i]
        let proxyAdmin = await ethers.provider.getStorageAt(contract, "0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103");
        proxyAdmin = ethers.utils.getAddress(proxyAdmin.slice(26))
        proxyAdmin = await ethers.getContractAt("ProxyAdmin", proxyAdmin)
        if (proxyAdmin.address != "0x0000000000000000000000000000000000000000") {
            let owner = await proxyAdmin.owner()
            console.log(contract, proxyAdmin.address, owner)
        } else {
            console.log(contract, proxyAdmin.address, "0x0000000000000000000000000000000000000000")
        }


    }






}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
