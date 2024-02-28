pragma solidity 0.8.17;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/adapter/HermesAdapter.sol";
import "@dex/interfaces/IUnswapRouter02.sol";
import "@dex/interfaces/IUni.sol";
import "@dex/interfaces/IUniswapV2Factory.sol";
contract HermesAdapterTest is Test {
    address ETH = 0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000;
    address WETH = 0x75cb093E4D61d2A2e65D8e0BBb01DE8d89b53481;
    address USDC = 0xEA32A96608495e54156Ae48931A7c20f0dcc1a21;
    address WORK = 0x2b64BA93f149F7CbA926E84DEFF9A40A7807290C;
    DexRouter dexRouter = DexRouter(payable(0x6b2C0c7be2048Daa9b5527982C29f48062B34D58));
    address tokenApprove = 0x57df6092665eb6058DE53939612413ff4B09114E;
    address alice = vm.rememberKey(1);
    address bob = vm.rememberKey(2);
    HermesAdapter adapter;

    function setUp() public {
        vm.createSelectFork("https://andromeda.metis.io/?owner=1088");
        adapter = new HermesAdapter();
    }
    modifier payer(address _user, address _token, uint256 _amount) {
        vm.startPrank(_user);
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
    struct SmartSwapInfo {
        uint256 orderId;
        address receiver;
        DexRouter.BaseRequest baseRequest;
        uint256[] batchesAmount;
        DexRouter.RouterPath[][] batches;
        PMMLib.PMMSwapRequest[] extraData;
    }

    function test_smartswapTo() public payer(alice, ETH, 1 ether) receiver(bob, WORK) {
        address ETH_TOKEN_POOL = 0x060705bC5E45Cec82d207e82b2a363218b4A907c;
        vm.deal(alice, 1 ether);
        deal(ETH, address(adapter), 1 ether);
        SmartSwapInfo memory info;
        info.orderId = 0;
        info.receiver = bob;
        info.baseRequest.fromToken = uint256(uint160(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE));
        info.baseRequest.toToken = USDC;
        info.baseRequest.fromTokenAmount = 1 ether;
        info.baseRequest.minReturnAmount = 0;
        info.baseRequest.deadLine = block.timestamp;
        info.batchesAmount = new uint[](1);
        info.batchesAmount[0] = 1 ether;
        info.batches = new DexRouter.RouterPath[][](1);
        info.batches[0] = new DexRouter.RouterPath[](1);
        info.batches[0][0].mixAdapters = new address[](1);
        info.batches[0][0].mixAdapters[0] = address(adapter);
        info.batches[0][0].assetTo = new address[](1);
        info.batches[0][0].assetTo[0] = address(adapter);
        info.batches[0][0].rawData = new uint[](1);
        info.batches[0][0].rawData[0] =
            uint256(bytes32(abi.encodePacked(uint8(0x80), uint88(10000), address(ETH_TOKEN_POOL))));
        info.batches[0][0].extraData = new bytes[](1);
        info.batches[0][0].extraData[0] = abi.encode(30);
        info.batches[0][0].fromToken = uint256(uint160(WETH));
        info.extraData = new PMMLib.PMMSwapRequest[](0);
        dexRouter.smartSwapTo{value: 1 ether}(
            info.orderId, info.receiver, info.baseRequest, info.batchesAmount, info.batches, info.extraData
        );
    }


}