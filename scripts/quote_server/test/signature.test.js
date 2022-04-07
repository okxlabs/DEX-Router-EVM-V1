const { PRIVATE_KEY } = require("../constants");
const {web3, keccak256, sign} = require("../utils/web3helper");
const domain_separator = '0xb62baa298dba2097375700cb4111f22d2780f2b74a67bd22ae424889eea981f3';
const { ecsign } = require('ethereumjs-util');


console.log("===================== web3.eth.sign ===================");
// let hash = keccak256("hello");

let data = '0x1901' + domain_separator.slice(2,66) + keccak256(web3.eth.abi.encodeParameter('string','hello')).slice(2,66);
console.log("data:", data);
console.log("hashData:", keccak256(data));

let encodedPackedHash = web3.utils.soliditySha3('\x19\x01', domain_separator, keccak256(web3.eth.abi.encodeParameter('string','hello')));
console.log("encodePackedHash", encodedPackedHash);

let toBeSign1 = Buffer.from(encodedPackedHash.slice(2),'hex');
console.log("toBeSign1",toBeSign1);

let bufferKey = Buffer.from(PRIVATE_KEY,'hex');
console.log("bufferKey",bufferKey);

console.log("ecsign", ecsign(toBeSign1, bufferKey));

let signature = sign(encodedPackedHash, bufferKey);
console.log("sign", signature);

// let r = '0x' + signature.r.toString('hex');
// console.log("r", r);
// let s = '0x' + signature.s.toString('hex');
// console.log("s", s);
// console.log("sig: ", signature.signature);
  












