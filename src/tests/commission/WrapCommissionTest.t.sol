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
    
    function owner() external view returns (address);
}

interface IWNativeRelayerTest {
    function setCallerOk(address[] calldata whitelistedCallers, bool isOk) external;
    function owner() external view returns (address);
}


contract SwapWrapCommissionTesting is Test {
    address DEXROUTER;
    DexRouter dexrouter;
    uint256 internal constant _REFERRER_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 internal constant _COMMISSION_FEE_MASK = 0x000000000000ffffffffffff0000000000000000000000000000000000000000;
    uint256 internal constant _COMMISSION_FLAG_MASK = 0xffffffffffff0000000000000000000000000000000000000000000000000000;
    uint256 internal constant NO_NEED_COMMISSION = uint256(0);

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    //swap 0.1 eth/weth
    bytes internal constant ETHtoWETHdata = hex"01617fab00000000000000000000000000000000000000000000000000328ac852ca8f00000000000000000000000000000000000000000000000000016345785D8A0000";
    bytes internal constant WETHtoETHdata = hex"01617fab00000000000000000000000000000000000000000000000000328acc104b9000800000000000000000000000000000000000000000000000016345785D8A0000";
    uint256 internal constant SwapAmount = 0.1 ether;

    address token_approve_proxy = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
    address token_approve = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address wNativeRelater = 0x5703B683c7F928b721CA95Da988d73a3299d4757;
    address referrer = 0x790ac11183ddE23163b307E3F7440F2460526957;
    //address referrer = 0x790ac11183ddE23163b307E3F7440F2460526957;

    address fromToken;
    address toToken;
    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        dexrouter = new DexRouter();
        DEXROUTER = address(dexrouter);

        deal(address(this), 1 ether);
        deal(WETH, address(this), 1 ether);

        vm.startPrank(referrer);
        IERC20(WETH).approve(token_approve, 1 ether);
        vm.stopPrank();

        address approveProxyAdmin = IApproveProxyTesting(token_approve_proxy).owner();
        // admin: 0x06C95a3934d94d5ae5bf54731bD2840ceFee6F87
        vm.startPrank(approveProxyAdmin);
        IApproveProxyTesting(token_approve_proxy).addProxy(DEXROUTER);
        vm.stopPrank();

        address wNativeRelaterAdmin = IWNativeRelayerTest(wNativeRelater).owner();
        vm.startPrank(wNativeRelaterAdmin);
        address[] memory whitelistedCallers = new address[](1);
        whitelistedCallers[0] = DEXROUTER;
        IWNativeRelayerTest(wNativeRelater).setCallerOk(whitelistedCallers, true);
        vm.stopPrank();

    }

    function test_ETHWrapped_fromCommission() public {
        uint256 gas0 = swapWrapWithfromCommissionFromNative();

        setUp();
        uint256 gas1 = swapWrapWithoutCommissionFromNative();

        console2.log("ETHWrapped with commission need: %s", gas0 - gas1);
    }

    function test_WETHUnwrapped_fromCommission() public {
        uint256 gas0 = swapWrapWithfromCommissionToNative();

        setUp();
        uint256 gas1 = swapWrapWithoutCommissionToNative();

        console2.log("WETHUnwrapped with commission need: %s", gas0 - gas1);
    }

    function test_ETHWrapped_toCommission() public {
        uint256 gas0 = swapWrapWithtoCommissionFromNative();

        setUp();
        uint256 gas1 = swapWrapWithoutCommissionFromNative();

        console2.log("ETHWrapped with commission need: %s", gas0 - gas1);
    }

    function test_WETHUnwrapped_toCommission() public {
        uint256 gas0 = swapWrapWithToCommissionToNative();

        setUp();
        uint256 gas1 = swapWrapWithoutCommissionToNative();

        console2.log("WETHUnwrapped with commission need: %s", gas0 - gas1);
    }

    function test_TokenMismatch_Revert() public {
        toToken = WETH;
        fromToken = ETH;

        bytes memory commission_info = hex"3ca20afc2aaa00000000012c790ac11183ddE23163b307E3F7440F2460526957";
        
        bytes memory commission_token = abi.encode(uint160(WETH));
        
        bytes memory data = ETHtoWETHdata;
        data = bytes.concat(data, commission_token);
        data = bytes.concat(data, commission_info);
        
        vm.expectRevert(bytes("token and src not match"));
        (bool success, ) = payable(DEXROUTER).call{value: SwapAmount}(data);
    }

    function swapWrapWithoutCommissionFromNative() public returns (uint256){
        toToken = WETH;
        fromToken = ETH;

        uint256 before_referrer_balance = payable(referrer).balance;
        uint256 before_owner_balance = payable(address(this)).balance;
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        bytes memory data = ETHtoWETHdata;
        
        uint256 beforeGas = gasleft();
        (bool success, ) = payable(DEXROUTER).call{value: SwapAmount}(data);
        uint256 afterGas = gasleft();
        assert(success);
 
        uint256 after_referrer_balance = payable(referrer).balance;
        uint256 after_owner_balance = payable(address(this)).balance;
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        assert(after_referrer_balance == before_referrer_balance);
        assert(after_owner_balance == before_owner_balance - SwapAmount);
        assert(before_owner_toToken_balance + SwapAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
        // console2.log("test_smartSwapByOrderIdWithCommissionOnNative : %s", beforeGas - afterGas);
    }

    function swapWrapWithfromCommissionFromNative() public returns (uint256){
        toToken = WETH;
        fromToken = ETH;

        uint256 before_referrer_balance = payable(referrer).balance;
        uint256 before_owner_balance = payable(address(this)).balance;
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        bytes memory commission_info = hex"3ca20afc2aaa00000000012c790ac11183ddE23163b307E3F7440F2460526957";
        bytes memory commission_token = abi.encode(uint160(fromToken));   
        bytes memory data = ETHtoWETHdata;
        data = bytes.concat(data, commission_token);
        data = bytes.concat(data, commission_info);
         
        uint256 beforeGas = gasleft();
        (bool success, ) = payable(DEXROUTER).call{value: SwapAmount + 3092783505154639}(data);
        uint256 afterGas = gasleft();
        assert(success);
 
        uint256 after_referrer_balance = payable(referrer).balance;
        uint256 after_owner_balance = payable(address(this)).balance;
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        assert(after_referrer_balance == before_referrer_balance + 3092783505154639);
        assert(after_owner_balance == before_owner_balance - SwapAmount - 3092783505154639);
        assert(before_owner_toToken_balance + SwapAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
        //console2.log("test_smartSwapByOrderIdWithCommissionOnNative : %s", beforeGas - afterGas);
    }

    function swapWrapWithtoCommissionFromNative() public returns (uint256){
        toToken = WETH;
        fromToken = ETH;

        uint256 before_referrer_balance = IERC20(toToken).balanceOf(referrer);
        uint256 before_owner_balance = payable(address(this)).balance;
        uint256 before_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        bytes memory commission_info = hex"3ca20afc2bbb00000000012c790ac11183ddE23163b307E3F7440F2460526957";
        bytes memory commission_token = abi.encode(uint160(toToken));   
        bytes memory data = ETHtoWETHdata;
        data = bytes.concat(data, commission_token);
        data = bytes.concat(data, commission_info);

        uint256 beforeGas = gasleft();
        (bool success, ) = payable(DEXROUTER).call{value: SwapAmount}(data);
        uint256 afterGas = gasleft();
        assert(success);

        uint256 after_referrer_balance = IERC20(toToken).balanceOf(referrer);
        uint256 after_owner_balance = payable(address(this)).balance;
        uint256 after_owner_toToken_balance = IERC20(toToken).balanceOf(address(this));

        assert(after_referrer_balance == before_referrer_balance + 0.003 ether);
        assert(after_owner_balance == before_owner_balance - SwapAmount);
        assert(before_owner_toToken_balance + SwapAmount - 0.003 ether == after_owner_toToken_balance);

        return beforeGas - afterGas;
        // console2.log("test_smartSwapByOrderIdWithCommissionOnNative : %s", beforeGas - afterGas);
    }

    function swapWrapWithoutCommissionToNative() public returns (uint256){
        toToken = ETH;
        fromToken = WETH;
        SafeERC20.safeApprove(IERC20(fromToken), token_approve, 1 ether);
        vm.deal(DEXROUTER, 0);//clean dexrouter dust

        uint256 before_referrer_balance = IERC20(fromToken).balanceOf(referrer);
        uint256 before_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 before_owner_toToken_balance = payable(address(this)).balance;

        bytes memory data = WETHtoETHdata;
        
        uint256 beforeGas = gasleft();
        (bool success, ) = payable(DEXROUTER).call(data);
        uint256 afterGas = gasleft();
        assert(success);
 
        uint256 after_referrer_balance = IERC20(fromToken).balanceOf(referrer);
        uint256 after_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 after_owner_toToken_balance = payable(address(this)).balance;

        assert(after_referrer_balance == before_referrer_balance);
        assert(after_owner_balance == before_owner_balance - SwapAmount);
        assert(before_owner_toToken_balance + SwapAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
        // console2.log("test_smartSwapByOrderIdWithCommissionOnNative : %s", beforeGas - afterGas);
    }

    function swapWrapWithfromCommissionToNative() public returns (uint256){
        toToken = ETH;
        fromToken = WETH;
        SafeERC20.safeApprove(IERC20(fromToken), token_approve, 1 ether);
        vm.deal(DEXROUTER, 0);//clean dexrouter dust

        uint256 before_referrer_balance = IERC20(fromToken).balanceOf(referrer);
        uint256 before_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 before_owner_toToken_balance = payable(address(this)).balance;
        console.log("balance: %s", before_owner_toToken_balance);

        bytes memory commission_info = hex"3ca20afc2aaa00000000012c790ac11183ddE23163b307E3F7440F2460526957";
        bytes memory commission_token = abi.encode(uint160(fromToken));   
        bytes memory data = WETHtoETHdata;
        data = bytes.concat(data, commission_token);
        data = bytes.concat(data, commission_info);
        
        uint256 beforeGas = gasleft();
        (bool success, ) = payable(DEXROUTER).call(data);
        uint256 afterGas = gasleft();
        assert(success);
 
        uint256 after_referrer_balance = IERC20(fromToken).balanceOf(referrer);
        uint256 after_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 after_owner_toToken_balance = payable(address(this)).balance;

        console.log("balance: %s", after_owner_toToken_balance);
        assert(after_referrer_balance == before_referrer_balance + 3092783505154639);
        assert(after_owner_balance == before_owner_balance - SwapAmount - 3092783505154639);
        assert(before_owner_toToken_balance + SwapAmount == after_owner_toToken_balance);

        return beforeGas - afterGas;
        //console2.log("test_smartSwapByOrderIdWithCommissionOnNative : %s", beforeGas - afterGas);
    }

    function swapWrapWithToCommissionToNative() public returns (uint256){
        toToken = ETH;
        fromToken = WETH;
        SafeERC20.safeApprove(IERC20(fromToken), token_approve, 1 ether);
        vm.deal(DEXROUTER, 0);//clean dexrouter dust

        uint256 before_referrer_balance = payable(referrer).balance;
        uint256 before_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 before_owner_toToken_balance = payable(address(this)).balance;

        bytes memory commission_info = hex"3ca20afc2bbb00000000012c790ac11183ddE23163b307E3F7440F2460526957";
        bytes memory commission_token = abi.encode(uint160(toToken));
        bytes memory data = WETHtoETHdata;
        data = bytes.concat(data, commission_token);
        data = bytes.concat(data, commission_info);

        uint256 beforeGas = gasleft();
        (bool success, ) = payable(DEXROUTER).call(data);
        uint256 afterGas = gasleft();
        assert(success);

        uint256 after_referrer_balance = payable(referrer).balance;
        uint256 after_owner_balance = IERC20(fromToken).balanceOf(address(this));
        uint256 after_owner_toToken_balance = payable(address(this)).balance;

        assert(after_referrer_balance == before_referrer_balance + 0.003 ether);
        assert(after_owner_balance == before_owner_balance - SwapAmount);
        assert(before_owner_toToken_balance + SwapAmount - 0.003 ether == after_owner_toToken_balance);

        return beforeGas - afterGas;
        // console2.log("test_smartSwapByOrderIdWithCommissionOnNative : %s", beforeGas - afterGas);
    }

    receive() external payable {
    }
}