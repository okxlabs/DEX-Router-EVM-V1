/**
* quoter.js
* There are two types of quote:
* 1. quote for pulling order
*    When a user try to swap in dex, the aggregation server will send a request to market maker
*    and try to pull quotes for user, prices from dexes will also be analized at the same time.
* 2. quote to push order
*    Market maker could also push a quote to aggregation server before any rfq received, and 
*    this quote might be used when a user try to swap whitin its deadline.
*/

const getToTokenAmount = require("./strategy");
const { keccak256, defaultAbiCoder, solidityPack } = require('ethers/lib/utils');
const { ecsign } = require('ethereumjs-util');
const {
    PAYER,
    ORDER_TYPEHASH,
    RFQ_VALID_PERIOD,
    PUSH_QUOTE_PATH_INDEX,
    ADAPTER_ADDRESS,
    DEFAULT_QUOTE,
    PRIVATE_KEY, 
    NAME_HASH, 
    VERSION_HASH, 
    EIP_712_DOMAIN_TYPEHASH
} = require("./constants");

const getDomainSeparator = function (chainId, marketMaker){
    return keccak256(defaultAbiCoder.encode(
        ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
        [EIP_712_DOMAIN_TYPEHASH, NAME_HASH, VERSION_HASH, chainId, marketMaker]
    ));
}

// rfq => infos to be signed
const getPullInfosToBeSigned = function (pull_data) {
    let quantity = pull_data.length;
    let localTs = getLocalTs();
    let pullInfosToBeSigned = [];
    let chainId = [];
    let marketMaker = [];

    for (let i = 0; i < quantity; i++) {
        let chunk = pull_data[i];
        let toTokenAmount = getToTokenAmount(chunk);

        pullInfosToBeSigned[i] = {
            "orderTypeHash" : ORDER_TYPEHASH,
            "pathIndex" : chunk.pathIndex,
            "payer" : PAYER,
            "fromTokenAddress" : chunk.fromTokenAddress,
            "toTokenAddress" : chunk.toTokenAddress,
            "fromTokenAmountMax" : Number(chunk.fromTokenAmount),
            "toTokenAmountMax" : Number(toTokenAmount),
            "salt" : Number(localTs),
            "deadLine" : localTs + RFQ_VALID_PERIOD,
            "isPushOrder" : false
        };

        chainId[i] = chunk.chainId;
        marketMaker[i] = chunk.marketMaker;
    }

    return { pullInfosToBeSigned, chainId, marketMaker };
}

// order to be pushed => infos to be signed
const getPushInfosToBeSigned = function (push_data){
    let quantity = push_data.length;
    let localTs = getLocalTs();
    let pushInfosToBeSigned = [];
    let chainId = [];
    let marketMaker = [];

    for (let i = 0; i < quantity; i++){
        let chunk = push_data[i];
        pushInfosToBeSigned[i] = {
            "orderTypeHash" : ORDER_TYPEHASH,
            "pathIndex" : PUSH_QUOTE_PATH_INDEX,
            "payer" : PAYER,
            "fromTokenAddress" : chunk.takerWantToken,
            "toTokenAddress" : chunk.makerSellToken,
            "fromTokenAmountMax" : chunk.makeAmountMax * chunk.PriceMin,
            "toTokenAmountMax" : chunk.makeAmountMax,
            "salt" : Number(localTs),
            "deadLine" : Number(localTs) + Number(chunk.pushQuoteValidPeriod),
            "isPushOrder" : true
        };
        chainId[i] = chunk.chainId;
        marketMaker[i] = ADAPTER_ADDRESS[chunk.chainId];
    }

    return {pushInfosToBeSigned, chainId, marketMaker};
}

// sign infos and return a single quote
const singleQuote = function (domain_separator, infosToBeSigned) {
    try{
        let hashOrder = keccak256(abiEncodeMessage(infosToBeSigned));
        let hash = hashToSign(domain_separator, hashOrder);
        let signature = sign(hash);
        let quote = {
            "infos":{
                "pathIndex": infosToBeSigned.pathIndex.toLocaleString('fullwide', { useGrouping: false }), 
                "payer": infosToBeSigned.payer, 
                "fromTokenAddress": infosToBeSigned.fromTokenAddress, 
                "toTokenAddress" : infosToBeSigned.toTokenAddress, 
                "fromTokenAmountMax" : infosToBeSigned.fromTokenAmountMax.toLocaleString('fullwide', { useGrouping: false }), 
                "toTokenAmountMax" : infosToBeSigned.toTokenAmountMax.toLocaleString('fullwide', { useGrouping: false }), 
                "salt" : infosToBeSigned.salt, 
                "deadLine" : infosToBeSigned.deadLine, 
                "isPushOrder" : infosToBeSigned.isPushOrder
            },
            "signature": signature
        }
        return quote;
    } catch {
        return DEFAULT_QUOTE;
    }
}

// sign infos and return multiple quotes
const multipleQuotes = function (mulInfosToBeSigned, chainId, marketMaker) {
    let quantity = mulInfosToBeSigned.length;
    let quotes = [];
    for (let i = 0; i < quantity; i++) {
        let domain_separator = getDomainSeparator(chainId[i], marketMaker[i]);
        let quote = singleQuote(domain_separator, mulInfosToBeSigned[i]);
        quotes[i] = quote;
    }

    return quotes;
}

const getLocalTs = function() {
    return Math.floor(Date.now() / 1000);
}

const abiEncodeMessage = function(obj){
    return defaultAbiCoder.encode(
        ['bytes32', 'uint256', 'address', 'address', 'address', 'uint256', 'uint256', 'uint256', 'uint256', 'bool'],
        [
            obj.orderTypeHash,
            obj.pathIndex.toLocaleString('fullwide', { useGrouping: false }),
            obj.payer,
            obj.fromTokenAddress,
            obj.toTokenAddress,
            obj.fromTokenAmountMax.toLocaleString('fullwide', { useGrouping: false }),
            obj.toTokenAmountMax.toLocaleString('fullwide', { useGrouping: false }),
            obj.salt,
            obj.deadLine,
            obj.isPushOrder
        ]
    );
}

// final hash for signature
const hashToSign = function (domain_separator, hashOrder){
    return keccak256(solidityPack(
        ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
        ['0x19', '0x01', domain_separator, hashOrder]
    ));
}

// sign 
const sign = function (digest){
    let { r, s, v } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(PRIVATE_KEY,'hex'));
    // r = '0x' + r.toString('hex');
    // s = '0x' + s.toString('hex');
    signature ='0x' + r.toString('hex') + s.toString('hex') + parseInt(v).toString(16);
    // console.log("signature",signature);
    return signature;
}

module.exports = { 
    getDomainSeparator,
    getPullInfosToBeSigned, 
    getPushInfosToBeSigned, 
    singleQuote, 
    multipleQuotes 
};

