pragma solidity 0.8.12;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/BalancerV2ComposableAdapter.sol";

contract BalancerV2ComposableAdapterTest is Test {
    BalancerV2ComposableAdapter adapter;
    address vault = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address bbaUSDT = 0x2F4eb100552ef93840d5aDC30560E5513DFfFACb;
    address bbaUSDC = 0x82698aeCc9E28e9Bb27608Bd52cF57f704BD1B83;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    struct Hop {
        bytes32 poolId;
        address sourceToken;
        address targetToken;
    }

    function setUp() public {
        vm.createSelectFork("https://eth.llamarpc.com", 17631980);
        adapter = new BalancerV2ComposableAdapter(vault);
        deal(USDT, address(this), 10 ** 6);
    }

    function test_1() public {
        Hop memory hop1 =
            Hop(bytes32(0x2f4eb100552ef93840d5adc30560e5513dfffacb000000000000000000000334), USDT, bbaUSDT);
        Hop memory hop2 =
            Hop(bytes32(0xa13a9247ea42d743238089903570127dda72fe4400000000000000000000035d), bbaUSDT, bbaUSDC);
        bytes memory data = abi.encode(hop1, hop2);
        USDT.call(abi.encodeWithSelector(IERC20.transfer.selector, address(adapter), 10 ** 6));
        adapter.sellBase(address(this), address(0), abi.encode(uint8(2), data));
        console2.log(IERC20(bbaUSDC).balanceOf(address(this)));
    }

    function test_2() public {
        Hop memory hop1 =
            Hop(bytes32(0x2f4eb100552ef93840d5adc30560e5513dfffacb000000000000000000000334), USDT, bbaUSDT);
        Hop memory hop2 =
            Hop(bytes32(0xa13a9247ea42d743238089903570127dda72fe4400000000000000000000035d), bbaUSDT, bbaUSDC);
        Hop memory hop3 =
            Hop(bytes32(0x82698aecc9e28e9bb27608bd52cf57f704bd1b83000000000000000000000336), bbaUSDC, USDC);
        bytes memory data = abi.encode(hop1, hop2, hop3);
        USDT.call(abi.encodeWithSelector(IERC20.transfer.selector, address(adapter), 10 ** 6));
        adapter.sellBase(address(this), address(0), abi.encode(uint8(3), data));
        console2.log(IERC20(USDC).balanceOf(address(this)));
    }
}
