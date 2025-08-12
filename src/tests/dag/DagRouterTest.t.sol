// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "./DagRouterBaseTest.t.sol";

contract DagRouterTest is DagRouterBaseTest {

    /*
     *  100% A(WETH) → B(DAI)
    */
    function test_DagRouter_noETH_case1() public userWithToken(arnaud, tokens[0], tokens[1], oneEther) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(tokens[0], tokens[1], oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase1_WETH2DAI();
        dexRouter.dagSwapTo(0, arnaud, baseRequest, paths);
    }

    /*
     *  10% A(WETH) → D(USDC)
     *  40% A(WETH) → C(USDT)
     *  50% A(WETH) → B(DAI) → C(USDT)
     *          ↳ 100% C(USDT) → D(USDC)  
    */
    function test_DagRouter_noETH_case2() public userWithToken(arnaud, tokens[0], tokens[3], oneEther) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(tokens[0], tokens[3], oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase2_WETH2USDC();
        dexRouter.dagSwapTo(0, arnaud, baseRequest, paths);
    }

    /*
     *  40% A(WETH) → D(USDC)  
     *  60% A(WETH) → B(DAI)  
     *      ↳ 20% B(DAI) → D(USDC)  
     *      ↳ 80% B(DAI) → C(USDT) → D(USDC)
    */
    function test_DagRouter_noETH_case3() public userWithToken(arnaud, tokens[0], tokens[3], oneEther) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(tokens[0], tokens[3], oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase3_WETH2USDC();
        dexRouter.dagSwapTo(0, arnaud, baseRequest, paths);
    }

    /*
     *  90% A(WETH) → B(DAI)  
     *      ↳ 100% B(DAI) → C(USDT)  
     *  10% A(WETH) → C(USDT)  
     *      ↳ 25% C(USDT) → D(USDC) → E(WBTC)  
     *      ↳ 75% C(USDT) → E(WBTC)
    */
    function test_DagRouter_noETH_case4() public userWithToken(arnaud, tokens[0], tokens[4], oneEther) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(tokens[0], tokens[4], oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase4_WETH2WBTC();
        dexRouter.dagSwapTo(0, arnaud, baseRequest, paths);
    }

    /*
     *  B1 and B2 are same token at different nodes
     *  90% A(WETH) → B1(DAI)  
     *      ↳ 100% B1(DAI) → C(USDC)  
     *  10% A(WETH) → C(USDC)  
     *      ↳ 25% C(USDC) → B2(DAI) → D(USDT)
     *      ↳ 75% C(USDC) → D(USDT)
    */
    function test_DagRouter_noETH_case5() public userWithToken(arnaud, tokens[0], tokens[2], oneEther) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(tokens[0], tokens[2], oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase5_WETH2USDT();
        dexRouter.dagSwapTo(0, arnaud, baseRequest, paths);
    }

    /*
     *  100% A(WETH) → B(DAI)
    */
    function test_DagRouter_fromETH_case1() public userWithToken(arnaud, ETH, tokens[1], oneEther) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(ETH, tokens[1], oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase1_WETH2DAI();
        dexRouter.dagSwapTo{value: oneEther}(0, arnaud, baseRequest, paths);
    }

    /*
     *  10% A(WETH) → D(USDC)
     *  40% A(WETH) → C(USDT)
     *  50% A(WETH) → B(DAI) → C(USDT)
     *          ↳ 100% C(USDT) → D(USDC)  
    */
    function test_DagRouter_fromETH_case2() public userWithToken(arnaud, ETH, tokens[3], oneEther) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(ETH, tokens[3], oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase2_WETH2USDC();
        dexRouter.dagSwapTo{value: oneEther}(0, arnaud, baseRequest, paths);
    }

    /*
     *  40% A(WETH) → D(USDC)  
     *  60% A(WETH) → B(DAI)  
     *      ↳ 20% B(DAI) → D(USDC)  
     *      ↳ 80% B(DAI) → C(USDT) → D(USDC)
    */
    function test_DagRouter_fromETH_case3() public userWithToken(arnaud, ETH, tokens[3], oneEther) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(ETH, tokens[3], oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase3_WETH2USDC();
        dexRouter.dagSwapTo{value: oneEther}(0, arnaud, baseRequest, paths);
    }

    /*
     *  90% A(WETH) → B(DAI)  
     *      ↳ 100% B(DAI) → C(USDT)  
     *  10% A(WETH) → C(USDT)  
     *      ↳ 25% C(USDT) → D(USDC) → E(WBTC)  
     *      ↳ 75% C(USDT) → E(WBTC)
    */
    function test_DagRouter_fromETH_case4() public userWithToken(arnaud, ETH, tokens[4], oneEther) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(ETH, tokens[4], oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase4_WETH2WBTC();
        dexRouter.dagSwapTo{value: oneEther}(0, arnaud, baseRequest, paths);
    }

    /*
     *  B1 and B2 are same token at different nodes
     *  90% A(WETH) → B1(DAI)  
     *      ↳ 100% B1(DAI) → C(USDC)  
     *  10% A(WETH) → C(USDC)  
     *      ↳ 25% C(USDC) → B2(DAI) → D(USDT)
     *      ↳ 75% C(USDC) → D(USDT)
    */
    function test_DagRouter_fromETH_case5() public userWithToken(arnaud, ETH, tokens[2], oneEther) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(ETH, tokens[2], oneEther);
        DexRouter.RouterPath[] memory paths = _generatePathCase5_WETH2USDT();
        dexRouter.dagSwapTo{value: oneEther}(0, arnaud, baseRequest, paths);
    }

    /*
     *  100% A(DAI) → B(WETH)
    */
    function test_DagRouter_toETH_case1() public userWithToken(arnaud, tokens[1], ETH, 1000 * 10 ** 18) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(tokens[1], ETH, 1000 * 10 ** 18);
        DexRouter.RouterPath[] memory paths = _generatePathCase1_DAI2WETH();
        dexRouter.dagSwapTo(0, arnaud, baseRequest, paths);
    }

    /*
     *  10% A(USDC) → D(WETH)
     *  40% A(USDC) → C(USDT)
     *  50% A(USDC) → B(DAI) → C(USDT)
     *          ↳ 100% C(USDT) → D(WETH)  
    */
    function test_DagRouter_toETH_case2() public userWithToken(arnaud, tokens[3], ETH, 1000 * 10 ** 6) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(tokens[3], ETH, 1000 * 10 ** 6);
        DexRouter.RouterPath[] memory paths = _generatePathCase2_USDC2WETH();
        dexRouter.dagSwapTo(0, arnaud, baseRequest, paths);
    }

    /*
     *  40% A(USDC) → D(WETH)  
     *  60% A(USDC) → B(DAI)  
     *      ↳ 20% B(DAI) → D(WETH)  
     *      ↳ 80% B(DAI) → C(USDT) → D(WETH)
    */
    function test_DagRouter_toETH_case3() public userWithToken(arnaud, tokens[3], ETH, 1000 * 10 ** 6) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(tokens[3], ETH, 1000 * 10 ** 6);
        DexRouter.RouterPath[] memory paths = _generatePathCase3_USDC2WETH();
        dexRouter.dagSwapTo(0, arnaud, baseRequest, paths);
    }

    /*
     *  90% A(WBTC) → B(USDT)  
     *      ↳ 100% B(USDT) → C(USDC)  
     *  10% A(WBTC) → C(USDC)  
     *      ↳ 25% C(USDC) → D(DAI) → E(WETH)  
     *      ↳ 75% C(USDC) → E(WETH)
    */
    function test_DagRouter_toETH_case4() public userWithToken(arnaud, tokens[4], ETH, 1 * 10 ** 8) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(tokens[4], ETH, 1 * 10 ** 8);
        DexRouter.RouterPath[] memory paths = _generatePathCase4_WBTC2WETH();
        dexRouter.dagSwapTo(0, arnaud, baseRequest, paths);
    }

    /*
     *  B1 and B2 are same token at different nodes
     *  90% A(USDT) → B1(DAI)  
     *      ↳ 100% B1(DAI) → C(USDC)  
     *  10% A(USDT) → C(USDC)  
     *      ↳ 25% C(USDC) → B2(DAI) → D(WETH)
     *      ↳ 75% C(USDC) → D(WETH)
    */
    function test_DagRouter_toETH_case5() public userWithToken(arnaud, tokens[2], ETH, 1000 * 10 ** 6) noResidue {
        DexRouter.BaseRequest memory baseRequest = _generateBaseRequest(tokens[2], ETH, 1000 * 10 ** 6);
        DexRouter.RouterPath[] memory paths = _generatePathCase5_USDT2WETH();
        dexRouter.dagSwapTo(0, arnaud, baseRequest, paths);
    }
}
