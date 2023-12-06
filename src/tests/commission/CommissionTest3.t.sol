// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";
import "@dex/DexRouter.sol";

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

contract T is Test {
    address DEXROUTER ;
    DexRouter dexrouter;

    uint256 internal constant _REFERRER_MASK = 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff;
    uint256 internal constant _COMMISSION_FEE_MASK = 0x000000ffffffffffffffffff0000000000000000000000000000000000000000;
    uint256 internal constant _COMMISSION_FLAG_MASK = 0xffffff0000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant NO_NEED_COMMISSION = uint256(0);

    address token_approve_proxy = 0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58;
    address token_approve = 0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f;
    address wNativeRelater = 0x5703B683c7F928b721CA95Da988d73a3299d4757;
    address shaneson = 0x790ac11183ddE23163b307E3F7440F2460526957;


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

    function test0() public {
        address referral = 0x94d3AF948652Ea2B272870ffA10Da3250e0A34c4;
        uint256 before_referral_balance = payable(referral).balance;
        bytes memory data = hex"9871efa40000000000000000000186b800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000160c8d2ea32400000000000000000000000000000000000000000000000d67ef7f2bfa9e12fe3a60000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000180000000000000003b6d0340bf3d800620dc6923d87468a345087bc99219c3a23ca20afc2aaa00000000004694d3af948652ea2b272870ffa10da3250e0a34c4";
        
        uint256 beforeGas = gasleft();
        (bool success, bytes memory b) = payable(DEXROUTER).call{value: 0.1 ether}(data);
        uint256 afterGas = gasleft();
        assert(success);

        uint256 after_referral_balance = payable(referral).balance;
        console2.log(before_referral_balance);
        console2.log(after_referral_balance);
        require(before_referral_balance + 700000000000000 == after_referral_balance, "check referral balance");
    }
}