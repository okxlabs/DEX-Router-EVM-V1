### 报价程序接收的数据格式：
数组类型json数据，字段如下
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
        "fromTokenAmount": 800, 
        "toTokenAmountMin": 800,
        "chainId":1
    }
]


### 报价程序返回的数据格式：
数组类型json数据，字段如下
quote = [
{
        "pathIndex": 100000000000000, 
        "payer": 0x5B7A4B8e50B10D48D9e9bDB3c19Fd5f366Ce429B, 
        "fromTokenAddress": 0x5B7A4B8e50B10D48D9e9bDB3c19Fd5f366Ce429B, 
        "toTokenAddress" : 0x5B7A4B8e50B10D48D9e9bDB3c19Fd5f366Ce429B, 
        "fromTokenAmount" : 400, 
        "toTokenAmount" : 400, 
        "salt" : 12345678, 
        "deadLinde" : 23456789, 
        "signature": {
            "r" : '0x5c444f89a77cbfce1d4fca802f074ac208be5a78843025d400e63df3314856be',
            "s" : '0x0ae85995b1c482348116813c5e86172cd1b8adfe4bb3781aa84c2d0a0c71e321,
            "v" : 0x1c
        }
},
{
        "pathIndex": 100000000000000, 
        "payer": 0x5B7A4B8e50B10D48D9e9bDB3c19Fd5f366Ce429B, 
        "fromTokenAddress": 0x5B7A4B8e50B10D48D9e9bDB3c19Fd5f366Ce429B, 
        "toTokenAddress" : 0x5B7A4B8e50B10D48D9e9bDB3c19Fd5f366Ce429B, 
        "fromTokenAmount" : 400, 
        "toTokenAmount" : 400, 
        "salt" : 12345678, 
        "deadLinde" : 23456789, 
        "signature": {
            "r" : '0x5c444f89a77cbfce1d4fca802f074ac208be5a78843025d400e63df3314856be',
            "s" : '0x0ae85995b1c482348116813c5e86172cd1b8adfe4bb3781aa84c2d0a0c71e321,
            "v" : 0x1c
        }
}
]

### 智能合约接口：
    struct SwapRequest {
        address payer;
        address fromToken;
        address toToken;
        uint256 fromTokenAmount;
        uint256 toTokenAmount;
        bytes32 salt;
        uint256 deadLine;
    }

     struct Sig {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function swap(
        address to,
        SwapRequest memory request,
        Sig memory signature
    ) external onlyRouter returns(bool)



