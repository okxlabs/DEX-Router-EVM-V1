// account who pays the making assets
const PAYER = '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC'; // third account of hardhat network
// const PAYER = '0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6';  // OKC test account
const ACCOUNT3 = '0x8D8327Fe0F90332046eFD16027B08268e6555C7f';  // account 3
const PAYER_4 = '0x90F79bf6EB2c4f870365E785982E1f101E93b906'; // fourth account of hardhat network
const ETH_FORK_ACCOUNT = '0x7abE0cE388281d2aCF297Cb089caef3819b13448';  // fork account in eth main net
const OKC_FORK_ACCOUNT = '0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6';  // fork account in okc main net
const BACKEND = '0x15d34aaf54267db7d7c367839aaf71a00a2c6a65';   // fifth account of hardhat network
const CANCELER = '0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc';  // sixth account of hardhat network
// private key of the account who sign the quotes
// const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PRIVATE_KEY = '5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a'; // third account of hardhat network
// const OKC_PRIVATE_KEY = process.env.OKC_PRIVATE_KEY; // OKC test account

const PRIVATE_KEY_4 = '7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6'; // fourth account of hardhat network
const PRIVATE_KEY_BACKEND = '47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a'; // fifth account of hardhat network
const PRIVATE_KEY_CANCELER = '8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba'; //sixth account of hardhat network
// valid period of quotes for pulling rfq
const RFQ_VALID_PERIOD = 6000000;

// chain_id => market_maker_address
const MARKET_MAKER_ADDRESS = {
    1:'0x5FC8d32690cc91D4c39d9d3abcBD16989F875707',
    56:'0x478c2F5B9b7a4C24b5F7D4c4f727dBC67D2f8382',    //bsc
    66: '0x031F1aD10547b8dEB43A36e5491c06A93812023a',   //okc
    31337:'0x5FC8d32690cc91D4c39d9d3abcBD16989F875707'
}

const PMM_ADAPTER_ADDRESS = {
    1:'0x5FC8d32690cc91D4c39d9d3abcBD16989F875707',
    56:'0x51A66d4ec8Df5eF8Fc7915fe64c4cb070FA8e8a7',
    66: '0xd57df2A597933eE50633357882784dC776f68188',
    31337:'0x5FC8d32690cc91D4c39d9d3abcBD16989F875707'   
}

// http provider
const PROVIDER = 'https://bsc-dataseed1.binance.org';

// aggregation server url
// const AGGREGATION_SERVER_URL = 'kong-proxy.dev-okex.svc.dev.local';
const AGGREGATION_SERVER_URL = 'localhost';

// prefix of data to calculate hash for sign
const EIP712_PREFIX = '\x19\x01';

// keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
const EIP_712_DOMAIN_TYPEHASH = '0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f';

// keccak256("METAX MARKET MAKER")
const NAME_HASH = '0x9569cad29571f225e7f2c73ecd677d78be383da74efd13f4af2bade05dc1a8de';

// keccak256("1.0")
const VERSION_HASH = '0xe6bbd6277e1bf288eed5e8d1780f9a50b239e86b153736bceebccf4ea79d90b3';
// keccak256("2.0")
// const VERSION_HASH = '0x88f72b566ae0c96f6fffac4bc8ac74909f61512ac0c06a8124d5ed420d306f90';

// // _ORDER_TYPEHASH = keccak256("PMMSwapRequest(uint256 pathIndex,address payer,address fromToken,address toToken,uint256 fromTokenAmountMax,uint256 toTokenAmountMax,uint256 deadLine)")
// const ORDER_TYPEHASH = '0xfa0a4a288f6666a30e0dc0e865205ec9caac1b3c273b9f7d06f25e0e4b3af4f5';

// _ORDER_TYPEHASH = keccak256("PMMSwapRequest(uint256 pathIndex,address payer,address fromToken,address toToken,uint256 fromTokenAmountMax,uint256 toTokenAmountMax,uint256 salt,uint256 deadLine,bool isPushOrder,bytes extension)")
const ORDER_TYPEHASH = '0x5d068ce469dcf41137bcb6c3e1894e076ad915392f28fda19ba41601d33c32a6';

// PATHINDEX_TYPEHASH = keccak256("uint256[] pathIndex");
const PATHINDEX_TYPEHASH = '0xd6af40fe7727e56223847d4ed76576b369a54472264ba930c5b50d885f73abd6';
  
// path index of pushing quotes
const PUSH_QUOTE_PATH_INDEX = 0;

const DEFAULT_QUOTE =  {
    "pathIndex": 0, 
    "payer": PAYER, 
    "fromTokenAddress": "0x0000000000000000000000000000000000000000", 
    "toTokenAddress" : "0x0000000000000000000000000000000000000000", 
    "fromTokenAmountMax" : 0, 
    "toTokenAmountMax" : 0, 
    "salt" : 0, 
    "deadLine" : 0, 
    "isPushOrder" : false,
    "pmmAdapter" : "0x0000000000000000000000000000000000000000",
    "signature": '0x'
}

module.exports = {
    PAYER,
    PAYER_4,
    ACCOUNT3,
    ETH_FORK_ACCOUNT,
    OKC_FORK_ACCOUNT,
    PRIVATE_KEY,
    PRIVATE_KEY_4,
    PRIVATE_KEY_BACKEND,
    PRIVATE_KEY_CANCELER,
    PROVIDER,
    EIP712_PREFIX,
    EIP_712_DOMAIN_TYPEHASH,
    NAME_HASH,
    VERSION_HASH,
    ORDER_TYPEHASH,
    PATHINDEX_TYPEHASH,
    RFQ_VALID_PERIOD,
    AGGREGATION_SERVER_URL,
    PUSH_QUOTE_PATH_INDEX,
    MARKET_MAKER_ADDRESS,
    PMM_ADAPTER_ADDRESS,
    DEFAULT_QUOTE
}
