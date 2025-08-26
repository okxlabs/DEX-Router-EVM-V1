// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AbstractAdapterTest} from "../common/AbstractAdapterTest.t.sol";
import {FlapAdapter} from "@dex/adapter/FlapAdapter.sol";
import {ExactInputParams} from "@dex/types/ExactInputParams.sol";

contract FlapAdapterTest is AbstractAdapterTest {

    address internal FLAP_PORTAL = 0xb30D8c4216E1f21F27444D2FfAee3ad577808678;
    address internal WNATIVE = 0xe538905cf8410324e03A5A23C1c177a474D59b2b;

    function createCustomAdapter(
        string memory /* networkId */
    ) internal override returns (address) {
        return address(new FlapAdapter(FLAP_PORTAL, WNATIVE));
    }

    function getSwapTestCases()
        internal
        override
        pure
        returns (SwapTestCase[][] memory)
    {
        SwapTestCase[][] memory cases = new SwapTestCase[][](1);
        cases[0] = getTestCases();

        return cases;
    }

    function getTestCases()
        internal
        pure
        returns (SwapTestCase[] memory)
    {
        SwapTestCase[] memory cases = new SwapTestCase[](2);

        address XStock = 0x53C66Ee89D09De290C2F259c5BEA41cD761d1111;
        address WOKB = 0xe538905cf8410324e03A5A23C1c177a474D59b2b;

        // Fix: Match the ExactInputParams with the actual swap direction
        ExactInputParams memory params1 = ExactInputParams({
            inputToken: WOKB,  // Input token should match fromToken
            outputToken: XStock, // Output token should match toToken
            inputAmount: 0.000075 * 10 ** 18,
            minOutputAmount: 0, // Set to 0 for testing, real value would be calculated
            permitData: ""
        });

        // WOKB -> XStock
        // https://www.oklink.com/x-layer/tx/0x764602ef0df6c51d92701bc96fdf5c3d982a85c74c6302f1b4509d1f967ff9ee
        cases[0] = SwapTestCase({
            networkId: "xlayer",
            forkBlock: 32207580 - 1,
            fromToken: WOKB,
            toToken: XStock,
            pool: address(0),
            amount: 0.05 * 10 ** 18, // 0.000075 WOKB
            expectedOutput: 1035074653168234088428680, // dynamic
            sellBase: false,
            expectRevert: false,
            description: "WOKB to XStock on XLayer FlapAdapter",
            moreInfo: abi.encode(params1),
            fromTokenPreTo: address(0) // Tokens will be sent to adapter directly
        });

        // XStock to WOKB
        // https://www.oklink.com/x-layer/tx/0x243dbbb61294e0fd512b8ba5c12cc7dd807b5cf63f7911ffd92a9ec87c68be5d
        ExactInputParams memory params2 = ExactInputParams({
            inputToken: XStock,
            outputToken: WOKB,
            inputAmount: 8344444137404781294501649,
            minOutputAmount: 0, // Set to 0 for testing, real value would be calculated
            permitData: ""
        });

        cases[1] = SwapTestCase({
            networkId: "xlayer",
            forkBlock: 32221262 - 1,
            fromToken: XStock,
            toToken: WOKB,
            pool: address(0),
            amount: 8344444137404781294501649,
            expectedOutput: 386854397091528676,
            sellBase: true,
            expectRevert: false,
            description: "XStock to WOKB on XLayer FlapAdapter",
            moreInfo: abi.encode(params2),
            fromTokenPreTo: address(0) // Tokens will be sent to adapter directly
        });

        return cases;
    }
}