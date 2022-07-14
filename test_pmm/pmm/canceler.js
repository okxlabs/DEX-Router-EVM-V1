const { keccak256, defaultAbiCoder, solidityPack } = require('ethers/lib/utils');
const { ecsign } = require('ethereumjs-util');
const {
    PRIVATE_KEY_CANCELER,
    PATHINDEX_TYPEHASH,
    NAME_HASH, 
    VERSION_HASH, 
    EIP_712_DOMAIN_TYPEHASH
} = require("./constants");

const signCancelQuotes = function (pathIndex, chainId, marketMaker) {
    let domain_separator = keccak256(defaultAbiCoder.encode(
            ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
            [EIP_712_DOMAIN_TYPEHASH, NAME_HASH, VERSION_HASH, chainId, marketMaker]
        )
    );

    let hashOrder = keccak256(defaultAbiCoder.encode(
            ['bytes32', 'uint256[]'],
            [PATHINDEX_TYPEHASH, pathIndex]
        )
    );
    let hash = hashToSign(domain_separator, hashOrder);
    let signature = sign(hash);
    return signature;
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
    let _operatorSig = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(PRIVATE_KEY_CANCELER,'hex'));
    vs = (Number(_operatorSig.v - 27)*8 + Number(_operatorSig.s.toString('hex').slice(0,1))).toString(16) + _operatorSig.s.toString('hex').slice(1);
    sig = '0x' + _operatorSig.r.toString('hex') + vs;
    // console.log("sig", sig);
    return sig;
}

module.exports = {
    signCancelQuotes
}

