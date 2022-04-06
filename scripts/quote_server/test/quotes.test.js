const { getPullInfosToBeSigned, getPushInfosToBeSigned, multipleQuotes } = require("../quoter");

const rfq0 = [];

const rfq1 = [
    {
        "pathIndex": 100000000000000,
        "fromTokenAddress": "0x5B7A4B8e50B10D48D9e9bDB3c19Fd5f366Ce429B", 
        "toTokenAddress": "0xE7E304F136c054Ee71199Efa6E26E8b0DAe242F3", 
        "fromTokenAmount": 400, 
        "toTokenAmountMin": 400,
        "chainId":1
    }
];
    
const rfq2 = [
    {
        "pathIndex": 100000000000000,
        "fromTokenAddress": "0x5B7A4B8e50B10D48D9e9bDB3c19Fd5f366Ce429B", 
        "toTokenAddress": "0xE7E304F136c054Ee71199Efa6E26E8b0DAe242F3", 
        "fromTokenAmount": 400, 
        "toTokenAmountMin": 400,
        "chainId":1
    },
    {
        "pathIndex": 200000000000000,
        "fromTokenAddress": "0x5B7A4B8e50B10D48D9e9bDB3c19Fd5f366Ce429B", 
        "toTokenAddress": "0xE7E304F136c054Ee71199Efa6E26E8b0DAe242F3", 
        "fromTokenAmount": 80000000000000000000000, 
        "toTokenAmountMin": 800,
        "chainId":56
    }
]

const push_data = [
    {
        "takerWantToken": "0x5B7A4B8e50B10D48D9e9bDB3c19Fd5f366Ce429B", 
        "makerSellToken": "0xE7E304F136c054Ee71199Efa6E26E8b0DAe242F3", 
        "makeAmountMax": 400, 
        "PriceMin": 400,
        "pushQuoteValidPeriod": 3600,
        "chainId":1
    },
    {
        "takerWantToken": "0x5B7A4B8e50B10D48D9e9bDB3c19Fd5f366Ce429B", 
        "makerSellToken": "0xE7E304F136c054Ee71199Efa6E26E8b0DAe242F3", 
        "makeAmountMax": 800, 
        "PriceMin": 800,
        "pushQuoteValidPeriod": 3600,
        "chainId":1

    }
  ]


// let infos_rfq0 = getPullInfosToBeSigned(rfq0);
// console.log("infos_rfq0", infos_rfq0);

// let infos_rfq1 = getPullInfosToBeSigned(rfq1);
// console.log("infos_rfq1", infos_rfq1);

let infos_rfq2 = getPullInfosToBeSigned(rfq2);
console.log("infos_rfq2", infos_rfq2);

// let infos_push_data = getPushInfosToBeSigned(push_data);
// console.log("infos_push_data", infos_push_data);

// let quotes_rfq0 = multipleQuotes(infos_rfq0);
// console.log("quotes_rfq0", quotes_rfq0);

// let quotes_rfq1 = multipleQuotes(infos_rfq1);
// console.log("quotes_rfq1", quotes_rfq1);

let quotes_rfq2 = multipleQuotes(infos_rfq2.pullInfosToBeSigned, infos_rfq2.chainId);
console.log("quotes_rfq2", quotes_rfq2);

// let quotes_push_date = multipleQuotes(infos_push_data.pushInfosToBeSigned, infos_push_data.chainId);
// console.log("quotes_push_date", quotes_push_date);


// const Web3 = require("web3");

// var x = Web3.utils.toBN(1234);
// console.log("x",x)