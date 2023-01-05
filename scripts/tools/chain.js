const ALCHEMY_KEY = process.env.ALCHEMY_KEY || 'xALpTiRVSIOkY1V1FPmG52PYkKzHfhyk';
const MORALIS_KEY = process.env.MORALIS_KEY || '';
const { network } = require("hardhat");
const hre = require("hardhat");

function getNetworkURL(net) {
    if (net == 'okc') {
        return 'http://35.72.176.238:26659'
    } else if (net == 'okc_test') {
        return 'https://exchaintestrpc.okex.org'
    } else if (net == 'eth') {
        return ALCHEMY_KEY == '' ? "https://rpc.ankr.com/eth" : `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_KEY}`
    } else if (net == 'bsc') {
        return `https://rpc.ankr.com/bsc`
    } else if (net == 'polygon') {
        return ALCHEMY_KEY == '' ? `https://rpc.ankr.com/polygon` : `https://polygon-mainnet.g.alchemy.com/v2/${ALCHEMY_KEY}`
    } else if (net == 'avax') {
        //  return `https://speedy-nodes-nyc.moralis.io/e88a69edd7e8b87e8c86975b/avalanche/mainnet/archive`
        return `https://avalancheapi.terminet.io/ext/bc/C/rpc`
        // return `https://rpc.ankr.com/avalanche`
    } else if (net == 'artibrum') {
        return ALCHEMY_KEY == '' ? `https://rpc.ankr.com/arbitrum` : `https://arb-mainnet.g.alchemy.com/v2/${ALCHEMY_KEY}`
    } else {
        return 'http://127.0.0.1:8545'
    }
}

setForkNetWorkAndBlockNumber = async (net, targetBlockNumber) => {
    url = getNetworkURL(net)
    await network.provider.request({
        method: "hardhat_reset",
        params: [
            {
                forking: {
                    jsonRpcUrl: url,
                    blockNumber: targetBlockNumber,
                }
            },
        ],
    });
}

setForkBlockNumber = async (targetBlockNumber) => {
    await network.provider.request({
        method: "hardhat_reset",
        params: [
            {
                forking: {
                    // jsonRpcUrl: `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_KEY}`,
                    jsonRpcUrl: `https://rpc.ankr.com/eth`,
                    blockNumber: targetBlockNumber,
                },
            },
        ],
    });
}

startMockAccount = async (account) => {
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: account,
    });
}

stopMockAccount = async (account) => {
    await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: account,
    });
}

setBalance = async (user, amount) => {
    const isHex = (amount.toString()).startsWith('0x')
    await network.provider.send("hardhat_setBalance", [
        user,
        isHex ? amount : "0x" + parseInt(amount).toString(16)
    ]);
}

setNonce = async (user, nonce) => {
    await network.provider.send("hardhat_setNonce", [
        user,
        nonce,
    ]);
}

setNextBlockTimeStamp = async (timestamp) => {
    await network.provider.send("evm_setNextBlockTimestamp", [timestamp]);
}



module.exports = {
    setForkBlockNumber,
    startMockAccount,
    stopMockAccount,
    setBalance,
    setNonce,
    setNextBlockTimeStamp,
    setForkNetWorkAndBlockNumber
}
