require("./rwstorage");

getArrayData = async (contract, slot) => {
    let len = await getStorageAt(contract, slot);
    let elements = [];
    let elementHash = await ethers.utils.keccak256(ethers.utils.hexZeroPad(slot, 32));
    for (let i = 0; i < len; i++) {
        element = await getStorageAt(contract, elementHash);
        elements.push(element);
        elementHash = ethers.BigNumber.from(elementHash).add(1).toHexString()
    }
    return elements;
}

getCompressData = async (contract, slot) => {
    // 压缩的情况
    // 0x00000000000003e800007530b1cd6e4153b2a390cf00a6556b0fc1458c4a5533
    r = await getStorageAt(contract, slot);
    return r;
}

getMappingData = async (contract, keys, values) => {
    // ["bytes", "uint256"],
    // ["0x0000000000000000000000001f573d6fb3f13d689ff844b4ce37794d79a7ff1c", 8]
    let hashkey = await ethers.utils.solidityKeccak256(
        keys,
        values
    );
    r = await getStorageAt(contract, hashkey);
    return r;
}

combine2Uint128 = (value1, value2) => {
    hexValue1 = ethers.utils.hexZeroPad(ethers.BigNumber.from(value1).toHexString(), 16);
    hexValue2 = ethers.utils.hexZeroPad(ethers.BigNumber.from(value2).toHexString(), 16);
    return hexValue1 + hexValue2.replace('0x', '');
}

module.exports = {
    getArrayData,
    getCompressData,
    getMappingData,
    combine2Uint128
}