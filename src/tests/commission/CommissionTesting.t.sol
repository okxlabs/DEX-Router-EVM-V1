// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";
import "@dex/interfaces/IERC20.sol";

interface IApproveProxyTesting {
    function isAllowedProxy(address _proxy) external view returns (bool);

    function claimTokens(
        address token,
        address who,
        address dest,
        uint256 amount
    ) external;

    function tokenApprove() external view returns (address);

    function addProxy(address _newProxy) external;
}

interface IWNativeRelayerTest {
    function setCallerOk(address[] calldata whitelistedCallers, bool isOk) external;
}


contract CommissionTesting is Test {
    address DEXROUTER;
    DexRouter dexrouter;
    uint256 internal constant _REFERRER_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 internal constant _COMMISSION_FEE_MASK = 0x000000ffffffffffffffffff0000000000000000000000000000000000000000;
    uint256 internal constant _COMMISSION_FLAG_MASK = 0xffffff0000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant NO_NEED_COMMISSION = uint256(0);

    address token_approve_proxy = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
    address token_approve = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address wNativeRelater = 0x5703B683c7F928b721CA95Da988d73a3299d4757;
    address shaneson = 0x790ac11183ddE23163b307E3F7440F2460526957;

    address fromToken;
    address toToken;
    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        dexrouter = new DexRouter();
        DEXROUTER = address(dexrouter);

        // admin: 0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87
        vm.startPrank(0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87);
        IApproveProxyTesting(token_approve_proxy).addProxy(DEXROUTER);

        vm.stopPrank();

        vm.startPrank(0xc82Ea2afE1Fd1D61C4A12f5CeB3D7000f564F5C6);
        address[] memory whitelistedCallers = new address[](1);
        whitelistedCallers[0] = DEXROUTER;
        IWNativeRelayerTest(wNativeRelater).setCallerOk(whitelistedCallers, true);
        vm.stopPrank();

    }

    function test_smartSwap() public {
        uint256 gas0 = smartSwapByOrderIdWithCommission();

        setUp();
        uint256 gas1 = smartSwapByOrderIdWithoutCommission();

        console2.log("smartSwap with commission need: %s", gas0 - gas1);
    }

    function test_smartSwapOnNative() public {
        uint256 gas0 = smartSwapByOrderIdWithCommissionOnNative();

        setUp();
        uint256 gas1 = smartSwapByOrderIdWithoutCommissionOnNative();

        console2.log("smartSwap on native with commission need: %s", gas0 - gas1);
    }

    function test_unxswap() public {
        uint256 gas0 = unxswapWithCommission(); 

        setUp();
        uint256 gas1 = unxswapWithoutCommission();

        console2.log("[safemoon token]unxswap with commission need: %s", gas0 - gas1);
    }

    function test_unxswapOnNative() public {
        uint256 gas0 = unxswapWithCommissionOnNative(); 

        setUp();
        uint256 gas1 = unswapWithoutCommissionOnNative();

        console2.log("unxswap on native with commission need: %s", gas0 - gas1);
    }
     function test_unxV3swap() public {
        uint256 gas0 = unxswapV3WithCommission();

        setUp();
        uint256 gas1 = unxswapV3WithoutCommission();

        console2.log("unxV3swap with commission need: %s", gas0 - gas1);
    }

    function test_unxV3swapOnNative() public {
        uint256 gas0 = unswapV3WithCommissionOnNative(); 

        setUp();
        uint256 gas1 = unxswapV3WithoutCommissionOnNative();

        console2.log("unxV3swap on native with commission need: %s", gas0 - gas1);
    }

    function smartSwapByOrderIdWithCommission() public returns(uint256){
        fromToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        toToken = 0xf819d9Cb1c2A819Fd991781A822dE3ca8607c3C9;
        deal(fromToken, address(this),  100000 * 10**6);
        SafeERC20.safeApprove(IERC20(fromToken), token_approve, 100000 * 10**6);

        uint256 before_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 before_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        bytes memory commission_info = hex"3ca20afc2aaa00000000012c790ac11183ddE23163b307E3F7440F2460526957";
        bytes memory data = hex"b80c2f090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000f819d9cb1c2a819fd991781a822de3ca8607c3c900000000000000000000000000000000000000000000000000000000021a1e4d0000000000000000000000000000000000000000000000000002ff8d0a86e6f200000000000000000000000000000000000000000000000000000000f4f853330000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000005c0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000021a1e4d0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000160000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000000000001000000000000000000000000031f1ad10547b8deb43a36e5491c06a93812023a000000000000000000000000000000000000000000000000000000000000000100000000000000000000000006da0fd433c1a5d7a4faa01111c044910a184553000000000000000000000000000000000000000000000000000000000000000180000000000000000000271006da0fd433c1a5d7a4faa01111c044910a184553000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000160000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000001000000000000000000000000031f1ad10547b8deb43a36e5491c06a93812023a00000000000000000000000000000000000000000000000000000000000000010000000000000000000000008dbee21e8586ee356130074aaa789c33159921ca00000000000000000000000000000000000000000000000000000000000000010000000000000000000027108dbee21e8586ee356130074aaa789c33159921ca000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000000";
        data = bytes.concat(data, commission_info);
        
        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call(data);
        uint256 afterGas = gasleft();
        assert(success);

        uint256 returnAmount = uint256(bytes32(b));
 
        uint256 after_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 after_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        assert(after_shaneson_balance == before_shaneson_balance + 1090704 );
        assert(after_owner_balance == before_owner_balance - 35266125 - 1090704 );
        assert(before_owner_toToken_balance + returnAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
        // console2.log("test_smartSwapByOrderIdWithCommission : %s", beforeGas - afterGas);
    }
    function smartSwapByOrderIdWithCommissionOnNative() public returns (uint256){
        toToken = 0x0b0a8c7C34374C1d0C649917a97EeE6c6c929B1b;

        uint256 before_shaneson_balance = payable(shaneson).balance;
        uint256 before_owner_balance = payable(address(this)).balance;
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        bytes memory commission_info = hex"3ca20afc2aaa00000000012c790ac11183ddE23163b307E3F7440F2460526957";
        bytes memory data = hex"b80c2f090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000b0a8c7c34374c1d0c649917a97eee6c6c929b1b0000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000000000000000000000000000000d6d6b3051beabf000000000000000000000000000000000000000000000000000000000f4f9c2760000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000003c000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000de0b6b3a7640000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000160000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000001000000000000000000000000031f1ad10547b8deb43a36e5491c06a93812023a000000000000000000000000000000000000000000000000000000000000000100000000000000000000000099a65698566e757610d5aa2372f6a0c7df92ae9f000000000000000000000000000000000000000000000000000000000000000180000000000000000000271099a65698566e757610d5aa2372f6a0c7df92ae9f000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000000";
        data = bytes.concat(data, commission_info);
        
        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call{value: 1030927835051546391}(data);
        uint256 afterGas = gasleft();
        assert(success);

        uint256 returnAmount = uint256(bytes32(b));
 
        uint256 after_shaneson_balance = payable(shaneson).balance;
        uint256 after_owner_balance = payable(address(this)).balance;
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        assert(after_shaneson_balance == before_shaneson_balance + 30927835051546391 );
        assert(after_owner_balance == before_owner_balance - 1 ether - 30927835051546391);
        assert(before_owner_toToken_balance + returnAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
        // console2.log("test_smartSwapByOrderIdWithCommissionOnNative : %s", beforeGas - afterGas);
    }

    function smartSwapByOrderIdWithoutCommissionOnNative() public returns(uint256){
        toToken = 0x0b0a8c7C34374C1d0C649917a97EeE6c6c929B1b;

        uint256 before_shaneson_balance = payable(shaneson).balance;
        uint256 before_owner_balance = payable(address(this)).balance;
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        bytes memory data = hex"b80c2f090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000b0a8c7c34374c1d0c649917a97eee6c6c929b1b0000000000000000000000000000000000000000000000000de0b6b3a76400000000000000000000000000000000000000000000000000000d6d6b3051beabf000000000000000000000000000000000000000000000000000000000f4f9c2760000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000003c000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000de0b6b3a7640000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000160000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000001000000000000000000000000031f1ad10547b8deb43a36e5491c06a93812023a000000000000000000000000000000000000000000000000000000000000000100000000000000000000000099a65698566e757610d5aa2372f6a0c7df92ae9f000000000000000000000000000000000000000000000000000000000000000180000000000000000000271099a65698566e757610d5aa2372f6a0c7df92ae9f000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000000";
        
        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call{value: 1 ether}(data);
        uint256 afterGas = gasleft();
        assert(success);

        uint256 returnAmount = uint256(bytes32(b));
 
        uint256 after_shaneson_balance = payable(shaneson).balance;
        uint256 after_owner_balance = payable(address(this)).balance;
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        assert(after_shaneson_balance == before_shaneson_balance );
        assert(after_owner_balance == before_owner_balance - 1 ether );
        assert(before_owner_toToken_balance + returnAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
        // console2.log("test_smartSwapByOrderIdWithoutCommissionOnNative : %s", beforeGas - afterGas);
    }

    function smartSwapByOrderIdWithoutCommission() public returns(uint256){
        fromToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        toToken = 0xf819d9Cb1c2A819Fd991781A822dE3ca8607c3C9;

        deal(fromToken, address(this),  100000 * 10**6);
        SafeERC20.safeApprove(IERC20(fromToken), token_approve, 100000 * 10**6);

        uint256 before_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 before_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        bytes memory data = hex"b80c2f090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000f819d9cb1c2a819fd991781a822de3ca8607c3c900000000000000000000000000000000000000000000000000000000021a1e4d0000000000000000000000000000000000000000000000000002ff8d0a86e6f200000000000000000000000000000000000000000000000000000000f4f853330000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000005c0000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000021a1e4d0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000022000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000160000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000000000000000000000000000000001000000000000000000000000031f1ad10547b8deb43a36e5491c06a93812023a000000000000000000000000000000000000000000000000000000000000000100000000000000000000000006da0fd433c1a5d7a4faa01111c044910a184553000000000000000000000000000000000000000000000000000000000000000180000000000000000000271006da0fd433c1a5d7a4faa01111c044910a184553000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000160000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc20000000000000000000000000000000000000000000000000000000000000001000000000000000000000000031f1ad10547b8deb43a36e5491c06a93812023a00000000000000000000000000000000000000000000000000000000000000010000000000000000000000008dbee21e8586ee356130074aaa789c33159921ca00000000000000000000000000000000000000000000000000000000000000010000000000000000000027108dbee21e8586ee356130074aaa789c33159921ca000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000000";
        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call(data);
        uint256 afterGas = gasleft();
        uint256 returnAmount = uint256(bytes32(b));
        assert(success);

        uint256 after_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 after_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        assert(after_shaneson_balance == before_shaneson_balance);
        assert(after_owner_balance == before_owner_balance - 35266125);
        assert(before_owner_toToken_balance + returnAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
        // console2.log("test_smartSwapByOrderIdWithoutCommission: %s",beforeGas - afterGas);
    }

    function unxswapWithCommission() public returns(uint256){
        fromToken = 0x12970E6868f88f6557B76120662c1B3E50A646bf;
        toToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        deal(fromToken, address(this),  (10**18) * 10**18);
        SafeERC20.safeApprove(IERC20(fromToken), token_approve, (10**18) * 10**18);

        uint256 before_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 before_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 before_owner_toToken_balance = payable(this).balance;


        bytes memory commission_info = hex"3ca20afc2aaa00000000012c790ac11183ddE23163b307E3F7440F2460526957";
        bytes memory data = hex"9871efa400000000000000000000000012970e6868f88f6557b76120662c1b3e50a646bf0000000000000000000000000000000000000000005d6521cd60e8a9f1e170a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000140000000000000003b6d0340cbe856765eeec3fdc505ddebf9dc612da995e593";
        data = bytes.concat(data, commission_info);

        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call(data);
        uint256 afterGas = gasleft();
        uint256 returnAmount = uint256(bytes32(b));
        assert(success);

        uint256 after_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 after_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 after_owner_toToken_balance = payable(this).balance;

        assert(after_shaneson_balance == before_shaneson_balance + 3491990220017597071364269 );
        assert(after_owner_balance == before_owner_balance - 0x005d6521cd60e8a9f1e170a0 - 3491990220017597071364269 );
        assert(before_owner_toToken_balance + returnAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
        // console2.log("test_unxswapWithoutCommission: %s",beforeGas - afterGas);
    }

    function unxswapWithoutCommission() public returns(uint256){
        fromToken = 0x12970E6868f88f6557B76120662c1B3E50A646bf;
        deal(fromToken, address(this),  (10**18) * 10**18);
        SafeERC20.safeApprove(IERC20(fromToken), token_approve, (10**18) * 10**18);

        uint256 before_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 before_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 before_owner_toToken_balance = payable(this).balance;
        

        bytes memory data = hex"9871efa400000000000000000000000012970e6868f88f6557b76120662c1b3e50a646bf0000000000000000000000000000000000000000005d6521cd60e8a9f1e170a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000140000000000000003b6d0340cbe856765eeec3fdc505ddebf9dc612da995e593";

        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call(data);
        uint256 afterGas = gasleft();
        uint256 returnAmount = uint256(bytes32(b));
        assert(success);

        uint256 after_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 after_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 after_owner_toToken_balance = payable(this).balance;

        assert(after_shaneson_balance == before_shaneson_balance );
        assert(after_owner_balance == before_owner_balance - 0x005d6521cd60e8a9f1e170a0);
        assert(before_owner_toToken_balance + returnAmount == after_owner_toToken_balance);
        
        return beforeGas - afterGas;
        // console2.log("test_unxswapWithoutCommission: %s",beforeGas - afterGas);
    }

    function unxswapWithCommissionOnNative() public returns(uint256){
        toToken = 0x94Be6962be41377d5BedA8dFe1b100F3BF0eaCf3;

        uint256 before_shaneson_balance = payable(shaneson).balance;
        uint256 before_owner_balance = payable(address(this)).balance;
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        bytes memory commission_info = hex"3ca20afc2aaa00000000012c790ac11183ddE23163b307E3F7440F2460526957";
        bytes memory data = hex"9871efa4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010a2427226c31f8000000000000000000000000000000000000000000000000657a6c71a44af66f40000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000180000000000000003b6d0340ef9ef6e07602e1e0419a5788f1d85e0698eab077";
        data = bytes.concat(data, commission_info);

        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call{value: 0x10a2427226c31f80 + 37069902336432989}(data);
        uint256 afterGas = gasleft();
        assert(success);

        uint256 returnAmount = uint256(bytes32(b));
 
        uint256 after_shaneson_balance = payable(shaneson).balance;
        uint256 after_owner_balance = payable(address(this)).balance;
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        assert(after_shaneson_balance == before_shaneson_balance + 37069902336432989 );
        assert(after_owner_balance == before_owner_balance - 0x10a2427226c31f80  - 37069902336432989 );
        assert(before_owner_toToken_balance + returnAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
        // console2.log("test_unxswapWithCommissionOnNative : %s", beforeGas - afterGas);
    }

    function unswapWithoutCommissionOnNative() public returns(uint256){
        toToken = 0x94Be6962be41377d5BedA8dFe1b100F3BF0eaCf3;

        uint256 before_shaneson_balance = payable(shaneson).balance;
        uint256 before_owner_balance = payable(address(this)).balance;
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        bytes memory data = hex"9871efa4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010a2427226c31f8000000000000000000000000000000000000000000000000657a6c71a44af66f40000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000180000000000000003b6d0340ef9ef6e07602e1e0419a5788f1d85e0698eab077";
        
        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call{value: 0x10a2427226c31f80}(data);
        uint256 afterGas = gasleft();
        assert(success);

        uint256 returnAmount = uint256(bytes32(b));
 
        uint256 after_shaneson_balance = payable(shaneson).balance;
        uint256 after_owner_balance = payable(address(this)).balance;
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        assert(after_shaneson_balance == before_shaneson_balance );
        assert(after_owner_balance == before_owner_balance - 0x10a2427226c31f80 );
        assert(before_owner_toToken_balance + returnAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
        // console2.log("test_unswapWithoutCommissionOnNative : %s", beforeGas - afterGas);
    }

    function unxswapV3WithCommission() public returns (uint256){
        fromToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        toToken = 0x78a0A62Fba6Fb21A83FE8a3433d44C73a4017A6f;  
        deal(fromToken, address(this),  10000 * 10**6);
        SafeERC20.safeApprove(IERC20(fromToken), token_approve, 10000 * 10**6);

        uint256 before_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 before_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(0xeCa6E88e6c0988eA622E1B3df72C8Fe5693b1626);

        bytes memory commission_info = hex"3ca20afc2aaa00000000012c790ac11183ddE23163b307E3F7440F2460526957";
        bytes memory data = hex"0d5f0e3b000000000000000000000000eca6e88e6c0988ea622e1b3df72c8fe5693b162600000000000000000000000000000000000000000000000000000000dc38ea650000000000000000000000000000000000000000000000064ba929665d69e3be0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000280000000000000000000000011b815efb8f581194ae79006d24e0d814b7697f68000000000000000000000002cad29e9640b9bcfb1d8d25cf3e4bd05f55cce70";
        data = bytes.concat(data, commission_info);

        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call(data);
        uint256 afterGas = gasleft();
        uint256 returnAmount = uint256(bytes32(b));
        assert(success);

        uint256 after_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 after_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(0xeCa6E88e6c0988eA622E1B3df72C8Fe5693b1626);
        assert(after_shaneson_balance == before_shaneson_balance + 114269614 );
        assert(after_owner_balance == before_owner_balance - 0xdc38ea65 - 114269614 );
        assert(before_owner_toToken_balance + returnAmount == after_owner_toToken_balance);

        return (beforeGas - afterGas);
        // console2.log("test_unxswapV3WithCommission: %s",beforeGas - afterGas);
    }

    function unxswapV3WithoutCommission() public returns(uint256){
        fromToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        toToken = 0x78a0A62Fba6Fb21A83FE8a3433d44C73a4017A6f;  
        deal(fromToken, address(this),  10000 * 10**6);
        SafeERC20.safeApprove(IERC20(fromToken), token_approve, 10000 * 10**6);

        uint256 before_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 before_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(0xeCa6E88e6c0988eA622E1B3df72C8Fe5693b1626);

        bytes memory data = hex"0d5f0e3b000000000000000000000000eca6e88e6c0988ea622e1b3df72c8fe5693b162600000000000000000000000000000000000000000000000000000000dc38ea650000000000000000000000000000000000000000000000064ba929665d69e3be0000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000280000000000000000000000011b815efb8f581194ae79006d24e0d814b7697f68000000000000000000000002cad29e9640b9bcfb1d8d25cf3e4bd05f55cce70";

        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call(data);
        uint256 afterGas = gasleft();
        uint256 returnAmount = uint256(bytes32(b));
        assert(success);

        uint256 after_shaneson_balance = IERC20(fromToken).balanceOf(shaneson);
        uint256 after_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(0xeCa6E88e6c0988eA622E1B3df72C8Fe5693b1626);
        assert(after_shaneson_balance == before_shaneson_balance );
        assert(after_owner_balance == before_owner_balance - 0xdc38ea65 );
        assert(before_owner_toToken_balance + returnAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
        // console2.log("test_unxswapV3WithoutCommission: %s",beforeGas - afterGas);
    }

    function unxswapV3WithoutCommissionOnNative() public returns(uint256){
        toToken = 0xebB82c932759B515B2efc1CfBB6BF2F6dbaCe404;

        uint256 before_shaneson_balance = payable(shaneson).balance;
        uint256 before_owner_balance = payable(address(this)).balance;
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(0x785719D8B4a59efD6c8D9586d3a87e75ba6858Cb);

        bytes memory data = hex"0d5f0e3b000000000000000000000000785719d8b4a59efd6c8d9586d3a87e75ba6858cb00000000000000000000000000000000000000000000000006f05b59d3b200000000000000000000000000000000000000000000000000000081061c5fd6352a000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000010000000000000000000000004c52d01fb85b36cccf1647b99fb7b20f70fe669c";
        
        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call{value: 0x06f05b59d3b20000}(data);
        uint256 afterGas = gasleft();
        assert(success);

        uint256 returnAmount = uint256(bytes32(b));
 
        uint256 after_shaneson_balance = payable(shaneson).balance;
        uint256 after_owner_balance = payable(address(this)).balance;
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(0x785719D8B4a59efD6c8D9586d3a87e75ba6858Cb);

        assert(after_shaneson_balance == before_shaneson_balance );
        assert(after_owner_balance == before_owner_balance - 0x06f05b59d3b20000 );
        assert(before_owner_toToken_balance + returnAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;

        // console2.log("unxswapV3WithoutCommissionOnNative : %s", beforeGas - afterGas);
    }

    function unswapV3WithCommissionOnNative() public returns(uint256){
        toToken = 0xebB82c932759B515B2efc1CfBB6BF2F6dbaCe404;

        uint256 before_shaneson_balance = payable(shaneson).balance;
        uint256 before_owner_balance = payable(address(this)).balance;
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(0x785719D8B4a59efD6c8D9586d3a87e75ba6858Cb);

        bytes memory commission_info = hex"3ca20afc2aaa00000000012c790ac11183ddE23163b307E3F7440F2460526957";
        bytes memory data = hex"0d5f0e3b000000000000000000000000785719d8b4a59efd6c8d9586d3a87e75ba6858cb00000000000000000000000000000000000000000000000006f05b59d3b200000000000000000000000000000000000000000000000000000081061c5fd6352a000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000010000000000000000000000004c52d01fb85b36cccf1647b99fb7b20f70fe669c";
        data = bytes.concat(data, commission_info);

        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call{value: 0x06f05b59d3b20000 + 15463917525773195}(data);
        uint256 afterGas = gasleft();
        assert(success);

        uint256 returnAmount = uint256(bytes32(b));
 
        uint256 after_shaneson_balance = payable(shaneson).balance;
        uint256 after_owner_balance = payable(address(this)).balance;
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(0x785719D8B4a59efD6c8D9586d3a87e75ba6858Cb);

        assert(after_shaneson_balance == before_shaneson_balance + 15463917525773195 );
        assert(after_owner_balance == before_owner_balance - 0x06f05b59d3b20000 - 15463917525773195);
        assert(before_owner_toToken_balance + returnAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
    }


    function test_unswapV3WithCommissionOnNative_refund() public returns(uint256){
        toToken = 0xebB82c932759B515B2efc1CfBB6BF2F6dbaCe404;

        uint256 before_shaneson_balance = payable(shaneson).balance;
        uint256 before_owner_balance = payable(address(this)).balance;
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(0x785719D8B4a59efD6c8D9586d3a87e75ba6858Cb);

        bytes memory commission_info = hex"3ca20afc2aaa00000000012c790ac11183ddE23163b307E3F7440F2460526957";
        bytes memory data = hex"0d5f0e3b000000000000000000000000785719d8b4a59efd6c8d9586d3a87e75ba6858cb00000000000000000000000000000000000000000000000006f05b59d3b200000000000000000000000000000000000000000000000000000081061c5fd6352a000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000010000000000000000000000004c52d01fb85b36cccf1647b99fb7b20f70fe669c";
        data = bytes.concat(data, commission_info);

        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call{value: 0x06f05b59d3b20000 + 15463917525773195 + 2 ether}(data);
        uint256 afterGas = gasleft();
        assert(success);

        uint256 returnAmount = uint256(bytes32(b));
 
        uint256 after_shaneson_balance = payable(shaneson).balance;
        uint256 after_owner_balance = payable(address(this)).balance;
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(0x785719D8B4a59efD6c8D9586d3a87e75ba6858Cb);

        assert(address(DEXROUTER).balance == 0);
        assert(after_shaneson_balance == before_shaneson_balance + 15463917525773195 );
        assert(after_owner_balance == before_owner_balance - 0x06f05b59d3b20000 - 15463917525773195);
        assert(before_owner_toToken_balance + returnAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
    }


    receive() external payable {
    }
}