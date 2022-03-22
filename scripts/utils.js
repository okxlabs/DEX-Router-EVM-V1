const ALCHEMY_KEY = process.env.ALCHEMY_KEY || '';

module.exports = setForkBlockNumber = async (targetBlockNumber) => {
    await network.provider.request({
        method: "hardhat_reset",
        params: [
            {
                forking: {
                    jsonRpcUrl: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_KEY}`,
                    blockNumber: targetBlockNumber,
                },
            },
        ],
    });
}

module.exports = impersonateAccount = async (accounts) => {
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: accounts,
    });
}

module.exports = setBalance = async (user, amount) => {
    await network.provider.send("hardhat_setBalance", [
        user,
        amount,
    ]);
}

module.exports = setStorageAt = async (contract, solt, vaule) => {
    await network.provider.send("hardhat_setStorageAt", [
        contract,
        solt,
        value
    ]);
}