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
    PAYER_4,
    ACCOUNT3,
    ETH_FORK_ACCOUNT,
    OKC_FORK_ACCOUNT,
    ORDER_TYPEHASH,
    RFQ_VALID_PERIOD,
    PUSH_QUOTE_PATH_INDEX,
    MARKET_MAKER_ADDRESS,
    PMM_ADAPTER_ADDRESS,
    DEFAULT_QUOTE,
    PRIVATE_KEY, 
    PRIVATE_KEY_BACKEND,
    NAME_HASH, 
    VERSION_HASH, 
    EIP_712_DOMAIN_TYPEHASH
} = require("./constants");

const subIndex = '0000000000000000000000000000000000000000000000000000000000001111';


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
            "isPushOrder" : false,
            "chainId" : chunk.chainId,
            "marketMaker" : chunk.marketMaker,
            "pmmAdapter" : chunk.pmmAdapter,
            "source": chunk.source
        };
    }
    return pullInfosToBeSigned;
}

const getPullInfosToBeSigned_paidByETHMockAccount = function (pull_data) {
    let quantity = pull_data.length;
    let localTs = getLocalTs();
    let pullInfosToBeSigned = [];

    for (let i = 0; i < quantity; i++) {
        let chunk = pull_data[i];
        let toTokenAmount = getToTokenAmount(chunk);
        pullInfosToBeSigned[i] = {
            "orderTypeHash" : ORDER_TYPEHASH,
            "pathIndex" : chunk.pathIndex,
            "payer" : ETH_FORK_ACCOUNT,
            "fromTokenAddress" : chunk.fromTokenAddress,
            "toTokenAddress" : chunk.toTokenAddress,
            "fromTokenAmountMax" : Number(chunk.fromTokenAmount),
            "toTokenAmountMax" : Number(toTokenAmount),
            "salt" : Number(localTs),
            "deadLine" : localTs + RFQ_VALID_PERIOD,
            "isPushOrder" : false,
            "chainId" : chunk.chainId,
            "marketMaker" : chunk.marketMaker,
            "pmmAdapter" : chunk.pmmAdapter,
            "source" : chunk.source
        };
    }
    return pullInfosToBeSigned;
}

const getPullInfosToBeSigned_paidByOKCMockAccount = function (pull_data) {
    let quantity = pull_data.length;
    let localTs = getLocalTs();
    let pullInfosToBeSigned = [];

    for (let i = 0; i < quantity; i++) {
        let chunk = pull_data[i];
        let toTokenAmount = getToTokenAmount(chunk);

        pullInfosToBeSigned[i] = {
            "orderTypeHash" : ORDER_TYPEHASH,
            "pathIndex" : chunk.pathIndex,
            "payer" : OKC_FORK_ACCOUNT,
            "fromTokenAddress" : chunk.fromTokenAddress,
            "toTokenAddress" : chunk.toTokenAddress,
            "fromTokenAmountMax" : Number(chunk.fromTokenAmount),
            "toTokenAmountMax" : Number(toTokenAmount),
            "salt" : Number(localTs),
            "deadLine" : localTs + RFQ_VALID_PERIOD,
            "isPushOrder" : false,
            "chainId" : chunk.chainId,
            "marketMaker" : chunk.marketMaker,
            "pmmAdapter" : chunk.pmmAdapter,
            "source": chunk.source
        };
    }
    return pullInfosToBeSigned;
}


const getPullInfosToBeSigned_paidByAccount3 = function (pull_data) {
    let quantity = pull_data.length;
    let localTs = getLocalTs();
    let pullInfosToBeSigned = [];

    for (let i = 0; i < quantity; i++) {
        let chunk = pull_data[i];
        let toTokenAmount = getToTokenAmount(chunk);

        pullInfosToBeSigned[i] = {
            "orderTypeHash" : ORDER_TYPEHASH,
            "pathIndex" : chunk.pathIndex,
            "payer" : ACCOUNT3,
            "fromTokenAddress" : chunk.fromTokenAddress,
            "toTokenAddress" : chunk.toTokenAddress,
            "fromTokenAmountMax" : Number(chunk.fromTokenAmount),
            "toTokenAmountMax" : Number(toTokenAmount),
            "salt" : Number(localTs),
            "deadLine" : localTs + RFQ_VALID_PERIOD,
            "isPushOrder" : false,
            "chainId" : chunk.chainId,
            "marketMaker" : chunk.marketMaker,
            "pmmAdapter" : chunk.pmmAdapter,
            "source": chunk.source
        };
    }
    return pullInfosToBeSigned;
}

// change payer to payer_4
const getPullInfosToBeSigned_paidByCarol = function (pull_data) {
    let quantity = pull_data.length;
    let localTs = getLocalTs();
    let pullInfosToBeSigned = [];

    for (let i = 0; i < quantity; i++) {
        let chunk = pull_data[i];
        let toTokenAmount = getToTokenAmount(chunk);

        pullInfosToBeSigned[i] = {
            "orderTypeHash" : ORDER_TYPEHASH,
            "pathIndex" : chunk.pathIndex,
            "payer" : PAYER_4,
            "fromTokenAddress" : chunk.fromTokenAddress,
            "toTokenAddress" : chunk.toTokenAddress,
            "fromTokenAmountMax" : Number(chunk.fromTokenAmount),
            "toTokenAmountMax" : Number(toTokenAmount),
            "salt" : Number(localTs),
            "deadLine" : localTs + RFQ_VALID_PERIOD,
            "isPushOrder" : false,
            "chainId" : chunk.chainId,
            "marketMaker" : chunk.marketMaker,
            "pmmAdapter" : chunk.pmmAdapter,
            "source" : chunk.source
        };
    }

    return pullInfosToBeSigned;
}

