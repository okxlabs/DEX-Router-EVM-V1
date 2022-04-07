const Web3 = require("web3");
const { ecsign } = require('ethereumjs-util');
const { PROVIDER, PRIVATE_KEY, NAME_HASH, VERSION_HASH, EIP712_PREFIX, EIP_712_DOMAIN_TYPEHASH } = require("./constants");
const web3 = new Web3(new Web3.providers.HttpProvider(PROVIDER));

var getCurBlockTs = async function(){
    let latestBlock = await web3.eth.getBlock('latest');
    let ts = latestBlock.timestamp;
    return ts;
}

var getLocalTs = function(){
    return Math.floor(Date.now()/1000);
}

var abiEncodeDomainSeparator = function(chain_id, adapter_address){
    return web3.eth.abi.encodeParameter(
        {
            "":{
                "domain_typehash": 'bytes32',
                "name_hash": 'bytes32',
                "version_hash": 'bytes32',
                "chain_id": 'uint256',
                "adapter_address": 'address'
            }
        },
        {
            "domain_typehash": EIP_712_DOMAIN_TYPEHASH,
            "name_hash": NAME_HASH,
            "version_hash": VERSION_HASH,
            "chain_id": chain_id,
            "adapter_address": adapter_address
        }
    )
}

// object => string
var abiEncodeMessage = function(obj){
    // console.log("obj", obj);
    let abiEncodedMessage = web3.eth.abi.encodeParameter(
        {
            "" : {
                "orderTypeHash" : 'bytes32',
                "pathIndex": 'uint256',
                "payer" : 'address',
                "fromTokenAddress" : 'address',
                "toTokenAddress" : 'address',
                "fromTokenAmountMax" : 'uint256',
                "toTokenAmountMax" : 'uint256',
                "salt" : 'uint256',
                "deadLine" : 'uint256',
                "isPushOrder" : 'bool'
            }
        },
        {
            "orderTypeHash" : obj.orderTypeHash,
            "pathIndex": obj.pathIndex.toLocaleString('fullwide', { useGrouping: false }),
            "payer" : obj.payer,
            "fromTokenAddress" : obj.fromTokenAddress,
            "toTokenAddress" : obj.toTokenAddress,
            "fromTokenAmountMax" : obj.fromTokenAmountMax.toLocaleString('fullwide', { useGrouping: false }),
            "toTokenAmountMax" : obj.toTokenAmountMax.toLocaleString('fullwide', { useGrouping: false }),
            "salt" : obj.salt,
            "deadLine" : obj.deadLine,
            "isPushOrder" : obj.isPushOrder   
        }
    );
    return abiEncodedMessage;
}

// string => hash
var keccak256 = function (message){
    return web3.utils.keccak256(message);
}

// final hash for signature
var hashToSign = function (domain_separator, hashOrder){
    return web3.utils.soliditySha3(EIP712_PREFIX, domain_separator, hashOrder);
}

// sign 
var sign = function (digest){
    let {r,s,v} = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(PRIVATE_KEY,'hex'));
    // r = '0x' + r.toString('hex');
    // s = '0x' + s.toString('hex');
    signature ='0x' + r.toString('hex') + s.toString('hex') + parseInt(v).toString(16);
    // console.log("signature",signature);
    return signature;
}

module.exports = {
    web3,
    getCurBlockTs, 
    getLocalTs, 
    abiEncodeDomainSeparator,
    abiEncodeMessage,
    keccak256,
    hashToSign,
    sign
};



