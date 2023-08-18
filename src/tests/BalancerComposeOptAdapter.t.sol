pragma solidity 0.8.12;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/BalancerV2ComposableAdapter.sol";
import "@dex/interfaces/IERC20.sol";


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
        // problem
        // vm.createSelectFork("https://eth.llamarpc.com", 17875000);
        // vm.createSelectFork("https://eth.llamarpc.com", 17884740);

        // normal
        // vm.createSelectFork("https://eth.llamarpc.com", 17084740);
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 17899161);

        adapter = new BalancerV2ComposableAdapter(vault);
        deal(USDT, address(adapter), 2000 * 10 ** 6);
    }

    function test_BalancerV2Composable_oneStep_1() public {
        bytes32 bb_a_USDT = 0x2f4eb100552ef93840d5adc30560e5513dfffacb000000000000000000000334;
        bytes32 bb_a_USD = 0xa13a9247ea42d743238089903570127dda72fe4400000000000000000000035d;
        bytes32 bb_a_USDC = 0x82698aecc9e28e9bb27608bd52cf57f704bd1b83000000000000000000000336;
        Hop memory hop1 = Hop({
            poolId: bb_a_USDT,
            sourceToken: USDT,
            targetToken: 0x2F4eb100552ef93840d5aDC30560E5513DFfFACb
        });
        Hop memory hop2 = Hop({
            poolId: bb_a_USD,
            sourceToken: 0x2F4eb100552ef93840d5aDC30560E5513DFfFACb,
            targetToken: 0x82698aeCc9E28e9Bb27608Bd52cF57f704BD1B83
        });
        Hop memory hop3 = Hop({
            poolId: bb_a_USDC,
            sourceToken: 0x82698aeCc9E28e9Bb27608Bd52cF57f704BD1B83,
            targetToken: USDC
        });

        uint8 Hops = 3;

        bytes memory moreInfo = abi.encode(Hops, abi.encode(hop1, hop2, hop3));
        adapter.sellBase(address(this), address(0), moreInfo);

        uint256 after_balance = IERC20(USDC).balanceOf(address(this));
        console2.log(after_balance);
    }

}
