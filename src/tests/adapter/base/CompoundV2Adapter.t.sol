// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {AbstractAdapterTest} from "../common/AbstractAdapterTest.t.sol";
import {CompoundAdapter} from "@dex/adapter/CompoundV2Adapter.sol";

contract CompoundV2AdapterTest is AbstractAdapterTest {

    // Mapping of network IDs to their wrapped tokens
    mapping(string => address) internal WETH;

    function createCustomAdapter(
        string memory networkId
    ) internal override returns (address) {
        // WETH addresses per network
        WETH["linea"] = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f; // Linea WETH

        address weth = WETH[networkId];
        require(weth != address(0), "Unsupported network for Compound V2");
        
        return address(new CompoundAdapter(weth));
    }

    function getSwapTestCases()
        internal
        override
        pure
        returns (SwapTestCase[][] memory)
    {
        SwapTestCase[][] memory cases = new SwapTestCase[][](1);
        cases[0] = getMendiTestCases(); // Empty test cases array

        return cases;
    }

    function getMendiTestCases() internal pure returns (SwapTestCase[] memory) {
        SwapTestCase[] memory cases = new SwapTestCase[](1);
        
        address meWETH = 0xAd7f33984bed10518012013D4aB0458D37FEE6F3;
        address WETH = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;
        address meWETH_WETH_POOL = 0x0000000000000000000000000000000000000000;
        // https://lineascan.build/tx/0x05437d7124f97c739976cfbf02b14798b77de2eb10ebf183d11bce6c9921f378
        cases[0] = SwapTestCase({
            networkId: "linea",
            forkBlock: 23405506,
            fromToken: meWETH,
            toToken: WETH,
            pool: meWETH_WETH_POOL,
            amount: 37831125,
            expectedOutput: 0.00808446455520139 * 10 ** 18,
            sellBase: false,
            expectRevert: false,
            description: "meWETH to WETH on Linea",
            moreInfo: abi.encode(meWETH, WETH, false),
            fromTokenPreTo: address(0)
        });
        return cases;
    }
}