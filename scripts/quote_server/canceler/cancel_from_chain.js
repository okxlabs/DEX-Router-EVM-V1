/*
* canceler.js
* a demo that market makers could use to try canceling the pulled or pushed quotes, it might fail 
* because the order might have already been taken by users. 
*/

const { PRIVATE_KEY, PMM_ADDAPTER_ADDRESS } = require("../constants");
const { web3 } = require("../utils/web3helper");
const { addapter_abi } = require("./addapter_abi");

const maker = web3.eth.accounts.privateKeyToAccount(PRIVATE_KEY);

const pmm_addapter = new web3.eth.Contract(addapter_abi, PMM_ADDAPTER_ADDRESS);

// cancel_hashes: the signatures array of quotes to be canceled
var cancelQuotes = async function (cancel_hashes){
    let tempData = pmm_addapter.method.cancelQuotes(cancel_hashes).encodeABI();

    maker.signTransaction({
        gasPrice: "10000000000",
        gas: "500000",
        to: PMM_ADDAPTER_ADDRESS,
        data: tempData
    }).then(async function (result) {
        let raw = result.rawTransaction;
        web3.eth.sendSignedTransaction(raw, function(err, hash){
            if(!err){
                console.log("cancel success, and the tx hash is: ", hash);
            }else{
                console.log("cancel tx failed");
            }
        }).catch(error => console.log(error.message));
    }).catch(error => console.log(error.message));
};

module.exports = cancelQuotes;

