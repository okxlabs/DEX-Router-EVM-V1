// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@dex/DexRouter.sol";
import "@dex/utils/WNativeRelayer.sol";
import "@dex/TokenApprove.sol";
import "@dex/TokenApproveProxy.sol";

contract TeeMethodsTest is Test {
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    IWETH WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); // ETH
    IERC20 USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7); // ETH, decimals=6
    address USDT_WETH_UNIV2_POOL = 0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852; // ETH, token0 is WETH, token1 is USDT
    address USDT_WETH_UNIV3_POOL = 0x4e68Ccd3E89f51C3074ca5072bbAC773960dFa36; // ETH, token0 is WETH, token1 is USDT

    DexRouter dexRouter;
    WNativeRelayer wNativeRelayer = WNativeRelayer(payable(0x5703B683c7F928b721CA95Da988d73a3299d4757)); // ETH
    TokenApprove tokenApprove = TokenApprove(payable(0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f)); // ETH
    TokenApproveProxy tokenApproveProxy = TokenApproveProxy(payable(0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58)); // ETH

    address admin = vm.rememberKey(1);
    address arnaud = vm.rememberKey(11111111);
    address bob = vm.rememberKey(22222222);

    uint256 swapETHAmount = 0.01 * 10 ** 18;
    uint256 swapUSDTAmount = 1000 * 10 ** 6;

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
        vm.stopPrank();
    }

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 22816142); // 2025.6.30 16:50
        vm.startPrank(admin);
        dexRouter = new DexRouter();
        vm.stopPrank();
        address tokenApproveProxyOwner = tokenApproveProxy.owner();
        vm.startPrank(tokenApproveProxyOwner);
        tokenApproveProxy.addProxy(address(dexRouter));
        vm.stopPrank();
        address wNativeRelayerOwner = wNativeRelayer.owner();
        vm.startPrank(wNativeRelayerOwner);
        address[] memory whitelistedCallers = new address[](1);
        whitelistedCallers[0] = address(dexRouter);
        wNativeRelayer.setCallerOk(whitelistedCallers, true);
        vm.stopPrank();
    }

    function test_uniswapV3SwapToWithBaseRequest_WETH2USDT() public userWithToken(arnaud, address(WETH), address(USDT), swapETHAmount) {
        WETH.approve(address(tokenApprove), swapETHAmount);
        DexRouter.BaseRequest memory baseRequest = _genBaseRequest(address(WETH), address(USDT), swapETHAmount);
        uint256[] memory pools = new uint256[](1);
        pools[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint56(0), uint32(swapETHAmount * 9999 / 10000), address(USDT_WETH_UNIV3_POOL))));
        
        dexRouter.uniswapV3SwapToWithBaseRequest(0, address(arnaud), baseRequest, pools);
    }

    function test_uniswapV3SwapToWithBaseRequest_ETH2USDT() public userWithToken(arnaud, address(ETH), address(USDT), swapETHAmount) {
        DexRouter.BaseRequest memory baseRequest = _genBaseRequest(address(ETH), address(USDT), swapETHAmount);
        uint256[] memory pools = new uint256[](1);
        pools[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint56(0), uint32(swapETHAmount * 9999 / 10000), address(USDT_WETH_UNIV3_POOL))));
        
        dexRouter.uniswapV3SwapToWithBaseRequest{value: swapETHAmount}(0, address(arnaud), baseRequest, pools);
    }

    function test_uniswapV3SwapToWithBaseRequest_USDT2ETH() public userWithToken(arnaud, address(USDT), address(ETH), swapUSDTAmount) {
        SafeERC20.safeApprove(IERC20(address(USDT)), address(tokenApprove), swapUSDTAmount);
        DexRouter.BaseRequest memory baseRequest = _genBaseRequest(address(USDT), address(ETH), swapUSDTAmount);
        uint256[] memory pools = new uint256[](1);
        pools[0] = uint256(bytes32(abi.encodePacked(uint8(0xa0), uint56(0), uint32(swapUSDTAmount * 9999 / 10000), address(USDT_WETH_UNIV3_POOL))));
        
        dexRouter.uniswapV3SwapToWithBaseRequest(0, address(arnaud), baseRequest, pools);
    }

    function test_unxswapToWithBaseRequest_WETH2USDT() public userWithToken(arnaud, address(WETH), address(USDT), swapETHAmount) {
        WETH.approve(address(tokenApprove), swapETHAmount);
        DexRouter.BaseRequest memory baseRequest = _genBaseRequest(address(WETH), address(USDT), swapETHAmount);
        bytes32[] memory pools = new bytes32[](1);
        pools[0] = bytes32(abi.encodePacked(uint8(0x00), uint56(0), uint32(swapETHAmount * 996 / 1000), address(USDT_WETH_UNIV2_POOL)));
        dexRouter.unxswapToWithBaseRequest(0, address(arnaud), baseRequest, pools);
    }

    function test_unxswapToWithBaseRequest_ETH2USDT() public userWithToken(arnaud, address(ETH), address(USDT), swapETHAmount) {
        DexRouter.BaseRequest memory baseRequest = _genBaseRequest(address(0), address(USDT), swapETHAmount);
        bytes32[] memory pools = new bytes32[](1);
        pools[0] = bytes32(abi.encodePacked(uint8(0x00), uint56(0), uint32(swapETHAmount * 996 / 1000), address(USDT_WETH_UNIV2_POOL)));
        dexRouter.unxswapToWithBaseRequest{value: swapETHAmount}(0, address(arnaud), baseRequest, pools);
    }

    function test_unxswapToWithBaseRequest_USDT2ETH() public userWithToken(arnaud, address(USDT), address(ETH), swapUSDTAmount) {
        SafeERC20.safeApprove(IERC20(address(USDT)), address(tokenApprove), swapUSDTAmount);
        DexRouter.BaseRequest memory baseRequest = _genBaseRequest(address(USDT), address(0), swapUSDTAmount);
        bytes32[] memory pools = new bytes32[](1);
        pools[0] = bytes32(abi.encodePacked(uint8(0xc0), uint56(0), uint32(swapUSDTAmount * 996 / 1000), address(USDT_WETH_UNIV2_POOL)));
        dexRouter.unxswapToWithBaseRequest(0, address(arnaud), baseRequest, pools);
    }

    function test_swapWrapToWithBaseRequest_ETH2WETH() public userWithToken(arnaud, address(ETH), address(WETH), swapETHAmount) {
        DexRouter.BaseRequest memory baseRequest = _genBaseRequest(address(ETH), address(WETH), swapETHAmount);
        dexRouter.swapWrapToWithBaseRequest{value: swapETHAmount}(0, address(arnaud), baseRequest);
    }

    function test_swapWrapToWithBaseRequest_WETH2ETH() public userWithToken(arnaud, address(WETH), address(ETH), swapETHAmount) {
        WETH.approve(address(tokenApprove), swapETHAmount);
        DexRouter.BaseRequest memory baseRequest = _genBaseRequest(address(WETH), address(ETH), swapETHAmount);
        dexRouter.swapWrapToWithBaseRequest(0, address(arnaud), baseRequest);
    }

    // internal function only for this test contract
    function _genBaseRequest(address _fromToken, address _toToken, uint256 _fromTokenAmount) internal view returns (DexRouter.BaseRequest memory) {
        DexRouter.BaseRequest memory baseRequest;
        baseRequest.fromToken = uint256(uint160(_fromToken));
        baseRequest.toToken = _toToken;
        baseRequest.fromTokenAmount = _fromTokenAmount;
        baseRequest.minReturnAmount = 0;
        baseRequest.deadLine = block.timestamp;
        return baseRequest;
    }
}