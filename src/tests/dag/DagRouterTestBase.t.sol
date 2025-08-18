// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@dex/DexRouter.sol";
import "@dex/TokenApprove.sol";
import "@dex/TokenApproveProxy.sol";
import "@dex/utils/WNativeRelayer.sol";
import "@dex/libraries/SafeERC20.sol";

contract DagRouterTestBase is Test {
    enum UniVersion {
        UniV2,
        UniV3
    }

    struct RouterPathParam {
        address fromToken;
        address toToken;
        UniVersion uniVersion;
        uint8 inputIndex;
        uint8 outputIndex;
        uint16 weight;
    }

    // tokens
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address[] public tokens = [
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH, decimals=18
        0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI, decimals=18
        0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT, decimals=6
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC, decimals=6
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599  // WBTC, decimals=8
    ];
    // pools
    address[] public pools = [
        0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11, // WETH<>DAI, UniV2, token0 = DAI, token1 = WETH
        0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8, // WETH<>DAI, UniV3
        0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852, // WETH<>USDT, UniV2, token0 = WETH, token1 = USDT
        0x4e68Ccd3E89f51C3074ca5072bbAC773960dFa36, // WETH<>USDT, UniV3
        0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc, // WETH<>USDC, UniV2, token0 = USDC, token1 = WETH
        0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640, // WETH<>USDC, UniV3
        0x48DA0965ab2d2cbf1C17C09cFB5Cbe67Ad5B1406, // DAI<>USDT, UniV3
        0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5, // DAI<>USDC, UniV2, token0 = DAI, token1 = USDC
        0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168, // DAI<>USDC, UniV3
        0x3041CbD36888bECc7bbCBc0045E3B1f144466f5f, // USDT<>USDC, UniV2, token0 = USDC, token1 = USDT
        0x3416cF6C708Da44DB2624D63ea0AAef7113527C6, // USDT<>USDC, UniV3
        0x9Db9e0e53058C89e5B94e29621a205198648425B, // USDT<>WBTC, UniV3
        0x99ac8cA7087fA4A2A1FB6357269965A2014ABc35  // USDC<>WBTC, UniV3
    ];

    DexRouter public dexRouter;
    TokenApprove tokenApprove = TokenApprove(0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f); // ETH
    TokenApproveProxy tokenApproveProxy = TokenApproveProxy(0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58); // ETH
    WNativeRelayer wNativeRelayer = WNativeRelayer(payable(0x5703B683c7F928b721CA95Da988d73a3299d4757)); // ETH

    address UniversalUniV3Adapter = 0x6747BcaF9bD5a5F0758Cbe08903490E45DdfACB5;
    address UniV2Adapter = 0xc837BbEa8C7b0caC0e8928f797ceB04A34c9c06e;

    address public admin = vm.rememberKey(1);
    address public arnaud = vm.rememberKey(11111111);

    uint256 public oneEther = 1 * 10 ** 18;

    // modifier to log fromToken and toToken balance of user
    modifier userWithToken(address _user, address _token0, address _token1, uint256 _amount) {
        vm.startPrank(_user);
        console2.log("User:", _user);
        if (_token0 == ETH) {
            deal(address(_user), _amount);
            console2.log(
                "ETH balance begin: %d",
                address(_user).balance
            );
        } else {
            deal(_token0, _user, _amount);
            SafeERC20.safeApprove(IERC20(_token0), address(tokenApprove), _amount);
            console2.log(
                "%s balance begin: %d",
                IERC20(_token0).symbol(),
                IERC20(_token0).balanceOf(address(_user))
            );
        }
        if (_token0 != _token1) {
            if (_token1 == ETH) {
                console2.log(
                    "ETH balance begin: %d",
                    address(_user).balance
                );
            } else {
                console2.log(
                    "%s balance begin: %d",
                    IERC20(_token1).symbol(),
                    IERC20(_token1).balanceOf(address(_user))
                );
            }
        }
        _;
        if (_token0 == ETH) {
            console2.log(
                "ETH balance end: %d",
                address(_user).balance
            );
        } else {
            console2.log(
                "%s balance end: %d",
                IERC20(_token0).symbol(),
                IERC20(_token0).balanceOf(address(_user))
            );
        }
        if (_token0 != _token1) {
            if (_token1 == ETH) {
                console2.log(
                    "ETH balance end: %d",
                    address(_user).balance
                );
            } else {
                console2.log(
                    "%s balance end: %d",
                    IERC20(_token1).symbol(),
                    IERC20(_token1).balanceOf(address(_user))
                );
            }
        }
        vm.stopPrank();
    }

    // modifier to ensure no token residue in dexRouter after function execution
    modifier noResidue() {
        _;
        
        // DONOT check ETH balance
        // uint256 ethBalance = address(dexRouter).balance;
        // require(ethBalance == 0, "DexRouter ETH balance must be 0");
        
        // Check ERC20 token balances
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 balance = IERC20(token).balanceOf(address(dexRouter));
            require(balance == 0, "DexRouter %s balance must be 0");
        }
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 22816142); // 2025.6.30 16:50
        vm.startPrank(admin);
        dexRouter = new DexRouter();
        vm.stopPrank();
        address wNativeRelayerOwner = wNativeRelayer.owner();
        vm.startPrank(wNativeRelayerOwner);
        tokenApproveProxy.addProxy(address(dexRouter));
        address[] memory whitelistedCallers = new address[](1);
        whitelistedCallers[0] = address(dexRouter);
        wNativeRelayer.setCallerOk(whitelistedCallers, true);
        vm.stopPrank();
    }

    // ==================== Internal Functions ====================
    function _generateBaseRequest(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) internal view returns (DexRouter.BaseRequest memory baseRequest) {
        baseRequest.fromToken = uint256(uint160(_fromToken));
        baseRequest.toToken = _toToken;
        baseRequest.fromTokenAmount = _amount;
        baseRequest.minReturnAmount = 0;
        baseRequest.deadLine = block.timestamp + 1000;
    }

    function _generateRouterPath(
        RouterPathParam[] memory params
    ) internal view returns (DexRouter.RouterPath memory path) {
        uint256 length = params.length;
        path.mixAdapters = new address[](length);
        path.assetTo = new address[](length);
        path.rawData = new uint256[](length);
        path.extraData = new bytes[](length);
        path.fromToken = uint256(uint160(params[0].fromToken));
        for (uint256 i = 0; i < length; i++) {
            path.rawData[i] = uint256(bytes32(abi.encodePacked(uint64(0x00), uint8(params[i].inputIndex), uint8(params[i].outputIndex), uint16(params[i].weight), address(0))));
            if (params[i].uniVersion == UniVersion.UniV2) {
                path.mixAdapters[i] = UniV2Adapter;
            } else if (params[i].uniVersion == UniVersion.UniV3) {
                path.mixAdapters[i] = UniversalUniV3Adapter;
                path.assetTo[i] = UniversalUniV3Adapter; // For UniV3, the assetTo is the adapter address. But for UniV2, the assetTo is the pool address.
                path.extraData[i] = abi.encode(0, abi.encode(params[i].fromToken, params[i].toToken, 0)); // For UniV3, the extraData is tokenInfo. But for UniV2, the extraData is empty.
            } else {
                revert("Invalid uni version");
            }

            if (params[i].fromToken == tokens[0] && params[i].toToken == tokens[1] || params[i].fromToken == tokens[1] && params[i].toToken == tokens[0]) {
                // WETH<>DAI
                if (params[i].uniVersion == UniVersion.UniV2) {
                    path.assetTo[i] = pools[0];
                    path.rawData[i] = path.rawData[i] | uint256(uint160(pools[0]));
                    if (params[i].fromToken == tokens[0]) { // fromToken == token1, reverse = 1, call sellQuote to sell token1
                        path.rawData[i] = path.rawData[i] | 1 << 255;
                        // console2.log("path.rawData: %x", path.rawData);
                    }
                } else {
                    path.rawData[i] = path.rawData[i] | uint256(uint160(pools[1]));
                }
            } else if (params[i].fromToken == tokens[0] && params[i].toToken == tokens[2] || params[i].fromToken == tokens[2] && params[i].toToken == tokens[0]) {
                // WETH<>USDT
                if (params[i].uniVersion == UniVersion.UniV2) {
                    path.assetTo[i] = pools[2];
                    path.rawData[i] = path.rawData[i] | uint256(uint160(pools[2]));
                    if (params[i].fromToken == tokens[2]) { // fromToken == token1, reverse = 1, call sellQuote to sell token1
                        path.rawData[i] = path.rawData[i] | 1 << 255;
                    }
                } else {
                    path.rawData[i] = path.rawData[i] | uint256(uint160(pools[3]));
                }
            } else if (params[i].fromToken == tokens[0] && params[i].toToken == tokens[3] || params[i].fromToken == tokens[3] && params[i].toToken == tokens[0]) {
                // WETH<>USDC
                if (params[i].uniVersion == UniVersion.UniV2) {
                    path.assetTo[i] = pools[4];
                    path.rawData[i] = path.rawData[i] | uint256(uint160(pools[4]));
                    if (params[i].fromToken == tokens[0]) { // fromToken == token1, reverse = 1, call sellQuote to sell token1
                        path.rawData[i] = path.rawData[i] | 1 << 255;
                    }
                } else {
                    path.rawData[i] = path.rawData[i] | uint256(uint160(pools[5]));
                }
            } else if (params[i].fromToken == tokens[1] && params[i].toToken == tokens[2] || params[i].fromToken == tokens[2] && params[i].toToken == tokens[1]) {
                // DAI<>USDT
                if (params[i].uniVersion == UniVersion.UniV3) {
                    path.rawData[i] = path.rawData[i] | uint256(uint160(pools[6]));
                } else {
                    revert("Invalid uni version");
                }
            } else if (params[i].fromToken == tokens[1] && params[i].toToken == tokens[3] || params[i].fromToken == tokens[3] && params[i].toToken == tokens[1]) {
                // DAI<>USDC
                if (params[i].uniVersion == UniVersion.UniV2) {
                    path.assetTo[i] = pools[7];
                    path.rawData[i] = path.rawData[i] | uint256(uint160(pools[7]));
                    if (params[i].fromToken == tokens[3]) { // fromToken == token1, reverse = 1, call sellQuote to sell token1
                        path.rawData[i] = path.rawData[i] | 1 << 255;
                    }
                } else {
                    path.rawData[i] = path.rawData[i] | uint256(uint160(pools[8]));

                }
            } else if (params[i].fromToken == tokens[2] && params[i].toToken == tokens[3] || params[i].fromToken == tokens[3] && params[i].toToken == tokens[2]) {
                // USDT<>USDC
                if (params[i].uniVersion == UniVersion.UniV2) {
                    path.assetTo[i] = pools[9];
                    path.rawData[i] = path.rawData[i] | uint256(uint160(pools[9]));
                    if (params[i].fromToken == tokens[2]) { // fromToken == token1, reverse = 1, call sellQuote to sell token1
                        path.rawData[i] = path.rawData[i] | 1 << 255;
                    }
                } else {
                    path.rawData[i] = path.rawData[i] | uint256(uint160(pools[10]));
                }
            } else if (params[i].fromToken == tokens[2] && params[i].toToken == tokens[4] || params[i].fromToken == tokens[4] && params[i].toToken == tokens[2]) {
                // USDT<>WBTC
                if (params[i].uniVersion == UniVersion.UniV3) {
                    path.rawData[i] = path.rawData[i] | uint256(uint160(pools[11]));
                } else {
                    revert("Invalid uni version");
                }
            } else if (params[i].fromToken == tokens[3] && params[i].toToken == tokens[4] || params[i].fromToken == tokens[4] && params[i].toToken == tokens[3]) {
                // USDC<>WBTC
                if (params[i].uniVersion == UniVersion.UniV3) {
                    path.rawData[i] = path.rawData[i] | uint256(uint160(pools[12]));
                } else {
                    revert("Invalid uni version");
                }
            } else {
                revert("Invalid token pair");
            }
        }
    }

    /*
     *  100% A(WETH) → B(DAI)
    */
    function _generatePathCase1_WETH2DAI() internal view returns (DexRouter.RouterPath[] memory paths) {
        paths = new DexRouter.RouterPath[](1);
        RouterPathParam[] memory node0 = new RouterPathParam[](1);
        node0[0] = RouterPathParam({
            fromToken: tokens[0],
            toToken: tokens[1],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 1,
            weight: 10000
        });
        paths[0] = _generateRouterPath(node0);
    }

    /*
     *  10% A(WETH) → D(USDC)
     *  40% A(WETH) → C(USDT)
     *  50% A(WETH) → B(DAI) → C(USDT)
     *          ↳ 100% C(USDT) → D(USDC)  
    */
    function _generatePathCase2_WETH2USDC() internal view returns (DexRouter.RouterPath[] memory paths) {
        paths = new DexRouter.RouterPath[](3);
        RouterPathParam[] memory node0 = new RouterPathParam[](3);
        node0[0] = RouterPathParam({
            fromToken: tokens[0],
            toToken: tokens[3],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 3,
            weight: 1000
        });
        node0[1] = RouterPathParam({
            fromToken: tokens[0],
            toToken: tokens[2],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 2,
            weight: 4000
        });
        node0[2] = RouterPathParam({
            fromToken: tokens[0],
            toToken: tokens[1],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 1,
            weight: 5000
        });
        paths[0] = _generateRouterPath(node0);
        RouterPathParam[] memory node1 = new RouterPathParam[](1);
        node1[0] = RouterPathParam({
            fromToken: tokens[1],
            toToken: tokens[2],
            uniVersion: UniVersion.UniV3,
            inputIndex: 1,
            outputIndex: 2,
            weight: 10000
        });
        paths[1] = _generateRouterPath(node1);
        RouterPathParam[] memory node2 = new RouterPathParam[](1);
        node2[0] = RouterPathParam({
            fromToken: tokens[2],
            toToken: tokens[3],
            uniVersion: UniVersion.UniV2,
            inputIndex: 2,
            outputIndex: 3,
            weight: 10000
        });
        paths[2] = _generateRouterPath(node2);
    }
    
    /*
     *  40% A(WETH) → D(USDC)  
     *  60% A(WETH) → B(DAI)  
     *      ↳ 20% B(DAI) → D(USDC)  
     *      ↳ 80% B(DAI) → C(USDT) → D(USDC)
    */
    function _generatePathCase3_WETH2USDC() internal view returns (DexRouter.RouterPath[] memory paths) {
        paths = new DexRouter.RouterPath[](3);
        RouterPathParam[] memory node0 = new RouterPathParam[](2);
        node0[0] = RouterPathParam({
            fromToken: tokens[0],
            toToken: tokens[3],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 3,
            weight: 4000
        });
        node0[1] = RouterPathParam({
            fromToken: tokens[0],
            toToken: tokens[1],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 1,
            weight: 6000
        });
        paths[0] = _generateRouterPath(node0);
        RouterPathParam[] memory node1 = new RouterPathParam[](2);
        node1[0] = RouterPathParam({
            fromToken: tokens[1],
            toToken: tokens[3],
            uniVersion: UniVersion.UniV2,
            inputIndex: 1,
            outputIndex: 3,
            weight: 2000
        });
        node1[1] = RouterPathParam({
            fromToken: tokens[1],
            toToken: tokens[2],
            uniVersion: UniVersion.UniV3,
            inputIndex: 1,
            outputIndex: 2,
            weight: 8000
        });
        paths[1] = _generateRouterPath(node1);
        RouterPathParam[] memory node2 = new RouterPathParam[](1);
        node2[0] = RouterPathParam({
            fromToken: tokens[2],
            toToken: tokens[3],
            uniVersion: UniVersion.UniV2,
            inputIndex: 2,
            outputIndex: 3,
            weight: 10000
        });
        paths[2] = _generateRouterPath(node2);
    }


    /*
     *  90% A(WETH) → B(DAI)  
     *      ↳ 100% B(DAI) → C(USDT)  
     *  10% A(WETH) → C(USDT)  
     *      ↳ 25% C(USDT) → D(USDC) → E(WBTC)  
     *      ↳ 75% C(USDT) → E(WBTC)
    */
    function _generatePathCase4_WETH2WBTC() internal view returns (DexRouter.RouterPath[] memory paths) {
        paths = new DexRouter.RouterPath[](4);
        RouterPathParam[] memory node0 = new RouterPathParam[](2);
        node0[0] = RouterPathParam({
            fromToken: tokens[0],
            toToken: tokens[1],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 1,
            weight: 9000
        });
        node0[1] = RouterPathParam({
            fromToken: tokens[0],
            toToken: tokens[2],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 2,
            weight: 1000
        });
        paths[0] = _generateRouterPath(node0);
        RouterPathParam[] memory node1 = new RouterPathParam[](1);
        node1[0] = RouterPathParam({
            fromToken: tokens[1],
            toToken: tokens[2],
            uniVersion: UniVersion.UniV3,
            inputIndex: 1,
            outputIndex: 2,
            weight: 10000
        });
        paths[1] = _generateRouterPath(node1);
        RouterPathParam[] memory node2 = new RouterPathParam[](2);
        node2[0] = RouterPathParam({
            fromToken: tokens[2],
            toToken: tokens[3],
            uniVersion: UniVersion.UniV2,
            inputIndex: 2,
            outputIndex: 3,
            weight: 2500
        });
        node2[1] = RouterPathParam({
            fromToken: tokens[2],
            toToken: tokens[4],
            uniVersion: UniVersion.UniV3,
            inputIndex: 2,
            outputIndex: 4,
            weight: 7500
        });
        paths[2] = _generateRouterPath(node2);
        RouterPathParam[] memory node3 = new RouterPathParam[](1);
        node3[0] = RouterPathParam({
            fromToken: tokens[3],
            toToken: tokens[4],
            uniVersion: UniVersion.UniV3,
            inputIndex: 3,
            outputIndex: 4,
            weight: 10000
        });
        paths[3] = _generateRouterPath(node3);
    }

    /*
     *  B1 and B2 are same token at different nodes
     *  90% A(WETH) → B1(DAI)  
     *      ↳ 100% B1(DAI) → C(USDC)  
     *  10% A(WETH) → C(USDC)  
     *      ↳ 25% C(USDC) → B2(DAI) → D(USDT)
     *      ↳ 75% C(USDC) → D(USDT)
    */
    function _generatePathCase5_WETH2USDT() internal view returns (DexRouter.RouterPath[] memory paths) {
        paths = new DexRouter.RouterPath[](4);
        RouterPathParam[] memory node0 = new RouterPathParam[](2);
        node0[0] = RouterPathParam({
            fromToken: tokens[0],
            toToken: tokens[1],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 1,
            weight: 9000
        });
        node0[1] = RouterPathParam({
            fromToken: tokens[0],
            toToken: tokens[3],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 2,
            weight: 1000
        });
        paths[0] = _generateRouterPath(node0);
        RouterPathParam[] memory node1 = new RouterPathParam[](1);
        node1[0] = RouterPathParam({
            fromToken: tokens[1],
            toToken: tokens[3],
            uniVersion: UniVersion.UniV3,
            inputIndex: 1,
            outputIndex: 2,
            weight: 10000
        });
        paths[1] = _generateRouterPath(node1);
        RouterPathParam[] memory node2 = new RouterPathParam[](2);
        node2[0] = RouterPathParam({
            fromToken: tokens[3],
            toToken: tokens[1],
            uniVersion: UniVersion.UniV2,
            inputIndex: 2,
            outputIndex: 3,
            weight: 2500
        });
        node2[1] = RouterPathParam({
            fromToken: tokens[3],
            toToken: tokens[2],
            uniVersion: UniVersion.UniV3,
            inputIndex: 2,
            outputIndex: 4,
            weight: 7500
        });
        paths[2] = _generateRouterPath(node2);
        RouterPathParam[] memory node3 = new RouterPathParam[](1);
        node3[0] = RouterPathParam({
            fromToken: tokens[1],
            toToken: tokens[2],
            uniVersion: UniVersion.UniV3,
            inputIndex: 3,
            outputIndex: 4,
            weight: 10000
        });
        paths[3] = _generateRouterPath(node3);
    }

    /*
     *  100% A(DAI) → B(WETH)
    */
    function _generatePathCase1_DAI2WETH() internal view returns (DexRouter.RouterPath[] memory paths) {
        paths = new DexRouter.RouterPath[](1);
        RouterPathParam[] memory node0 = new RouterPathParam[](1);
        node0[0] = RouterPathParam({
            fromToken: tokens[1],
            toToken: tokens[0],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 1,
            weight: 10000
        });
        paths[0] = _generateRouterPath(node0);
    }

    /*
     *  10% A(USDC) → D(WETH)
     *  40% A(USDC) → C(USDT)
     *  50% A(USDC) → B(DAI) → C(USDT)
     *          ↳ 100% C(USDT) → D(WETH)  
    */
    function _generatePathCase2_USDC2WETH() internal view returns (DexRouter.RouterPath[] memory paths) {
        paths = new DexRouter.RouterPath[](3);
        RouterPathParam[] memory node0 = new RouterPathParam[](3);
        node0[0] = RouterPathParam({
            fromToken: tokens[3],
            toToken: tokens[0],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 3,
            weight: 1000
        });
        node0[1] = RouterPathParam({
            fromToken: tokens[3],
            toToken: tokens[2],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 2,
            weight: 4000
        });
        node0[2] = RouterPathParam({
            fromToken: tokens[3],
            toToken: tokens[1],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 1,
            weight: 5000
        });
        paths[0] = _generateRouterPath(node0);
        RouterPathParam[] memory node1 = new RouterPathParam[](1);
        node1[0] = RouterPathParam({
            fromToken: tokens[1],
            toToken: tokens[2],
            uniVersion: UniVersion.UniV3,
            inputIndex: 1,
            outputIndex: 2,
            weight: 10000
        });
        paths[1] = _generateRouterPath(node1);
        RouterPathParam[] memory node2 = new RouterPathParam[](1);
        node2[0] = RouterPathParam({
            fromToken: tokens[2],
            toToken: tokens[0],
            uniVersion: UniVersion.UniV2,
            inputIndex: 2,
            outputIndex: 3,
            weight: 10000
        });
        paths[2] = _generateRouterPath(node2);
    }

    /*
     *  40% A(USDC) → D(WETH)  
     *  60% A(USDC) → B(DAI)  
     *      ↳ 20% B(DAI) → D(WETH)  
     *      ↳ 80% B(DAI) → C(USDT) → D(WETH)
    */
    function _generatePathCase3_USDC2WETH() internal view returns (DexRouter.RouterPath[] memory paths) {
        paths = new DexRouter.RouterPath[](3);
        RouterPathParam[] memory node0 = new RouterPathParam[](2);
        node0[0] = RouterPathParam({
            fromToken: tokens[3],
            toToken: tokens[0],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 3,
            weight: 4000
        });
        node0[1] = RouterPathParam({
            fromToken: tokens[3],
            toToken: tokens[1],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 1,
            weight: 6000
        });
        paths[0] = _generateRouterPath(node0);
        RouterPathParam[] memory node1 = new RouterPathParam[](2);
        node1[0] = RouterPathParam({
            fromToken: tokens[1],
            toToken: tokens[0],
            uniVersion: UniVersion.UniV2,
            inputIndex: 1,
            outputIndex: 3,
            weight: 2000
        });
        node1[1] = RouterPathParam({
            fromToken: tokens[1],
            toToken: tokens[2],
            uniVersion: UniVersion.UniV3,
            inputIndex: 1,
            outputIndex: 2,
            weight: 8000
        });
        paths[1] = _generateRouterPath(node1);
        RouterPathParam[] memory node2 = new RouterPathParam[](1);
        node2[0] = RouterPathParam({
            fromToken: tokens[2],
            toToken: tokens[0],
            uniVersion: UniVersion.UniV2,
            inputIndex: 2,
            outputIndex: 3,
            weight: 10000
        });
        paths[2] = _generateRouterPath(node2);
    }

    /*
     *  90% A(WBTC) → B(USDT)  
     *      ↳ 100% B(USDT) → C(USDC)  
     *  10% A(WBTC) → C(USDC)  
     *      ↳ 25% C(USDC) → D(DAI) → E(WETH)  
     *      ↳ 75% C(USDC) → E(WETH)
    */
    function _generatePathCase4_WBTC2WETH() internal view returns (DexRouter.RouterPath[] memory paths) {
        paths = new DexRouter.RouterPath[](4);
        RouterPathParam[] memory node0 = new RouterPathParam[](2);
        node0[0] = RouterPathParam({
            fromToken: tokens[4],
            toToken: tokens[2],
            uniVersion: UniVersion.UniV3,
            inputIndex: 0,
            outputIndex: 1,
            weight: 9000
        });
        node0[1] = RouterPathParam({
            fromToken: tokens[4],
            toToken: tokens[3],
            uniVersion: UniVersion.UniV3,
            inputIndex: 0,
            outputIndex: 2,
            weight: 1000
        });
        paths[0] = _generateRouterPath(node0);
        RouterPathParam[] memory node1 = new RouterPathParam[](1);
        node1[0] = RouterPathParam({
            fromToken: tokens[2],
            toToken: tokens[3],
            uniVersion: UniVersion.UniV2,
            inputIndex: 1,
            outputIndex: 2,
            weight: 10000
        });
        paths[1] = _generateRouterPath(node1);
        RouterPathParam[] memory node2 = new RouterPathParam[](2);
        node2[0] = RouterPathParam({
            fromToken: tokens[3],
            toToken: tokens[1],
            uniVersion: UniVersion.UniV2,
            inputIndex: 2,
            outputIndex: 3,
            weight: 2500
        });
        node2[1] = RouterPathParam({
            fromToken: tokens[3],
            toToken: tokens[0],
            uniVersion: UniVersion.UniV2,
            inputIndex: 2,
            outputIndex: 4,
            weight: 7500
        });
        paths[2] = _generateRouterPath(node2);
        RouterPathParam[] memory node3 = new RouterPathParam[](1);
        node3[0] = RouterPathParam({
            fromToken: tokens[1],
            toToken: tokens[0],
            uniVersion: UniVersion.UniV2,
            inputIndex: 3,
            outputIndex: 4,
            weight: 10000
        });
        paths[3] = _generateRouterPath(node3);
    }

    /*
     *  B1 and B2 are same token at different nodes
     *  90% A(USDT) → B1(DAI)  
     *      ↳ 100% B1(DAI) → C(USDC)  
     *  10% A(USDT) → C(USDC)  
     *      ↳ 25% C(USDC) → B2(DAI) → D(WETH)
     *      ↳ 75% C(USDC) → D(WETH)
    */
    function _generatePathCase5_USDT2WETH() internal view returns (DexRouter.RouterPath[] memory paths) {
        paths = new DexRouter.RouterPath[](4);
        RouterPathParam[] memory node0 = new RouterPathParam[](2);
        node0[0] = RouterPathParam({
            fromToken: tokens[2],
            toToken: tokens[1],
            uniVersion: UniVersion.UniV3,
            inputIndex: 0,
            outputIndex: 1,
            weight: 9000
        });
        node0[1] = RouterPathParam({
            fromToken: tokens[2],
            toToken: tokens[3],
            uniVersion: UniVersion.UniV2,
            inputIndex: 0,
            outputIndex: 2,
            weight: 1000
        });
        paths[0] = _generateRouterPath(node0);
        RouterPathParam[] memory node1 = new RouterPathParam[](1);
        node1[0] = RouterPathParam({
            fromToken: tokens[1],
            toToken: tokens[3],
            uniVersion: UniVersion.UniV3,
            inputIndex: 1,
            outputIndex: 2,
            weight: 10000
        });
        paths[1] = _generateRouterPath(node1);
        RouterPathParam[] memory node2 = new RouterPathParam[](2);
        node2[0] = RouterPathParam({
            fromToken: tokens[3],
            toToken: tokens[1],
            uniVersion: UniVersion.UniV2,
            inputIndex: 2,
            outputIndex: 3,
            weight: 2500
        });
        node2[1] = RouterPathParam({
            fromToken: tokens[3],
            toToken: tokens[0],
            uniVersion: UniVersion.UniV3,
            inputIndex: 2,
            outputIndex: 4,
            weight: 7500
        });
        paths[2] = _generateRouterPath(node2);
        RouterPathParam[] memory node3 = new RouterPathParam[](1);
        node3[0] = RouterPathParam({
            fromToken: tokens[1],
            toToken: tokens[0],
            uniVersion: UniVersion.UniV3,
            inputIndex: 3,
            outputIndex: 4,
            weight: 10000
        });
        paths[3] = _generateRouterPath(node3);
    }
}
