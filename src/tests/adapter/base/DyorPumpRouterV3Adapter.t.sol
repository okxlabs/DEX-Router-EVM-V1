// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {DyorPumpRouterV3Adapter} from "contracts/8/adapter/DyorPumpRouterV3Adapter.sol";
import {AbstractAdapterTest} from "../common/AbstractAdapterTest.t.sol";

/**
 * @title DyorPumpRouterV3AdapterTest
 * @dev Test for DyorPumpRouterV3Adapter
 */
contract DyorPumpRouterV3AdapterTest2 is AbstractAdapterTest {
    /**
     * @dev Create BakeryAdapter
     */
    mapping(string => address) internal routers;
    mapping(string => address) internal weth;
    function createCustomAdapter(
        string memory networkId
    ) internal override returns (address) {
        routers["xlayer"] = 0xD983C98D1522731146bAd34078dA0bD966D9EA08;
        weth["xlayer"] = 0xe538905cf8410324e03A5A23C1c177a474D59b2b;
        return address(new DyorPumpRouterV3Adapter(routers[networkId], weth[networkId]));
    }

    /**
     * @dev Define test cases for BakeryAdapter
     */
    function getSwapTestCases()
        internal
        pure
        override
        returns (SwapTestCase[][] memory)
    {
        SwapTestCase[][] memory cases = new SwapTestCase[][](1);
        cases[0] = getDyorfunTestCases();

        return cases;
    }

    function getDyorfunTestCases()
        internal
        pure
        returns (SwapTestCase[] memory)
    {
        SwapTestCase[] memory cases = new SwapTestCase[](1);

        address wokb = 0xe538905cf8410324e03A5A23C1c177a474D59b2b;
        address pandas = 0xa3e4378dFA9577c5533d8bbf3E65f79C05304A36;
        address pandas_wokb_pool = pandas;
        address[] memory path = new address[](2);
        path[0] = wokb;
        path[1] = pandas;
        bytes memory moreInfo = abi.encode(0.303 * 10 ** 18, 0, path);
        // https://www.oklink.com/zh-hans/x-layer/tx/0xde24979837baeea0809136534bfb696efbe46a94bed17fb2c81d63ab247a392d
        // Test 1: Sell base (OKB -> Pandas)
        cases[0] = SwapTestCase({
            networkId: "xlayer", // Uses BSC network from foundry.toml
            forkBlock: 31183367 - 1, // Example block, update as needed
            fromToken: wokb,
            toToken: pandas,
            pool: pandas_wokb_pool,
            amount: 0.303 * 10 ** 18, // 0.3 WOKB
            expectedOutput: 0, // Dynamic, can be set if known, actual is  4640289545676597216670428
            sellBase: true,
            expectRevert: false,
            description: "WOKB to Pandas on XLayer via DyorPumpRouterV3Adapter",
            moreInfo: moreInfo,
            fromTokenPreTo: address(0)
        });

        ///@dev can not sell quote for dyor, because the token is not in the pool
        // path[0] = pandas;
        // path[1] = wokb;
        // moreInfo = abi.encode(1226969441255741335479853, 0, path);
        // // https://www.oklink.com/zh-hans/x-layer/tx/0x830ed4300720f80b9130770fdcd69c9fe13943448d7c05417f3fb8a026651b41
        // cases[1] = SwapTestCase({
        //     networkId: "xlayer", // Uses BSC network from foundry.toml
        //     forkBlock: 31196607 - 1, // Example block, update as needed
        //     fromToken: pandas,
        //     toToken: wokb,
        //     pool: pandas_wokb_pool,
        //     amount: 1226969441255741335479853,
        //     expectedOutput: 0, // Dynamic, can be set if known
        //     sellBase: false,
        //     expectRevert: false,
        //     description: "Pandas to WOKB on XLayer via DyorPumpRouterV3Adapter",
        //     moreInfo: moreInfo,
        //     fromTokenPreTo: address(0)
        // });

        return cases;
    }
}