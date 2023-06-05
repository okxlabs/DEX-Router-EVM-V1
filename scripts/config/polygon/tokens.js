
const USDC  = {
    name: "USDC",
    decimals: 6,
    baseTokenAddress: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',
}

const WETH = {
    name: "WETH",
    decimals: 18,
    baseTokenAddress: '0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619',
}

const TEL = {
    name: "TEL",
    decimals: 2,
    baseTokenAddress: '0xdF7837DE1F2Fa4631D716CF2502f8b230F1dcc32',
}

const WMATIC = {
    name: "WMATIC",
    decimals: 18,
    baseTokenAddress: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
}

const MATIC = {
    name: "MATIC",
    decimals: 18,
    baseTokenAddress: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
}

const USDT = {
    name: "USDT",
    decimals: 6,
    baseTokenAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
}

const amUSDT = {
    name: "amUSDT",//aave matic USDT （aaveV2 atoken on polygon）
    decimals: 6,
    baseTokenAddress: '0x60D55F02A771d515e077c9C2403a1ef324885CeC',
}

const aPolUSDC = {
    name: "aPolUSDC",//aave polygon USDC （aaveV3 atoken on polygon）
    decimals: 6,
    baseTokenAddress: '0x625E7708f30cA75bfd92586e17077590C60eb4cD',
}

const aEthUSDC = {
    name: "aEthUSDC",//aave Ethereum USDC （aaveV3 atoken on eth）
    decimals: 6,
    baseTokenAddress: '0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c',
}

module.exports = {
    WETH,
    TEL,
    USDC,
    WMATIC,
    MATIC,
    USDT,
    amUSDT,
    aPolUSDC,
    aEthUSDC
}