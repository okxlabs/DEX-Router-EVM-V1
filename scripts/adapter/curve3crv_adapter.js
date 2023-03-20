const { getConfig } = require("../config");
tokenConfig = getConfig("eth");

async function deployAdapter() {
    Curve3poolLPAdapter = await ethers.getContractFactory("Curve3poolLPAdapter");
    curve3poolLPAdapter = await Curve3poolLPAdapter.deploy(tokenConfig.contractd.Curve3CRVPoolLPToken.address);
    await curve3poolLPAdapter.deployed();
    return curve3poolLPAdapter
}

async function main() {
    Curve3poolLPAdapter = await deployAdapter();
    console.log(`Curve3poolLPAdapter: "${Curve3poolLPAdapter.address}"`);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });