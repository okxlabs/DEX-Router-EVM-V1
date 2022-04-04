
const Web3 = require("web3");
const PROVIDER = 'https://bsc-dataseed1.binance.org';
const { ethers } = require('hardhat')


const web3 = new Web3(new Web3.providers.HttpProvider(PROVIDER));


var abiEncodeMessage = function(obj){
    let abiEncodedMessage = web3.eth.abi.encodeParameter(
        {
            "" : {
                "fromTokenAmountMax" : 'uint256',
            }
        },
        {
            "fromTokenAmountMax" : obj, 
        }
    );
    // console.log("abiEncodedMessage",abiEncodedMessage);
    return abiEncodedMessage;
}

var abiEncodeMessage = function(obj){
    let res = ethers.utils.defaultAbiCoder.encode(
        ['uint256'],
        [obj]
      )
    return res;
}



n = 10000000000000000000000000000;

let res = abiEncodeMessage(n);
console.log("n",n);


// g = n.toLocaleString('fullwide', { useGrouping: false })
// console.log("g", g);


// // let x = web3.utils.toBN(g);
// // console.log("x", x);
// // console.log("xtoString", x.toString());

// let res = abiEncodeMessage(g);
// console.log("res", res);

// let y = 10000000000000000000000000000;
// let res2 = abiEncodeMessage(web3.utils.toBN(y).toString());
// console.log("res2", res2);