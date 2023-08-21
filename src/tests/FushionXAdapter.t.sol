pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import {TokenApproveProxy} from "@dex/TokenApproveProxy.sol";
import {TokenApprove} from "@dex/TokenApprove.sol";
import {DexRouter, PMMLib} from "@dex/DexRouter.sol";
import {WNativeRelayer} from "@dex/utils/WNativeRelayer.sol";

import {FushionXAdapter, IERC20} from "@dex/adapter/FushionXAdapter.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract FushionXAdapterTest is Test {
    TokenApprove public tokenApprove;
    TokenApproveProxy public tokenApproveProxy;
    DexRouter public dexRouter;
    FushionXAdapter public adapter;
    WNativeRelayer public wNativeRelayer;
    address proxyAdmin = 0x358506b4C5c441873AdE429c5A2BE777578E2C6f;
    address payable WMNT = payable(0x78c1b0C915c4FAA5FffA6CAbf0219DA63d7f4cb8);
    address USDT = 0x201EBa5CC46D216Ce6DC03F6a759e8E766e956aE; //x
    address WETH = 0xdEAddEaDdeadDEadDEADDEAddEADDEAddead1111; //y
    address factoryDeployer = 0x8790c2C3BA67223D83C8FCF2a5E3C650059987b4;
    address WMNT_USDT = 0x262255F4770aEbE2D0C8b97a46287dCeCc2a0AfF;
    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp0() public {
        vm.createSelectFork(vm.envString("MANTLE_RPC_URL"), 29178);

        address tokenApproveProxyImpl = address(new TokenApproveProxy());
        tokenApproveProxy = TokenApproveProxy(
            address(
                new TransparentUpgradeableProxy(tokenApproveProxyImpl, proxyAdmin, abi.encodeWithSelector(DexRouter.initialize.selector ))
            )
        );

        address tokenApproveImpl = address(new TokenApprove());
        tokenApprove = TokenApprove(
            address(
                new TransparentUpgradeableProxy(tokenApproveImpl, proxyAdmin, abi.encodeWithSelector(TokenApprove.initialize.selector, address(tokenApproveProxy)))
            )
        );

        address dexRouterImpl = address(new DexRouter());
        dexRouter = DexRouter(
            payable(
                address(
                    new TransparentUpgradeableProxy(dexRouterImpl, proxyAdmin, abi.encodeWithSelector(DexRouter.initialize.selector ))
                )
            )
        );

        address wNativeRelayerImpl = address(new WNativeRelayer());
        wNativeRelayer = WNativeRelayer(
            payable(
                address(
                    new TransparentUpgradeableProxy(wNativeRelayerImpl, proxyAdmin, abi.encodeWithSelector(WNativeRelayer.initialize.selector, WMNT
                    ))
                )
            )
        );
        address[] memory whitelistedCallers = new address[](1);
        whitelistedCallers[0] = address(dexRouter);
        wNativeRelayer.setCallerOk(whitelistedCallers, true);

        tokenApproveProxy.setTokenApprove(address(tokenApprove));
        tokenApproveProxy.addProxy(address(dexRouter));

        // dexRouter.setApproveProxy(address(tokenApproveProxy));
        // dexRouter.setWNativeRelayer(address(wNativeRelayer));
    }
    // https://explorer.mantle.xyz/tx/0x49d2fba5f0a3d2496ae39be81340df70744285132b18d3e6112dc8b3928dffd3

    function setUp() public {
        setUp0();
        adapter = new FushionXAdapter(WMNT, factoryDeployer);
        deal(USDT, address(this), 100 * 10 ** 6);
        deal(WMNT, address(this), 1 ether);
    }

    function test_1() public {
        USDT.call(abi.encodeWithSignature("transfer(address,uint256)", address(adapter), 100 * 10 ** 6));
        adapter.sellBase(address(this), WMNT_USDT, abi.encode(0, abi.encode(USDT, WMNT, uint24(500))));
        console2.log("WMNT amount", IERC20(WMNT).balanceOf(address(this)) - 1 ether);
    }

    function test_0() public {
        WMNT.call(abi.encodeWithSignature("transfer(address,uint256)", address(adapter), 1 ether));
        adapter.sellBase(address(this), WMNT_USDT, abi.encode(0, abi.encode(WMNT, USDT, uint24(500))));
        console2.log("USDT amount", IERC20(USDT).balanceOf(address(this)) - 100 * 10 ** 6);
    }

    function test_1_integrate() public {
        DexRouter.BaseRequest memory baseRequest =
            DexRouter.BaseRequest(uint160(USDT), WMNT, 100 * 10 ** 6, 0, block.timestamp);
        uint256[] memory batchesAmount = new uint[](1);
        batchesAmount[0] = 100 * 10 ** 6;
        DexRouter.RouterPath[][] memory batches = new DexRouter.RouterPath[][](1);
        batches[0] = new DexRouter.RouterPath[](1);
        address[] memory mixAdapters = new address[](1);
        mixAdapters[0] = address(adapter);
        address[] memory assetTo = new address[](1);
        assetTo[0] = address(adapter);
        uint256[] memory rawData = new uint256[](1);
        rawData[0] = getRawData(false, 10000, address(WMNT_USDT));
        bytes[] memory extraData = new bytes[](1);
        extraData[0] = abi.encode(0, abi.encode(USDT, WMNT, uint24(500)));
        batches[0][0] = DexRouter.RouterPath({
            mixAdapters: mixAdapters,
            assetTo: assetTo,
            rawData: rawData,
            extraData: extraData,
            fromToken: getFromTokenBatch(USDT, false, false, 0, 0)
        });
        PMMLib.PMMSwapRequest[] memory lib = new PMMLib.PMMSwapRequest[](0);
        USDT.call(abi.encodeWithSignature("approve(address,uint256)", address(tokenApprove), type(uint256).max));
        dexRouter.smartSwapByOrderId(uint256(0), baseRequest, batchesAmount, batches, lib);
        console2.log("WMNT amount", IERC20(WMNT).balanceOf(address(this)) - 1 ether);
    }

    function getFromTokenBatch(address token, bool useBatch, bool useHop, uint256 batchIndex, uint256 hopIndex)
        internal
        returns (uint256)
    {
        uint256 res;
        bytes1 firstByte = bytes1(0);
        bytes1 secondByte = bytes1(0);
        bytes1 thridByte = bytes1(0);
        if (useBatch) {
            if (useHop) {
                firstByte = bytes1(0xC0); //0b1100_0000
            } else {
                firstByte = bytes1(0x80); //0b1000_0000
            }
        } else if (useHop) {
            firstByte = bytes1(0x40); //0b0100_0000
        } else {
            firstByte = bytes1(0x00); //0b0000_0000
        }
        if (useBatch) {
            secondByte = bytes1(uint8(batchIndex));
        }
        if (useHop) {
            thridByte = bytes1(uint8(hopIndex));
        }

        assembly {
            firstByte := shr(mul(0, 8), firstByte)
            secondByte := shr(mul(1, 8), secondByte)
            thridByte := shr(mul(2, 8), thridByte)
            let last := token
            res := add(firstByte, add(secondByte, add(thridByte, last)))
        }

        return res;
    }

    function getRawData(bool reverse, uint256 _weight, address addr) internal returns (uint256) {
        uint256 res;
        bytes1 firstByte = bytes1(0x00);
        if (reverse) {
            firstByte = bytes1(0x80); //0b1000_0000
        }
        bytes2 weight = bytes2(uint16(_weight));
        uint256 shift = 10;
        assembly {
            weight := shr(mul(shift, 8), weight)
            res := add(firstByte, add(weight, addr))
        }
        return res;
    }
}
