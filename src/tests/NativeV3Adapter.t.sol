pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/adapter/NativeV3Adapter.sol";
import "@dex/DexRouter.sol";
import {PMMLib} from "@dex/libraries/PMMLib.sol";

contract NativeV3AdapterTest is Test {
    DexRouter dexRouter = DexRouter(payable(0xDcB7028E5EAA1d7bB82B7152Cb0e7adC12e7457c)); // pre on eth
    address tokenApprove = 0xfFb8322DEEeADF0d61589211493Fb2Dc668D3CC0;

    // address on eth
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address NWETH = 0x5994258Ec80Cc6853e2B6F047Ec6D213FE89B24b; // Native LP Token of WETH, token0
    address NUSDC = 0x91F70f89915f8E5fc9fdD8078685067a49cc6C28; // Native LP Token of USDC, token1
    address NWETH_NUSDC = 0x933347830121Ed36D1A98A8F3ddF75b6393B4ED3; // NativeV3Pool of N-WETH and N-USDC
    address CREDIT_VAULT = 0xe3D41d19564922C9952f692C5Dd0563030f5f2EF; // CreditVault

    address arnaud = vm.rememberKey(1);

    NativeV3Adapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 22221000);
        adapter = new NativeV3Adapter(CREDIT_VAULT); // local deployed adapter

        // set trusted operator for NWETH
        bytes memory ownerCalldata = abi.encodeWithSignature("owner()");
        (bool success, bytes memory result) = NWETH.call(ownerCalldata);
        require(success, "Failed to get owner for NWETH");
        address ownerNWETH = abi.decode(result, (address));
        bytes memory setTrustedOperatorCalldata = abi.encodeWithSignature(
            "setTrustedOperator(address,bool)",
            address(adapter),
            true
        );
        vm.prank(ownerNWETH);
        (success, ) = NWETH.call(setTrustedOperatorCalldata);
        require(success, "Failed to set trusted operator for NWETH");

        // set trusted operator for NUSDC
        (success, result) = NUSDC.call(ownerCalldata);
        require(success, "Failed to get owner for NUSDC");
        address ownerNUSDC = abi.decode(result, (address));
        vm.prank(ownerNUSDC);
        (success, ) = NUSDC.call(setTrustedOperatorCalldata);
        require(success, "Failed to set trusted operator for NUSDC");   
    }

    modifier user(address _user) {
        vm.startPrank(_user);
        console2.log("User:", _user);
        _;
        vm.stopPrank();
    }

    struct SwapInfo {
        uint256 orderId;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_nativeV3_swapWETH2USDC_adapter() public {
        uint256 amount = 1 * 10 ** 15; // 0.001 WETH
        deal(WETH, address(this), amount);
        console2.log("WETH balance before:", IERC20(WETH).balanceOf(address(this)));
        console2.log("USDC balance before:", IERC20(USDC).balanceOf(address(this)));
        console2.log("NWETH shares before:", INativeLPToken(NWETH).sharesOf(address(this)));
        console2.log("NUSDC shares before:", INativeLPToken(NUSDC).sharesOf(address(this)));
        IERC20(WETH).transfer(address(adapter), amount);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(WETH, USDC, uint24(5000));
        bytes memory moreInfo = abi.encode(sqrtX96, data);
        adapter.sellBase(address(this), NWETH_NUSDC, moreInfo);
        console2.log("WETH balance after:", IERC20(WETH).balanceOf(address(this)));
        console2.log("USDC balance after:", IERC20(USDC).balanceOf(address(this)));
        console2.log("NWETH shares after:", INativeLPToken(NWETH).sharesOf(address(this)));
        console2.log("NUSDC shares after:", INativeLPToken(NUSDC).sharesOf(address(this)));
    }

    function test_nativeV3_swapWETH2USDC_dexRouter() user(arnaud) public {
        uint256 amount = 1 * 10 ** 15; // 0.001 WETH
        deal(WETH, arnaud, amount);
        IERC20(WETH).approve(tokenApprove, amount);

        console2.log("WETH balance before:", IERC20(WETH).balanceOf(address(arnaud)));
        console2.log("USDC balance before:", IERC20(USDC).balanceOf(address(arnaud)));
        console2.log("NWETH shares before:", INativeLPToken(NWETH).sharesOf(address(arnaud)));
        console2.log("NUSDC shares before:", INativeLPToken(NUSDC).sharesOf(address(arnaud)));

        SwapInfo memory swapInfo;
        swapInfo.baseRequest.fromToken = uint256(uint160(address(WETH)));
        swapInfo.baseRequest.toToken = USDC;
        swapInfo.baseRequest.fromTokenAmount = amount;
        swapInfo.baseRequest.minReturnAmount = 0;
        swapInfo.baseRequest.deadLine = block.timestamp;

        swapInfo.batchesAmount = new uint[](1);
        swapInfo.batchesAmount[0] = amount;

        swapInfo.batches = new DexRouter.RouterPath[][](1);
        swapInfo.batches[0] = new DexRouter.RouterPath[](1);
        swapInfo.batches[0][0].mixAdapters = new address[](1);
        swapInfo.batches[0][0].mixAdapters[0] = address(adapter);
        swapInfo.batches[0][0].assetTo = new address[](1);
        // direct interaction with pool
        swapInfo.batches[0][0].assetTo[0] = address(adapter);
        swapInfo.batches[0][0].rawData = new uint[](1);
        swapInfo.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x00), uint88(10000), address(NWETH_NUSDC))));
        swapInfo.batches[0][0].extraData = new bytes[](1);
        uint160 sqrtX96 = 0;
        bytes memory data = abi.encode(WETH, USDC, uint24(5000));
        swapInfo.batches[0][0].extraData[0] = abi.encode(sqrtX96, data);
        swapInfo.batches[0][0].fromToken = uint256(uint160(address(WETH)));

        swapInfo.extraData = new PMMLib.PMMSwapRequest[](0);

        dexRouter.smartSwapByOrderId(
            swapInfo.orderId,
            swapInfo.baseRequest,
            swapInfo.batchesAmount,
            swapInfo.batches,
            swapInfo.extraData
        );

        console2.log("WETH balance after:", IERC20(WETH).balanceOf(address(arnaud)));
        console2.log("USDC balance after:", IERC20(USDC).balanceOf(address(arnaud)));
        console2.log("NWETH shares after:", INativeLPToken(NWETH).sharesOf(address(arnaud)));
        console2.log("NUSDC shares after:", INativeLPToken(NUSDC).sharesOf(address(arnaud)));
    }

}