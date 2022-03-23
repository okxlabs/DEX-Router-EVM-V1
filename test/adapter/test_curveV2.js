

const { ethers, hre } = require('hardhat');
const { expect } = require("chai");
const fs = require('fs');
const { assert } = require('console');
const { equal } = require('assert');
const BigNumber = require("bignumber.js");



    
describe("test curve V2", function () {
    let provider;
    let fromToken;
    let toToken;
    let fromCoinIdx;
    let toCoinIdx;
    let exchangeFunctionSelector;
    let pool;
    let signer;

    let CurveV2Adapter;
    let USDTContract;
    let usetABI;

    function checkContractBalance(Contract) {
    }   

    function getUsertABI() {
        const abi = JSON.parse(fs.readFileSync('./test/adapter/usdt.json', 'utf8'));
        return abi;
    }


    beforeEach(async function() {
        // address
        UserAddress = "0x3DdfA8eC3052539b6C9549F12cEA2C295cfF5296"
        UsdtAddress = "0xdAC17F958D2ee523a2206206994597C13D831ec7"

        provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545/");

        await provider.send("hardhat_impersonateAccount",[UserAddress]);


        signer = await provider.getSigner(UserAddress)

        // 获得
        Address = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
        CurveV2Adapter = await ethers.getContractFactory("CurveV2Adapter");
        CurveV2Adapter = await CurveV2Adapter.attach(Address);
        console.log(CurveV2Adapter.address);

        // USDT
        usetABI = getUsertABI();
        USDTContract = new ethers.Contract(UsdtAddress, usetABI, provider);
        userBalance = await USDTContract.balanceOf(UserAddress);
        console.log(userBalance)

      });
    
    it("transfer token to contract", async function () {
        const beforeBalance = await USDTContract.balanceOf(CurveV2Adapter.address);
        await USDTContract.connect(signer).transfer(
            CurveV2Adapter.address,
            100000000
        );
        const afterBalance = await USDTContract.balanceOf(CurveV2Adapter.address);
        equal(true, afterBalance.eq(beforeBalance.add(100000000)));
    })
    

    
    it("swap token from curve", async function () {
        const abiCoder = ethers.utils.defaultAbiCoder;
        // 3pool address: 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7
        const result = abiCoder.encode([ "uint", "string" ], [ 1234, "Hello World" ]);

        pool = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7"
        toToken = UserAddress
        moreInfo = {}

        // CurveV2Adapter deployed: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
        // await CurveV2Adapter.sellBase(toToken, pool, moreInfo);

    })
})

