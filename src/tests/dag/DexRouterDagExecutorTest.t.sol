// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@dex/DexRouterDagExecutor.sol";
import "@dex/utils/WNativeRelayer.sol";
import "@dex/interfaces/IWETH.sol";

contract DexRouterDagExecutorPoc is Test {
    enum UniVersion {
        UniV2,
        UniV3
    }

    // tokens
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address[] tokens = [
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, // WETH, decimals=18
        0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI, decimals=18
        0xdAC17F958D2ee523a2206206994597C13D831ec7, // USDT, decimals=6
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC, decimals=6
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599  // WBTC, decimals=8
    ];
    // pools
    address[] pools = [
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

    DexRouterDagExecutor dagExecutor;
    WNativeRelayer wNativeRelayer = WNativeRelayer(payable(0x5703B683c7F928b721CA95Da988d73a3299d4757)); // ETH
    address UniversalUniV3Adapter = 0x6747BcaF9bD5a5F0758Cbe08903490E45DdfACB5;
    address UniV2Adapter = 0xc837BbEa8C7b0caC0e8928f797ceB04A34c9c06e;

    address admin = vm.rememberKey(1);
    address arnaud = vm.rememberKey(11111111);

    uint256 oneEther = 1 * 10 ** 18;

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
        
        // Check ETH balance
        uint256 ethBalance = address(dagExecutor).balance;
        if (ethBalance > 0) {
            console2.log("DexRouter ETH balance: %d", ethBalance);
        }
        
        // Check ERC20 token balances
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 balance = IERC20(token).balanceOf(address(dagExecutor));
            if (balance > 0) {
                console2.log("DexRouter %s balance: %d", IERC20(token).symbol(), balance);
            }
        }
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 22816142); // 2025.6.30 16:50
        vm.startPrank(admin);
        dagExecutor = new DexRouterDagExecutor();
        vm.stopPrank();
        address wNativeRelayerOwner = wNativeRelayer.owner();
        vm.startPrank(wNativeRelayerOwner);
        address[] memory whitelistedCallers = new address[](1);
        whitelistedCallers[0] = address(dagExecutor);
        wNativeRelayer.setCallerOk(whitelistedCallers, true);
        vm.stopPrank();
    }

    /*
     *  100% A(WETH) → B(DAI)
    */
    function test_DexRouterDagExecutor_case1() public userWithToken(arnaud, tokens[0], tokens[1], oneEther) noResidue {
        DexRouterDagExecutor.BaseRequest memory baseRequest = _generateBaseRequest(tokens[0], tokens[1], oneEther);
        DexRouterDagExecutor.RouterPath[][] memory paths = new DexRouterDagExecutor.RouterPath[][](1);
        paths[0] = new DexRouterDagExecutor.RouterPath[](1);
        paths[0][0] = _generateRouterPath(tokens[0], tokens[1], UniVersion.UniV2, 0, 1, 10000);
        IERC20(tokens[0]).transfer(address(dagExecutor), oneEther);
        dagExecutor.swapTo(arnaud, arnaud, baseRequest, paths);
    }

    /*
     *  10% A(WETH) → D(USDC)
     *  40% A(WETH) → C(USDT)
     *  50% A(WETH) → B(DAI) → C(USDT)
     *          ↳ 100% C(USDT) → D(USDC)  
    */
    function test_DexRouterDagExecutor_case2() public userWithToken(arnaud, tokens[0], tokens[3], oneEther) noResidue {
        DexRouterDagExecutor.BaseRequest memory baseRequest = _generateBaseRequest(tokens[0], tokens[3], oneEther);
        DexRouterDagExecutor.RouterPath[][] memory paths = new DexRouterDagExecutor.RouterPath[][](3);
        paths[0] = new DexRouterDagExecutor.RouterPath[](3);
        paths[0][0] = _generateRouterPath(tokens[0], tokens[3], UniVersion.UniV2, 0, 3, 1000);
        paths[0][1] = _generateRouterPath(tokens[0], tokens[2], UniVersion.UniV2, 0, 2, 4000);
        paths[0][2] = _generateRouterPath(tokens[0], tokens[1], UniVersion.UniV2, 0, 1, 5000);
        paths[1] = new DexRouterDagExecutor.RouterPath[](1);
        paths[1][0] = _generateRouterPath(tokens[1], tokens[2], UniVersion.UniV3, 1, 2, 10000);
        paths[2] = new DexRouterDagExecutor.RouterPath[](1);
        paths[2][0] = _generateRouterPath(tokens[2], tokens[3], UniVersion.UniV2, 2, 3, 10000);
        IERC20(tokens[0]).transfer(address(dagExecutor), oneEther);
        dagExecutor.swapTo(arnaud, arnaud, baseRequest, paths);
    }

    /*
     *  40% A(WETH) → D(USDC)  
     *  60% A(WETH) → B(DAI)  
     *      ↳ 20% B(DAI) → D(USDC)  
     *      ↳ 80% B(DAI) → C(USDT) → D(USDC)
    */
    function test_DexRouterDagExecutor_case3() public userWithToken(arnaud, tokens[0], tokens[3], oneEther) noResidue {
        DexRouterDagExecutor.BaseRequest memory baseRequest = _generateBaseRequest(tokens[0], tokens[3], oneEther);
        DexRouterDagExecutor.RouterPath[][] memory paths = new DexRouterDagExecutor.RouterPath[][](3);
        paths[0] = new DexRouterDagExecutor.RouterPath[](2);
        paths[0][0] = _generateRouterPath(tokens[0], tokens[3], UniVersion.UniV2, 0, 3, 4000);
        paths[0][1] = _generateRouterPath(tokens[0], tokens[1], UniVersion.UniV2, 0, 2, 6000);
        paths[1] = new DexRouterDagExecutor.RouterPath[](2);
        paths[1][0] = _generateRouterPath(tokens[1], tokens[3], UniVersion.UniV2, 1, 3, 2000);
        paths[1][1] = _generateRouterPath(tokens[1], tokens[2], UniVersion.UniV3, 1, 2, 8000);
        paths[2] = new DexRouterDagExecutor.RouterPath[](1);
        paths[2][0] = _generateRouterPath(tokens[2], tokens[3], UniVersion.UniV2, 2, 3, 10000);
        IERC20(tokens[0]).transfer(address(dagExecutor), oneEther);
        dagExecutor.swapTo(arnaud, arnaud, baseRequest, paths);
    }

    /*
     *  90% A(WETH) → B(DAI)  
     *      ↳ 100% B(DAI) → C(USDT)  
     *  10% A(WETH) → C(USDT)  
     *      ↳ 25% C(USDT) → D(USDC) → E(WBTC)  
     *      ↳ 75% C(USDT) → E(WBTC)
    */
    function test_DexRouterDagExecutor_case4() public userWithToken(arnaud, tokens[0], tokens[4], oneEther) noResidue {
        DexRouterDagExecutor.BaseRequest memory baseRequest = _generateBaseRequest(tokens[0], tokens[4], oneEther);
        DexRouterDagExecutor.RouterPath[][] memory paths = new DexRouterDagExecutor.RouterPath[][](4);
        paths[0] = new DexRouterDagExecutor.RouterPath[](2);
        paths[0][0] = _generateRouterPath(tokens[0], tokens[1], UniVersion.UniV2, 0, 1, 9000);
        paths[0][1] = _generateRouterPath(tokens[0], tokens[2], UniVersion.UniV2, 0, 2, 1000);
        paths[1] = new DexRouterDagExecutor.RouterPath[](1);
        paths[1][0] = _generateRouterPath(tokens[1], tokens[2], UniVersion.UniV3, 1, 2, 10000);
        paths[2] = new DexRouterDagExecutor.RouterPath[](2);
        paths[2][0] = _generateRouterPath(tokens[2], tokens[3], UniVersion.UniV2, 2, 3, 2500);
        paths[2][1] = _generateRouterPath(tokens[2], tokens[4], UniVersion.UniV3, 2, 4, 7500);
        paths[3] = new DexRouterDagExecutor.RouterPath[](1);
        paths[3][0] = _generateRouterPath(tokens[3], tokens[4], UniVersion.UniV3, 3, 4, 10000);
        IERC20(tokens[0]).transfer(address(dagExecutor), oneEther);
        dagExecutor.swapTo(arnaud, arnaud, baseRequest, paths);
    }

    /*
     *  B1 and B2 are same token at different nodes
     *  90% A(WETH) → B1(DAI)  
     *      ↳ 100% B1(DAI) → C(USDC)  
     *  10% A(WETH) → C(USDC)  
     *      ↳ 25% C(USDC) → B2(DAI) → D(USDT)
     *      ↳ 75% C(USDC) → D(USDT)
    */
    function test_DexRouterDagExecutor_case5() public userWithToken(arnaud, tokens[0], tokens[2], oneEther) noResidue {
        DexRouterDagExecutor.BaseRequest memory baseRequest = _generateBaseRequest(tokens[0], tokens[2], oneEther);
        DexRouterDagExecutor.RouterPath[][] memory paths = new DexRouterDagExecutor.RouterPath[][](4);
        paths[0] = new DexRouterDagExecutor.RouterPath[](2);
        paths[0][0] = _generateRouterPath(tokens[0], tokens[1], UniVersion.UniV2, 0, 1, 9000); // 90% A(WETH) → B1(DAI)
        paths[0][1] = _generateRouterPath(tokens[0], tokens[3], UniVersion.UniV2, 0, 2, 1000); // 10% A(WETH) → C(USDC)
        paths[1] = new DexRouterDagExecutor.RouterPath[](1);
        paths[1][0] = _generateRouterPath(tokens[1], tokens[3], UniVersion.UniV3, 1, 2, 10000); // 100% B1(DAI) → C(USDC)
        paths[2] = new DexRouterDagExecutor.RouterPath[](2);
        paths[2][0] = _generateRouterPath(tokens[3], tokens[1], UniVersion.UniV2, 2, 3, 2500); // 25% C(USDC) → B2(DAI)
        paths[2][1] = _generateRouterPath(tokens[3], tokens[2], UniVersion.UniV3, 2, 4, 7500); // 75% C(USDC) → D(USDT)
        paths[3] = new DexRouterDagExecutor.RouterPath[](1);
        paths[3][0] = _generateRouterPath(tokens[1], tokens[2], UniVersion.UniV3, 3, 4, 10000); // 100% B2(DAI) → C(USDT)
        IERC20(tokens[0]).transfer(address(dagExecutor), oneEther);
        dagExecutor.swapTo(arnaud, arnaud, baseRequest, paths);
    }

    // ==================== Internal Functions ====================
    function _generateBaseRequest(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) internal view returns (DexRouterDagExecutor.BaseRequest memory baseRequest) {
        baseRequest.fromToken = uint256(uint160(_fromToken));
        baseRequest.toToken = _toToken;
        baseRequest.fromTokenAmount = _amount;
        baseRequest.minReturnAmount = 0;
        baseRequest.deadLine = block.timestamp + 1000;
    }

    function _generateRouterPath(
        address _fromToken,
        address _toToken,
        UniVersion _uniVersion,
        uint8 _inputIndex,
        uint8 _outputIndex,
        uint16 _weight
    ) internal view returns (DexRouterDagExecutor.RouterPath memory path) {
        path.fromToken = uint256(uint160(_fromToken));
        path.rawData = uint256(bytes32(abi.encodePacked(uint64(0x00), uint8(_inputIndex), uint8(_outputIndex), uint16(_weight), address(0))));
        if (_uniVersion == UniVersion.UniV2) {
            path.mixAdapter = UniV2Adapter;
        } else if (_uniVersion == UniVersion.UniV3) {
            path.mixAdapter = UniversalUniV3Adapter;
            path.assetTo = UniversalUniV3Adapter; // For UniV3, the assetTo is the adapter address. But for UniV2, the assetTo is the pool address.
            path.extraData = abi.encode(0, abi.encode(_fromToken, _toToken, 0)); // For UniV3, the extraData is tokenInfo. But for UniV2, the extraData is empty.
        } else {
            revert("Invalid uni version");
        }

        if (_fromToken == tokens[0] && _toToken == tokens[1] || _fromToken == tokens[1] && _toToken == tokens[0]) {
            // WETH<>DAI
            if (_uniVersion == UniVersion.UniV2) {
                path.assetTo = pools[0];
                path.rawData = path.rawData | uint256(uint160(pools[0]));
                if (_fromToken == tokens[0]) { // fromToken == token1, reverse = 1, call sellQuote to sell token1
                    path.rawData = path.rawData | 1 << 255;
                    // console2.log("path.rawData: %x", path.rawData);
                }
            } else {
                path.rawData = path.rawData | uint256(uint160(pools[1]));
            }
        } else if (_fromToken == tokens[0] && _toToken == tokens[2] || _fromToken == tokens[2] && _toToken == tokens[0]) {
            // WETH<>USDT
            if (_uniVersion == UniVersion.UniV2) {
                path.assetTo = pools[2];
                path.rawData = path.rawData | uint256(uint160(pools[2]));
                if (_fromToken == tokens[2]) { // fromToken == token1, reverse = 1, call sellQuote to sell token1
                    path.rawData = path.rawData | 1 << 255;
                }
            } else {
                path.rawData = path.rawData | uint256(uint160(pools[3]));
            }
        } else if (_fromToken == tokens[0] && _toToken == tokens[3] || _fromToken == tokens[3] && _toToken == tokens[0]) {
            // WETH<>USDC
            if (_uniVersion == UniVersion.UniV2) {
                path.assetTo = pools[4];
                path.rawData = path.rawData | uint256(uint160(pools[4]));
                if (_fromToken == tokens[0]) { // fromToken == token1, reverse = 1, call sellQuote to sell token1
                    path.rawData = path.rawData | 1 << 255;
                }
            } else {
                path.rawData = path.rawData | uint256(uint160(pools[5]));
            }
        } else if (_fromToken == tokens[1] && _toToken == tokens[2] || _fromToken == tokens[2] && _toToken == tokens[1]) {
            // DAI<>USDT
            if (_uniVersion == UniVersion.UniV3) {
                path.rawData = path.rawData | uint256(uint160(pools[6]));
            } else {
                revert("Invalid uni version");
            }
        } else if (_fromToken == tokens[1] && _toToken == tokens[3] || _fromToken == tokens[3] && _toToken == tokens[1]) {
            // DAI<>USDC
            if (_uniVersion == UniVersion.UniV2) {
                path.assetTo = pools[7];
                path.rawData = path.rawData | uint256(uint160(pools[7]));
                if (_fromToken == tokens[3]) { // fromToken == token1, reverse = 1, call sellQuote to sell token1
                    path.rawData = path.rawData | 1 << 255;
                }
            } else {
                path.rawData = path.rawData | uint256(uint160(pools[8]));

            }
        } else if (_fromToken == tokens[2] && _toToken == tokens[3] || _fromToken == tokens[3] && _toToken == tokens[2]) {
            // USDT<>USDC
            if (_uniVersion == UniVersion.UniV2) {
                path.assetTo = pools[9];
                path.rawData = path.rawData | uint256(uint160(pools[9]));
                if (_fromToken == tokens[2]) { // fromToken == token1, reverse = 1, call sellQuote to sell token1
                    path.rawData = path.rawData | 1 << 255;
                }
            } else {
                path.rawData = path.rawData | uint256(uint160(pools[10]));
            }
        } else if (_fromToken == tokens[2] && _toToken == tokens[4] || _fromToken == tokens[4] && _toToken == tokens[2]) {
            // USDT<>WBTC
            if (_uniVersion == UniVersion.UniV3) {
                path.rawData = path.rawData | uint256(uint160(pools[11]));
            } else {
                revert("Invalid uni version");
            }
        } else if (_fromToken == tokens[3] && _toToken == tokens[4] || _fromToken == tokens[4] && _toToken == tokens[3]) {
            // USDC<>WBTC
            if (_uniVersion == UniVersion.UniV3) {
                path.rawData = path.rawData | uint256(uint160(pools[12]));
            } else {
                revert("Invalid uni version");
            }
        } else {
            revert("Invalid token pair");
        }
    }
}
