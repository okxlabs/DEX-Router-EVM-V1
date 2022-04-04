// account who pays the making assets
const PAYER = '0x488aa52C39A4ED0291F50C147886221322DbEB68';

// private key of the account who sign the quotes
const PRIVATE_KEY = 'f9adc1675174d7723ab15dd3e7b427af0030e0a16d1a0baa5b9ba206610ad8fb';

// valid period of quotes for pulling rfq
const RFQ_VALID_PERIOD = 60;

// chain_id => adapter_address
const ADAPTER_ADDRESS = {
    1:'0x488aa52C39A4ED0291F50C147886221322DbEB68',
    56:'0x488aa52C39A4ED0291F50C147886221322DbEB68'
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

// keccak256("METAX PMM Adapter")
const NAME_HASH = '0xb62baa298dba2097375700cb4111f22d2780f2b74a67bd22ae424889eea981f3';

// keccak256("1.0")
const VERSION_HASH = '0xe6bbd6277e1bf288eed5e8d1780f9a50b239e86b153736bceebccf4ea79d90b3';

// keccak256("SwapRequest(address payer,address fromToken,address toToken,uint256 fromTokenAmount,uint256 toTokenAmount,bytes32 salt,uint256 deadLine)")
const ORDER_TYPEHASH = '0xe1fce3a3913fd90b2538674cd4e405e3960199c2869b49f61f7e532cb3f7fce0';

// path index of pushing quotes
const PUSH_QUOTE_PATH_INDEX = 0;

const DEFAULT_QUOTE =  {
    "infos":{
        "pathIndex": 0, 
        "payer": PAYER, 
        "fromTokenAddress": "0x0000000000000000000000000000000000000000", 
        "toTokenAddress" : "0x0000000000000000000000000000000000000000", 
        "fromTokenAmountMax" : 0, 
        "toTokenAmountMax" : 0, 
        "salt" : 0, 
        "deadLine" : 0, 
        "isPushOrder" : false
    },
    "signature": '0x'
}

module.exports = {
    PAYER,
    PRIVATE_KEY,
    PROVIDER,
    EIP712_PREFIX,
    EIP_712_DOMAIN_TYPEHASH,
    NAME_HASH,
    VERSION_HASH,
    ORDER_TYPEHASH,
    RFQ_VALID_PERIOD,
    AGGREGATION_SERVER_URL,
    PUSH_QUOTE_PATH_INDEX,
    ADAPTER_ADDRESS,
    DEFAULT_QUOTE
}
