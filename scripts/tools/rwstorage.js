const { ethers } = require("hardhat");

setStorageAt = async (contract, slot, value) => {
    await network.provider.send("hardhat_setStorageAt", [
        contract,
        slot,
        value
    ]);
}

getStorageAt = async (contract, slot) => {
    const provider = ethers.getDefaultProvider();
    return await provider.getStorageAt(contract, slot);
};

module.exports = {
    setStorageAt,
    getStorageAt
}