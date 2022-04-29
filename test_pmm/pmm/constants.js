// account who pays the making assets
const PAYER = '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC'; // third account of hardhat network
const PAYER_4 = '0x90F79bf6EB2c4f870365E785982E1f101E93b906'; // fourth account of hardhat network
const BACKEND = '0x15d34aaf54267db7d7c367839aaf71a00a2c6a65';   // fifth account of hardhat network
// private key of the account who sign the quotes
// const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PRIVATE_KEY = '5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a'; // third account of hardhat network
const PRIVATE_KEY_4 = '7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6'; // fourth account of hardhat network
const PRIVATE_KEY_BACKEND = '47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a'; // fifth account of hardhat network
// valid period of quotes for pulling rfq
const RFQ_VALID_PERIOD = 600;

// chain_id => market_maker_address
const MARKET_MAKER_ADDRESS = {
    1:'0x488aa52C39A4ED0291F50C147886221322DbEB68',
    56:'0x488aa52C39A4ED0291F50C147886221322DbEB68',
    31337:'0x5FC8d32690cc91D4c39d9d3abcBD16989F875707'
}

const PMM_ADAPTER_ADDRESS = {
    1:'0x488aa52C39A4ED0291F50C147886221322DbEB68',
    56:'0x488aa52C39A4ED0291F50C147886221322DbEB68',
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

//ORDER_TYPEHASH = keccak256("PMMSwapRequest(uint256 pathIndex,address payer,address fromToken,address toToken,uint256 fromTokenAmountMax,uint256 toTokenAmountMax,uint256 salt,uint256 deadLine,bool isPushOrder,bytes extension)")
const ORDER_TYPEHASH = '0x5d068ce469dcf41137bcb6c3e1894e076ad915392f28fda19ba41601d33c32a6';

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
    PRIVATE_KEY,
    PRIVATE_KEY_4,
    PRIVATE_KEY_BACKEND,
    PROVIDER,
    EIP712_PREFIX,
    EIP_712_DOMAIN_TYPEHASH,
    NAME_HASH,
    VERSION_HASH,
    ORDER_TYPEHASH,
    RFQ_VALID_PERIOD,
    AGGREGATION_SERVER_URL,
    PUSH_QUOTE_PATH_INDEX,
    MARKET_MAKER_ADDRESS,
    PMM_ADAPTER_ADDRESS,
    DEFAULT_QUOTE
}
