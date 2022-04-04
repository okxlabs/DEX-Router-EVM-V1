
# 1. Introduction
## 1.1 Why you need a quote server?
If you are a market maker who want to participate in decentralized aggregate swap, then a quote server could help you connect to the aggregate server so your liquidity would be available via the aggregate engine.

This is a simple quote server demo that might help you to develop your own quote server.



# 2. Getting Start
## 2.1 Install quote server demo
clone this repo and install
TODO: github repo link

```
npm install
```



## 2.2 Setup constants
We need setup some constants in constants.js.

```
/// account who pays the market making funds
const PAYER

/// private key of the account who sign the quotes, it could be the private key of payer or a specified quote signer
/// NOTES: Extra measures should be taken to keep your private key safe!
const PRIVATE_KEY

// valid period of quotes for pulling rfq, with unit of second
const RFQ_VALID_PERIOD

// a mapping from chain id to corresponding adapter address
const ADAPTER_ADDRESS
```



## 2.3 Setup operator in smart contract
Your can easily grant authorization to an operator to sign quote messages in the PMM Adapter smart contract, here we have the interface of setting operator as follows, and when you set it please make sure your active account is PAYER you set in constant.
```
function setOperator(address _operator) external;
```



## 2.4 Approve smart contract to use your market making funds
Approve smart contract Token Approve to use your market making funds during swapping.



## 2.5 Start your quote server
Then we can start the quote server with a simple  order:
```
node index.js
```



# 3. How to setup pull order quotes strategy
You can customize your quotes strategy in strategy.js, we simply returns 1.01 times in the demo.
NOTES: Please be noted that toTokenAmountMin will be specified to 0 when there is no requirement of the amount, and you could set up the result according to your own strategy.



# 4. How to push quotes
You can fill your quotes in ./pusher/pushdata.json, then you can push your quotes by running pusher.js.
```
node pusher.js
```



# 5. How to cancel quotes
Sometimes maybe you want to cancel your quotes posted, you can try to cancel your quotes in the PMM Adapter smart contract before they are taken.

Here we have the interface of cancelling quotes, both PAYER and operator could cancel quotes.
```
    function cancelQuotes(bytes32[] digest, bytes[] memory signature) external returns(bool[]);
```



# 6. How to query quote status on chain
Also you can query your quote status on chain in the PMM Adapter smart contract. There is no need to query a quote which deadline has expired, because the smart contract will never accept a expired order.

Here we have the interface of querying quotes status.
1. If one quote has never been brought onto chain, then its status will be default as {0, 0, false};
2. If one quote was pulled to aggregation server, and then brought onto chain for swapping, then it's status will be marked as {0, 0, true};
3. If one quote was pushed to aggregation server, and then brought onto chain for swapping, then it's status will be marked as {fromTokenAmountMax, fromTokenAmountUsed, false} util you cancel it.

```
struct OrderStatus{
        uint256 fromTokenAmountMax;
        uint256 fromTokenAmountUsed;
        bool cancelledOrFinalized;
    }

function queryOrderStatus(bytes32[] calldata digests) external view returns (OrderStatus[] memory);
```



# 7. Some rules to follow
TODO: some rules from aggregation server considering security.
1. IP
2. Frequency of pushing
3. Transaction failure rate due to expiration or lack of making funds
...



# 8. API
## 8.1 Pull quote
### 8.1.1 Request for quote
This quote server will listen on port 8000 and request data will be posted from aggregation engine with the form of array typed json.
Data type of request_for_quote you will receive from aggregation engine will be as follows:
```
struct request_for_quote {
    "pathIndex": "uint256";             // a uinque identifier of this order
    "fromTokenAddress": "address";      // from token address of this swap
    "toTokenAddress": "address";        // to token address of this swap
    "fromTokenAmount": "uint256";       // from token amount of this swap
    "toTokenAmountMin": "uint256";      // minimun to token amount of this swap, specified as 0 when no requirement
    "chainId":"uint256";                // chain id of this swap
}
```



### 8.1.2 Response for pull order
First of all you need to sign your quote information, and the data type of the information will be as follows:
```
struct infos_to_be_signed = {
    "orderTypeHash": "bytes32";         // this is a constant defined in constant.js
    "pathIndex" : "uint256";            // a uinque identifier of this order    
    "payer" : "address";                // the address who will pay the market making funds
    "fromTokenAddress" : "address";     // from token address of this swap
    "toTokenAddress" : "address";       // to token address of this swap
    "fromTokenAmountMax" : "uint256";   // from token amount of this swap
    "toTokenAmountMax" : "uint256";     // from token amount of this swap
    "salt" : "uint256";                 // timestamp of this quote, with unit of second
    "deadLine" : "uint256";             // dead line of this quote, with unit of second
    "isPushOrder" : "bool";             // is this a push order
}
```

Then the data will be wrapped according to EIP712 standard, and you will finally sign the hash of wrapped information. After that, you will send the quote with following data type:
```
struct quote {
    "infos":{
        "pathIndex" : "uint256";            // a uinque identifier of this order    
        "payer" : "address";                // the address who will pay the market making funds
        "fromTokenAddress" : "address";     // from token address of this swap
        "toTokenAddress" : "address";       // to token address of this swap
        "fromTokenAmountMax" : "uint256";   // from token amount of this swap
        "toTokenAmountMax" : "uint256";     // from token amount of this swap
        "salt" : "uint256";                 // timestamp of this quote, with unit of second
        "deadLine" : "uint256";             // dead line of this quote, with unit of second
        "isPushOrder" : "bool";             // is this a push order
    },
    "signature": "bytes";                   // signature of this quote
}
```



## 8.2 Push quote
The aggregation server will listen on the following path, where you can post your push order to.
http://kong-proxy.dev-okex.svc.dev.local:8443/priapi/v1/dx/public/multi/test/push

Data type of push quote is the same as 8.1.2, please be noted the segment of isPushOrder should be true in this case.



## 8.3 Set operator in smart contract
You can set operator with your payer account,
```
function setOperator(address _operator) external;
```

parameters:
_operator:  an operator who can sign quotes



## 8.4 Approve token
You need to approve token so the smart contract could use your market making funds during swapping.
```
function approve(address spender, uint256 amount) external returns (bool);
```

parameters:
spender:    Token Approve smart contract
amount:     allowance to Token Approve smart contract



## 8.5 Cancel quotes
Posted quotes could be canceled in smart contract PMM Adapter before they are taken.
```
    function cancelQuotes(bytes32[] digest, bytes[] memory signature) external returns(bool[] result);
```

parameters:
digest:     hash of wrapped quote information
signature:  signature of digest

returns:
result:     cancel excution result of each quote



## 8.6 Query quotes status
Quotes status could be queried in smart contract PMM Adapter.
```
struct OrderStatus{
    uint256 fromTokenAmountMax;     // from token amount max
    uint256 fromTokenAmountUsed;    // to token amount used
    bool cancelledOrFinalized;      // is this quote cancelled or finalized
}

function queryOrderStatus(bytes32[] calldata digests) external view returns (OrderStatus[] memory status);
```
parameters:     
digests:    hashes array of wrapped quote information

returns:
status:     OrderStatus array of quote

more information about result analysis please refer to part 6.
