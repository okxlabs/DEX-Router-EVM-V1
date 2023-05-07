const { ethers } = require('ethers');
const { setn } = require('./utils');

const OrderRFQ = [
    { name: 'info', type: 'uint256' },
    { name: 'makerAsset', type: 'address' },
    { name: 'takerAsset', type: 'address' },
    { name: 'maker', type: 'address' },
    { name: 'allowedSender', type: 'address' },
    { name: 'makingAmount', type: 'uint256' },
    { name: 'takingAmount', type: 'uint256' },
];

const ABIOrderRFQ = {
    type: 'tuple',
    name: 'order',
    components: OrderRFQ,
};

// const name = 'OKX PMM Protocol';
// const version = '1.0';
const name = '1inch Aggregation Router';
const version = '5';
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

function buildOrderRFQ(
    info,
    makerAsset,
    takerAsset,
    maker,
    makingAmount,
    takingAmount,
    allowedSender = ZERO_ADDRESS,
) {
    return {
        info,
        makerAsset,
        takerAsset,
        maker,
        allowedSender,
        makingAmount,
        takingAmount,
    };
}

function buildOrderRFQData(chainId, verifyingContract, order) {
    return {
        domain: { name, version, chainId, verifyingContract },
        types: { OrderRFQ },
        value: order,
    };
}

async function signOrderRFQ(order, chainId, target, wallet) {
    const orderData = buildOrderRFQData(chainId, target, order);
    return await wallet._signTypedData(orderData.domain, orderData.types, orderData.value);
}

function compactSignature(signature) {
    const sig = ethers.utils.splitSignature(signature);
    return {
        r: sig.r,
        vs: sig._vs,
    };
}

function unwrapWeth(amount) {
    return setn(BigInt(amount), 252, 1).toString();
}

function makingAmount(amount) {
    return setn(BigInt(amount), 255, 1).toString();
}

function takingAmount(amount) {
    return BigInt(amount).toString();
}

module.exports = {
    ABIOrderRFQ,
    buildOrderRFQ,
    buildOrderRFQData,
    signOrderRFQ,
    compactSignature,
    makingAmount,
    takingAmount,
    unwrapWeth,
    name,
    version,
};
