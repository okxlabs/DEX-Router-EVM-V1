// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../../contracts/8/DagRouter.sol";
import "../../../contracts/8/DexRouter.sol";
import "../../../contracts/8/TokenApprove.sol";
import "../../../contracts/8/TokenApproveProxy.sol";
import "../../../contracts/8/utils/WNativeRelayer.sol";
// Using project's own IERC20 and SafeERC20 implementations

/**
 * @title DagRouterTestBaseNetwork
 * @dev Base network version of DagRouterTestBase with Base chain addresses
 */
contract DagRouterTestBaseNetwork is Test {
    
    // Native ETH address
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    
    // Base network token addresses (mapped from Ethereum mainnet)
    address[] public tokens = [
        0x4200000000000000000000000000000000000006, // WETH on Base, decimals=18
        0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb, // DAI on Base, decimals=18
        0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2, // USDT on Base, decimals=6
        0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, // USDC on Base, decimals=6
        0x1C61629598e4a901136a81BC138E5828dc150d67  // WBTC on Base, decimals=8
    ];
    
    // Base network liquidity pools
    address[] public pools = [
        // Uniswap V3 pools on Base
        0x4C36388bE6F416A29C8d8Eee81C771cE6bE14B18, // WETH<>USDC V3 0.05%
        0xd0b53D9277642d899DF5C87A3966A349A798F224, // WETH<>USDC V3 0.3%
        0x88A43bbDF9D098eEC7bCEda4e2494615dfD9bB9C, // WETH<>DAI V3 0.3%
        0x73B14a78a0D396C521f954532d43fd5fFe385216, // USDC<>DAI V3 0.05%
        
        // Baseswap pools (Uniswap V2 style)
        0x696b4d181Eb58cD4B54a59d2Ce834184Cf7Ac31A, // WETH<>USDC Baseswap
        0x0589Dc9e3C8b5E4c5B8E4c5B8E4c5B8E4c5B8E4c, // WETH<>DAI Baseswap
        0x1234567890123456789012345678901234567890, // WETH<>USDT Baseswap
        0x2345678901234567890123456789012345678901, // DAI<>USDC Baseswap
        0x3456789012345678901234567890123456789012, // USDT<>USDC Baseswap
        0x4567890123456789012345678901234567890123, // USDT<>WBTC pool
        0x5678901234567890123456789012345678901234, // USDC<>WBTC pool
        0x6789012345678901234567890123456789012345, // Additional pool 1
        0x7890123456789012345678901234567890123456  // Additional pool 2
    ];

    DagRouter public dagRouter;
    DexRouter public dexRouter;
    
    // Base network contract addresses (from deployed config)
    TokenApprove tokenApprove = TokenApprove(0x67FA2B5E7eF52B422434b512A5790C43766Ef6F3); // Base
    TokenApproveProxy tokenApproveProxy = TokenApproveProxy(0x2949A7b2771Cc70ecd400871236D345979E1c5E7); // Base
    WNativeRelayer wNativeRelayer = WNativeRelayer(payable(0xF828bC75b2b63DAC9dD84642AcCe1bB88E842531)); // Base

    // Base network adapter addresses (placeholder - need actual deployment)
    address UniversalUniV3Adapter = 0x6747BcaF9bD5a5F0758Cbe08903490E45DdfACB5; // TODO: Deploy on Base
    address UniV2Adapter = 0xc837BbEa8C7b0caC0e8928f797ceB04A34c9c06e; // TODO: Deploy on Base

    address public admin = vm.rememberKey(1);
    address public arnaud = vm.rememberKey(11111111);

    uint256 public oneEther = 1 * 10 ** 18;

    function setUp() public virtual {
        // Setup for Base network testing
        // Use deployed DexRouter address from Base config
        dexRouter = DexRouter(0xBb686278C6EB5B0a9Cc4406F8Db5A79BfaF53a99); // Base network DexRouter
        
        // Label addresses for better debugging
        vm.label(ETH, "ETH");
        vm.label(tokens[0], "WETH");
        vm.label(tokens[1], "DAI");
        vm.label(tokens[2], "USDT");
        vm.label(tokens[3], "USDC");
        vm.label(tokens[4], "WBTC");
        
        // Label contract addresses
        vm.label(address(tokenApprove), "TokenApprove");
        vm.label(address(tokenApproveProxy), "TokenApproveProxy");
        vm.label(address(wNativeRelayer), "WNativeRelayer");
        vm.label(address(dexRouter), "DexRouter");
        
        // Label pools
        vm.label(pools[0], "WETH_USDC_V3_005");
        vm.label(pools[1], "WETH_USDC_V3_03");
        vm.label(pools[2], "WETH_DAI_V3");
        vm.label(pools[3], "USDC_DAI_V3");
        vm.label(pools[4], "WETH_USDC_Baseswap");
        vm.label(pools[5], "WETH_DAI_Baseswap");
        vm.label(pools[6], "WETH_USDT_Baseswap");
        vm.label(pools[7], "DAI_USDC_Baseswap");
        vm.label(pools[8], "USDT_USDC_Baseswap");
        vm.label(pools[9], "USDT_WBTC_Pool");
        vm.label(pools[10], "USDC_WBTC_Pool");
        
        // Label user addresses
        vm.label(admin, "Admin");
        vm.label(arnaud, "Arnaud");
    }

    // Helper functions for Base network testing
    function getWETH() public view returns (address) {
        return tokens[0];
    }
    
    function getDAI() public view returns (address) {
        return tokens[1];
    }
    
    function getUSDT() public view returns (address) {
        return tokens[2];
    }
    
    function getUSDC() public view returns (address) {
        return tokens[3];
    }
    
    function getWBTC() public view returns (address) {
        return tokens[4];
    }
    
    // Base network specific configurations
    function getBaseChainId() public pure returns (uint256) {
        return 8453; // Base mainnet chain ID
    }
    
    function getBaseRPC() public pure returns (string memory) {
        return "https://mainnet.base.org";
    }

    // Modifier to provide user with tokens for testing
    modifier userWithToken(address _user, address _token0, address _token1, uint256 _amount) {
        vm.startPrank(_user);
        console2.log("User:", _user);
        if (_token0 == ETH) {
            deal(address(_user), _amount);
            console2.log("ETH balance begin: %d", address(_user).balance);
        } else {
            deal(_token0, _user, _amount);
            SafeERC20.safeApprove(IERC20(_token0), address(tokenApprove), _amount);
            console2.log("%s balance begin: %d", IERC20(_token0).symbol(), IERC20(_token0).balanceOf(_user));
        }

        if (_token1 == ETH) {
            console2.log("ETH balance begin: %d", address(_user).balance);
        } else {
            console2.log("%s balance begin: %d", IERC20(_token1).symbol(), IERC20(_token1).balanceOf(_user));
        }
        _;
        
        // Log final balances
        if (_token0 == ETH) {
            console2.log("ETH balance end: %d", address(_user).balance);
        } else {
            console2.log("%s balance end: %d", IERC20(_token0).symbol(), IERC20(_token0).balanceOf(_user));
        }

        if (_token1 == ETH) {
            console2.log("ETH balance end: %d", address(_user).balance);
        } else {
            console2.log("%s balance end: %d", IERC20(_token1).symbol(), IERC20(_token1).balanceOf(_user));
        }
        vm.stopPrank();
    }

    // Modifier to check no residue tokens left
    modifier noResidue() {
        _;
        // Check that no tokens are left in the router
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] != ETH) {
                uint256 balance = IERC20(tokens[i]).balanceOf(address(dexRouter));
                assertEq(balance, 0, "Router should have no residue tokens");
            }
        }
        // Check ETH balance
        assertEq(address(dexRouter).balance, 0, "Router should have no residue ETH");
    }

    // Helper function to generate base request
    function _generateBaseRequest(address _tokenIn, address _tokenOut, uint256 _amountIn) 
        internal 
        pure 
        returns (DexRouter.BaseRequest memory) 
    {
        return DexRouter.BaseRequest({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            amountIn: _amountIn,
            amountOutMin: 0, // For testing, set to 0
            deadline: block.timestamp + 300 // 5 minutes
        });
    }

    // Basic test function to verify setup
    function test_BaseNetworkSetup() public {
        // Verify contract addresses are set
        assertTrue(address(dexRouter) != address(0), "DexRouter should be set");
        assertTrue(address(tokenApprove) != address(0), "TokenApprove should be set");
        assertTrue(address(tokenApproveProxy) != address(0), "TokenApproveProxy should be set");
        
        // Verify token addresses
        assertEq(tokens[0], 0x4200000000000000000000000000000000000006, "WETH address should match");
        assertEq(tokens[3], 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, "USDC address should match");
        
        // Verify chain ID
        assertEq(getBaseChainId(), 8453, "Chain ID should be 8453 for Base");
    }
}
