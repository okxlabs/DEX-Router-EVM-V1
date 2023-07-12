pragma solidity 0.8.17;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {DexRouter, IERC20} from "@dex/DexRouter.sol";

interface IApproveProxy {
    function isAllowedProxy(address _proxy) external view returns (bool);
    function claimTokens(address token, address who, address dest, uint256 amount) external;
    function tokenApprove() external view returns (address);
    function owner() external view returns (address);
    function addProxy(address _newProxy) external;
    function setCallerOk(address[] memory callers, bool ok) external;
}

interface IDai {
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract uniV3Test is Test {
    event OrderRecord(address fromToken, address toToken, address sender, uint256 fromAmount, uint256 returnAmount);

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address approveImpl = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;

    DexRouter router;

    address approveProxy = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
    address wNativeRelayer = 0x5703B683c7F928b721CA95Da988d73a3299d4757;
    address owner = 0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87;
    address admin = vm.rememberKey(123);

    function setUp() public {
        // vm.createSelectFork(
        //     vm.envString("ETH_RPC_URL"), bytes32(0xe7a27ded0129b70621f5e092d46a129f4824ec706f31b5141338360a7de02a5a)
        // );
        vm.createSelectFork(
            vm.envString("ETH_RPC_URL"), bytes32(0xfd19fa6c6d3a6f6551eee15105e8100c1d42925b04a8f93b2ea2e0977a213514)
        );
        address impl = address(new DexRouter());
        router = DexRouter(
            payable(
                address(
                    new TransparentUpgradeableProxy(impl, address(admin), abi.encodeWithSelector(DexRouter.initialize.selector))
                )
            )
        );
        router.setApproveProxy(approveProxy);
        router.setWNativeRelayer(wNativeRelayer);
        console2.log("owner", IApproveProxy(approveProxy).owner());
        vm.prank(owner);
        IApproveProxy(approveProxy).addProxy(address(router));
        vm.prank(0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6);
        address[] memory callers = new address[](1);
        callers[0] = address(router);
        IApproveProxy(wNativeRelayer).setCallerOk(callers, true);
    }

    function test_wrapETH() public {
        address token = 0xB22C05CeDbF879a661fcc566B5a759d005Cf7b4C;
        address pool = 0x6d1F6AAc7c375b66d87026Aea2D3E04d760e624d;
        address user = 0x3B80D6d859BEe0F8Dbcaf4124D08F4f2d0172f11;
        vm.deal(user, 1 ether);
        vm.startPrank(user, user);
        uint256 recipient = uint160(address(this));
        uint256 amount = 0.7 ether;
        uint256 minReturn = 13561638866160792692942;
        uint256[] memory pools = new uint256[](1);
        pools[0] = uint256(uint160(address(pool))) | (1 << 255);
        vm.expectEmit(true, false, false, true);
        emit OrderRecord(ETH, token, user, amount, 28740849564730167095322);
        uint256 amountRes = router.uniswapV3SwapTo{value: 0.7 ether}(recipient, amount, minReturn, pools);
        require(amountRes == 28740849564730167095322, "must be");
    }

    function test_unwrapWeth() public {
        address token = 0x2eCBa91da63C29EA80Fbe7b52632CA2d1F8e5Be0;
        address pool = 0x30E08eF9A9625a6d3dC25F7F0bf4DA2d80b5Db60;
        address user = 0xC4e226e5C22E5DCfe18851b4a7798BF5e2C8ac81;
        vm.startPrank(user, user);
        uint256 recipient = uint160(address(this));
        uint256 amount = 4000000000000000000000;
        uint256 minReturn = 87314763908949911;
        uint256[] memory pools = new uint256[](1);
        pools[0] = uint256(uint160(address(pool))) | (1 << 253);

        vm.expectEmit(true, false, false, true);
        emit OrderRecord(token, ETH, user, amount, 91910277798894645);
        uint256 amountRes = router.uniswapV3SwapTo(recipient, amount, minReturn, pools);
        console2.log(amountRes);
    }

    function test_hop2() public {
        address token = 0x2eCBa91da63C29EA80Fbe7b52632CA2d1F8e5Be0;
        address pool = 0x30E08eF9A9625a6d3dC25F7F0bf4DA2d80b5Db60; // token_WETH
        address pool2 = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640; //WETH_USDC
        address user = 0xC4e226e5C22E5DCfe18851b4a7798BF5e2C8ac81;
        vm.startPrank(user, user);
        uint256 recipient = uint160(address(this));
        uint256 amount = 4000000000000000000000;
        uint256 minReturn = 1;
        uint256[] memory pools = new uint256[](2);
        pools[0] = uint256(uint160(address(pool)));
        pools[1] = uint256(uint160(address(pool2))) | (1 << 255);

        vm.expectEmit(true, false, false, true);
        emit OrderRecord(token, USDC, user, amount, 170431085);
        uint256 amountRes = router.uniswapV3SwapTo(recipient, amount, minReturn, pools);
        console2.log(amountRes);
    }

    function test_permit() public {
        address user1 = vm.rememberKey(1);
        address DAI_WETH = 0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8;

        deal(DAI, user1, 100 ether);
        // Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                bytes32(0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)"),
                        user1,
                        approveImpl,
                        1,
                        block.timestamp + 1 days,
                        true
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        uint256[] memory pools = new uint256[](1);
        pools[0] = uint256(uint160(address(DAI_WETH)));
        bytes memory signedData = abi.encode(user1, approveImpl, 1, block.timestamp + 1 days, true, v, r, s);
        console2.log("dai balance", IERC20(DAI).balanceOf(user1));
        vm.startPrank(user1, user1);
        vm.expectEmit(true, false, false, true);

        emit OrderRecord(DAI, WETH, user1, 100 ether, 53594806425093043);
        uint256 amountRes =
            router.uniswapV3SwapToWithPermit(uint160(user1), IERC20(DAI), 100 ether, 1, pools, signedData);
        console2.log(amountRes);
    }

    function test_minReturn() public {
        address token = 0x2eCBa91da63C29EA80Fbe7b52632CA2d1F8e5Be0;
        address pool = 0x30E08eF9A9625a6d3dC25F7F0bf4DA2d80b5Db60; // token_WETH
        address pool2 = 0x88e6A0c2dDD26FEEb64F039a2c41296FcB3f5640; //WETH_USDC
        address user = 0xC4e226e5C22E5DCfe18851b4a7798BF5e2C8ac81;
        vm.startPrank(user, user);
        uint256 recipient = uint160(address(this));
        uint256 amount = 4000000000000000000000;
        uint256 minReturn = type(uint256).max;
        uint256[] memory pools = new uint256[](2);
        pools[0] = uint256(uint160(address(pool)));
        pools[1] = uint256(uint160(address(pool2))) | (1 << 255);

        vm.expectRevert(bytes("Min return not reached"));
        uint256 amountRes = router.uniswapV3SwapTo(recipient, amount, minReturn, pools);
    }

    function test_swapCallback() public {
        vm.expectRevert(bytes4(keccak256("BadPool()")));
        router.uniswapV3SwapCallback(-1, -1, abi.encode(address(this)));
    }

    function token0() public view returns (address) {
        return address(this);
    }

    function token1() public view returns (address) {
        return address(this);
    }

    function fee() public view returns (uint256) {
        return 0;
    }

    function test_invalidMsgValue() public {
        address token = 0xB22C05CeDbF879a661fcc566B5a759d005Cf7b4C;
        address pool = 0x6d1F6AAc7c375b66d87026Aea2D3E04d760e624d;
        address user = 0x3B80D6d859BEe0F8Dbcaf4124D08F4f2d0172f11;
        vm.deal(user, 1 ether);
        vm.startPrank(user, user);
        uint256 recipient = uint160(address(this));
        uint256 amount = 0.7 ether;
        uint256 minReturn = 13561638866160792692942;
        uint256[] memory pools = new uint256[](1);
        pools[0] = uint256(uint160(address(pool))) | (1 << 255);
        vm.expectRevert(bytes4(keccak256("InvalidMsgValue()")));
        uint256 amountRes = router.uniswapV3SwapTo{value: 0.01 ether}(recipient, amount, minReturn, pools);
    }

    receive() external payable {}
}
