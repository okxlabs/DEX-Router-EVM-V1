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
const {getCurBlockTs, getLocalTs, abiEncodeMessage, abiEncodeDomainSeparator, sign, keccak256, hashToSign} = require("./utils/web3helper");
const {
    PAYER,
    ORDER_TYPEHASH,
    RFQ_VALID_PERIOD,
    PUSH_QUOTE_PATH_INDEX,
    ADAPTER_ADDRESS,
    DEFAULT_QUOTE
} = require("./constants");

var getDomainSeparator = function (chainId){
    let adapterAddress = ADAPTER_ADDRESS[chainId];
    return keccak256(abiEncodeDomainSeparator(chainId, adapterAddress));
}

// rfq => infos to be signed
var getPullInfosToBeSigned = function (pull_data){
    let quantity = pull_data.length;
    let localTs = getLocalTs();
    let pullInfosToBeSigned = [];
    let chainId = [];

    for (let i = 0; i < quantity; i++){
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
    }

    return {pullInfosToBeSigned, chainId};
}

// order to be pushed => infos to be signed
var getPushInfosToBeSigned = function (push_data){
    let quantity = push_data.length;
    let localTs = getLocalTs();
    let pushInfosToBeSigned = [];
    let chainId = [];

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
    }

    return {pushInfosToBeSigned, chainId};
}

// sign infos and return a single quote
var singleQuote = function (domain_separator, infosToBeSigned){
    try{
        let hashOrder = keccak256(abiEncodeMessage(infosToBeSigned));
        console.log("hashOrder", hashOrder);
        let hash = hashToSign(domain_separator, hashOrder);
        console.log("digest",hash);
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
    }catch{
        return DEFAULT_QUOTE;
    }

}

// sign infos and return multiple quotes
var multipleQuotes = function (mulInfosToBeSigned, chainId){
    let quantity = mulInfosToBeSigned.length;
    let quotes = [];
    for (let i = 0; i < quantity; i++){
        let domain_separator = getDomainSeparator(chainId[i]);
        let quote = singleQuote(domain_separator, mulInfosToBeSigned[i]);
        quotes[i] = quote;
    }

    return quotes;
}


module.exports = { 
    getDomainSeparator,
    getPullInfosToBeSigned, 
    getPushInfosToBeSigned, 
    singleQuote, 
    multipleQuotes 
};