// order to be pushed => infos to be signed
const getPushInfosToBeSigned = function (push_data){
    let quantity = push_data.length;
    let localTs = getLocalTs();
    let pushInfosToBeSigned = [];

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
            "isPushOrder" : true,
            "chainId" : chunk.chainId,
            "marketMaker" : chunk.marketMaker,
            "pmmAdapter" : chunk.pmmAdapter,
            "source" : chunk.source
        };
    }

    return pushInfosToBeSigned;
}

// sign infos and return a single quote
const singleQuote = function (domain_separator, infosToBeSigned, pmmAdapter) {
    try{
        let hashOrder = keccak256(abiEncodeMessage(infosToBeSigned));
        let hash = hashToSign(domain_separator, hashOrder);
        let signature = sign(hash);
        let quote = {
            "pathIndex": infosToBeSigned.pathIndex.toLocaleString('fullwide', { useGrouping: false }), 
            "payer": infosToBeSigned.payer, 
            "fromTokenAddress": infosToBeSigned.fromTokenAddress, 
            "toTokenAddress" : infosToBeSigned.toTokenAddress, 
            "fromTokenAmountMax" : infosToBeSigned.fromTokenAmountMax.toLocaleString('fullwide', { useGrouping: false }), 
            "toTokenAmountMax" : infosToBeSigned.toTokenAmountMax.toLocaleString('fullwide', { useGrouping: false }), 
            "salt" : infosToBeSigned.salt, 
            "deadLine" : infosToBeSigned.deadLine, 
            "isPushOrder" : infosToBeSigned.isPushOrder,
            "extension" : '0x000000000000000000000000' + pmmAdapter.slice(2) + subIndex + signature.slice(2) + infosToBeSigned.source,
        }
        return quote;
    } catch {
        return DEFAULT_QUOTE;
    }
}

// sign infos and return multiple quotes
const multipleQuotes = function (mulInfosToBeSigned) {
    // console.log("marketMaker", marketMaker);
    let quantity = mulInfosToBeSigned.length;
    let quotes = [];
    for (let i = 0; i < quantity; i++) {
        let domain_separator = getDomainSeparator(mulInfosToBeSigned[i].chainId, mulInfosToBeSigned[i].marketMaker);
        let quote = singleQuote(domain_separator, mulInfosToBeSigned[i], mulInfosToBeSigned[i].pmmAdapter);
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
    // signature65 ='0x' + r.toString('hex') + s.toString('hex') + parseInt(v).toString(16);
    // console.log("signature65",signature65);
    let _operatorSig = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(PRIVATE_KEY,'hex'));
    vs = (Number(_operatorSig.v - 27)*8 + Number(_operatorSig.s.toString('hex').slice(0,1))).toString(16) + _operatorSig.s.toString('hex').slice(1);
    operatorSig64 = _operatorSig.r.toString('hex') + vs;
    // console.log("operatorSig", operatorSig64);

    let _backEndSig = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(PRIVATE_KEY_BACKEND,'hex'));
    vs = (Number(_backEndSig.v - 27)*8 + Number(_backEndSig.s.toString('hex').slice(0,1))).toString(16) + _backEndSig.s.toString('hex').slice(1);
    backEndSig64 = _backEndSig.r.toString('hex') + vs;
    // console.log("backEndSig64", backEndSig64);

    sig = '0x' + operatorSig64 + backEndSig64;
    // console.log("sig", sig);
    return sig;
}

const getDigest = function (request,chainId,marketMaker){
        let domain_separator = getDomainSeparator(chainId, marketMaker);
        let obj = {
            "orderTypeHash" : ORDER_TYPEHASH,
            "pathIndex" : Number(request[0]),
            "payer" : request[1],
            "fromTokenAddress" : request[2],
            "toTokenAddress" : request[3],
            "fromTokenAmountMax" : Number(request[4]),
            "toTokenAmountMax" : Number(request[5]),
            "salt" : request[6],
            "deadLine" : request[7],
            "isPushOrder" : request[8]
        }
        let hashOrder = keccak256(abiEncodeMessage(obj));
        let hash = hashToSign(domain_separator, hashOrder);
    return hash;
}



module.exports = { 
    getDomainSeparator,
    getPullInfosToBeSigned, 
    getPullInfosToBeSigned_paidByETHMockAccount,
    getPullInfosToBeSigned_paidByOKCMockAccount,
    getPullInfosToBeSigned_paidByAccount3,
    getPullInfosToBeSigned_paidByCarol,
    getPushInfosToBeSigned, 
    singleQuote, 
    multipleQuotes,
    getDigest 
};

