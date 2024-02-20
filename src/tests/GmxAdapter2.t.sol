// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/GmxAdapter2.sol";
import "@dex/DexRouter.sol";

contract GmxAdapter2Test is Test {
    GmxAdapter2 adapter;

    address xbridge = 0xf956D9FA19656D8e5219fd6fa8bA6cb198094138;
    DexRouter dexRouter = DexRouter(payable(0x1daC23e41Fc8ce857E86fD8C1AE5b6121C67D96d));
    address APPROVE_PROXY = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address vault = 0x9ab2De34A33fB459b538c43f251eB825645e8595;
    address USDC_e = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address USDC = 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E;

    address alice = vm.rememberKey(1);
    address bob = vm.rememberKey(2);

    function setUp() public {
        vm.createSelectFork(vm.envString("AVAX_RPC_URL"), 41269697);
        adapter = new GmxAdapter2();
    }

    struct SmartSwapInfo {
        uint256 orderId;
        address receiver;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    modifier payer(address _user, address _token, uint256 _amount) {
        vm.startPrank(_user);
        deal(_token, _user, _amount);
        IERC20(_token).approve(APPROVE_PROXY, _amount);
        console2.log("%s user: Alice amount: %d", IERC20(_token).symbol(), IERC20(_token).balanceOf(_user));
        _;
        console2.log("%s user: Alice amount: %d", IERC20(_token).symbol(), IERC20(_token).balanceOf(_user));

        vm.stopPrank();
    }

    modifier receiver(address _user, address _token) {
        console2.log("%s user: Bob   amount: %d", IERC20(_token).symbol(), IERC20(_token).balanceOf(_user));
        _;
        console2.log("%s user: Bob   amount: %d", IERC20(_token).symbol(), IERC20(_token).balanceOf(_user));
    }

    function test_smartswapTo() public payer(alice, WAVAX, 1 ether) receiver(bob, USDC) {
        SmartSwapInfo memory info;
        info.orderId = 0;
        info.receiver = bob;
        info.baseRequest.fromToken = uint256(uint160(WAVAX));
        info.baseRequest.toToken = USDC;
        info.baseRequest.fromTokenAmount = 1 ether;
        info.baseRequest.minReturnAmount = 0;
        info.baseRequest.deadLine = block.timestamp;
        info.batchesAmount = new uint256[](1);
        info.batchesAmount[0] = 1 ether;
        info.batches = new DexRouter.RouterPath[][](1);
        info.batches[0] = new DexRouter.RouterPath[](2);
        info.batches[0][0].mixAdapters = new address[](1);
        info.batches[0][0].mixAdapters[0] = address(adapter);
        info.batches[0][0].assetTo = new address[](1);
        info.batches[0][0].assetTo[0] = address(adapter);
        info.batches[0][0].rawData = new uint256[](1);
        info.batches[0][0].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(vault))));
        info.batches[0][0].extraData = new bytes[](1);
        info.batches[0][0].extraData[0] = abi.encode(WAVAX, USDC_e);
        info.batches[0][0].fromToken = uint256(uint160(WAVAX));

        info.batches[0][1].mixAdapters = new address[](1);
        info.batches[0][1].mixAdapters[0] = address(adapter);
        info.batches[0][1].assetTo = new address[](1);
        info.batches[0][1].assetTo[0] = address(adapter);
        info.batches[0][1].rawData = new uint256[](1);
        info.batches[0][1].rawData[0] = uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(vault))));
        info.batches[0][1].extraData = new bytes[](1);
        info.batches[0][1].extraData[0] = abi.encode(USDC_e, USDC);
        info.batches[0][1].fromToken = uint256(uint160(USDC_e));

        info.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapTo(
            info.orderId, info.receiver, info.baseRequest, info.batchesAmount, info.batches, info.extraData
        );
    }
}
