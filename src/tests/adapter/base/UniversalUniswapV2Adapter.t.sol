// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {UniversalUniswapV2Adapter} from "@dex/adapter/TemplateAdapter/UniversalUniswapV2Adapter.sol";
import {AbstractAdapterTest} from "../common/AbstractAdapterTest.t.sol";

/**
 * @title UniversalUniswapV2AdapterTest
 * @dev Simple test for UniversalUniswapV2Adapter
 * @dev UniversalUniswapV2Adapter uses 0.2% fee (998/1000)
 * @dev Uses "bsc" network identifier from foundry.toml
 */
contract UniversalUniswapV2AdapterTest is AbstractAdapterTest {
    /**
     * @dev Create ApeSwap adapter
     */
    function createCustomAdapter(string memory /* networkId */) internal override returns (address) {
        return address(new UniversalUniswapV2Adapter());
    }

    function getSwapTestCases()
        internal
        pure
        override
        returns (SwapTestCase[][] memory)
    {
        SwapTestCase[][] memory cases = new SwapTestCase[][](3);
        cases[0] = getApeSwapV2TestCases();
        cases[1] = getRDexV2TestCases();
        cases[2] = getLynexTestCases();

        return cases;
    }
    /**
     * @dev Define test cases for ApeSwap using network identifiers
     */
    function getApeSwapV2TestCases() internal pure returns (SwapTestCase[] memory) {
        // Token addresses on BSC
        address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
        address BANANA = 0x603c7f932ED1fc6575303D8Fb018fDCBb0f39a95;
    
        // Pool addresses
        address WBNB_BANANA_POOL = 0xF65C1C0478eFDe3c19b49EcBE7ACc57BB6B1D713;
    
        SwapTestCase[] memory cases = new SwapTestCase[](1);
        
        // ApeSwap uses 0.2% fee (998/1000)
        bytes memory apeSwapFee = abi.encode(998, 1000);
        
        // Test 1: WBNB to BANANA
        // Using latest block (0) to avoid archive node requirement
        cases[0] = SwapTestCase({
            networkId: "bsc", // Uses BSC network from foundry.toml
            forkBlock: 0, // 0 = latest block
            fromToken: WBNB,
            toToken: BANANA,
            pool: WBNB_BANANA_POOL,
            amount: 328595232056825,
            expectedOutput: 0, // Dynamic
            sellBase: false,
            expectRevert: false,
            description: "WBNB to BANANA on BSC",
            moreInfo: apeSwapFee,
            fromTokenPreTo: address(0)
        });
        
        return cases;
    }

    function getRDexV2TestCases() internal pure returns (SwapTestCase[] memory) {
        // Token addresses on BSC
        address RAC = 0x024a9AD0ECFaa8b3566D3310AFFb358379a55e7a;
        address BUSD = 0x55d398326f99059fF775485246999027B3197955;
    
        // Pool addresses
        address RAC_BUSD_POOL = 0x9f3E1B10c58384Ab472393455d2f870427fF9153;
    
        SwapTestCase[] memory cases = new SwapTestCase[](1);
        
        // RDX uses 0.5% fee (995/1000)
        bytes memory rdxFee = abi.encode(995, 1000);
        
        // Test 1: RAC to BUSD
        // Using latest block (0) to avoid archive node requirement
        // https://bscscan.com/tx/0x6877385a5544fbe6b4d692ef57ab8ea0b824ac186ce34d0e6275d586dd183335
        // https://app.blocksec.com/explorer/tx/bsc/0x1a80c3d5edd7996701bb2e78b982c1e1c3dbd826dab347cf3b0b4ef53bca825a?event=simulation&type=0&timestamp=1754894565307
        cases[0] = SwapTestCase({
            networkId: "bsc", // Uses BSC network from foundry.toml
            forkBlock: 57189200 - 1, // 0 = latest block
            fromToken: RAC,
            toToken: BUSD,
            pool: RAC_BUSD_POOL,
            amount: 1000 * 10 ** 18,
            expectedOutput: 0, // Dynamic
            sellBase: true,
            expectRevert: false,
            description: "RAC to BUSD on BSC",
            moreInfo: rdxFee,
            fromTokenPreTo: address(0)
        });
        
        return cases;
    }

    function getLynexTestCases() internal pure returns (SwapTestCase[] memory) {
        address LYNX = 0x1a51b19CE03dbE0Cb44C1528E34a7EDD7771E9Af;
        address USDC = 0x176211869cA2b568f2A7D4EE941E073a821EE1ff;

        address LYNX_USDC_POOL = 0x3E78c1F766D7FE2c3dceF6aFe6609966540B6391;

        // Lynex uses 0.5% fee (995/1000)
        bytes memory lynexFee = abi.encode(995, 1000);
        SwapTestCase[] memory cases = new SwapTestCase[](1);
        
        // https://lineascan.build/tx/0xc1de66fb17508e61d5c9e4925bae20b53ec809d837d5409260f08e88f241faf3
        cases[0] = SwapTestCase({
            networkId: "linea",
            forkBlock: 21889650 - 1,
            fromToken: USDC,
            toToken: LYNX,
            pool: LYNX_USDC_POOL,
            amount: 1.748546 * 10 ** 6 + 1, // Add 1 wei cause adapter will leave 1 wei for reduce gas cost
            expectedOutput: 156.966805548135144944 * 10 ** 18,
            sellBase: true,
            expectRevert: false,
            description: "USDC to LYNX on Linea",
            moreInfo: lynexFee,
            fromTokenPreTo: address(0)
        });
        
        return cases;
    }
} 