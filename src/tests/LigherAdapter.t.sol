// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/test.sol";
import "forge-std/console2.sol";

import "@dex/adapter/LighterswapAdapter.sol";

contract LighterAdapterTest is Test {
    address private constant router = 0x033c00fd922AF40b6683Fe5371380831a5b81D57;
    address USDC_e = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8; //token1
    address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; //token0
    address WETH_USDC = 0xB8Df652Ccb5CB39Ac1cD98a899639F8463B103a8;
    LighterswapAdapter adapter;

    function setUp() public {
        vm.createSelectFork(vm.envString("ARBI_RPC_URL"), uint256(122144049 - 1));
        adapter = new LighterswapAdapter(router);
    }

    function test_sellQuote() public {
        deal(USDC_e, address(this), 2000 * 10 ** 6);
        IERC20(USDC_e).transfer(address(adapter), 2000 * 10 ** 6);
        // uint64 price = 184765;
        uint64 price = 500000;
        adapter.sellQuote(address(this), WETH_USDC, abi.encode(price, USDC_e, WETH));
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
        console2.log("USDC balance", IERC20(USDC_e).balanceOf(address(this)));
    }

    function test_sellBase() public {
        deal(WETH, address(this), 10 ether);
        IERC20(WETH).transfer(address(adapter), 10 ether);
        // uint price = 179671;
        uint price = 1;
        adapter.sellBase(address(this), WETH_USDC, abi.encode(price, WETH, USDC_e));
        console2.log("WETH balance", IERC20(WETH).balanceOf(address(this)));
        console2.log("USDC balance", IERC20(USDC_e).balanceOf(address(this)));
    }

    function _test_parseCallData() public {
        bytes memory data = hex"04000000000000000005000000000002d1bd00";
        address(this).call(data);
    }

    function _test_getLimitOrders() public {
        address pool = 0xB8Df652Ccb5CB39Ac1cD98a899639F8463B103a8;
        vm.startPrank(router);
        (
            uint32[] memory ids,
            address[] memory users,
            uint256[] memory amount0s,
            uint256[] memory amount1s,
            bool[] memory isAsks
        ) = ILighterPool(pool).getLimitOrders();
        for (uint256 i = 0; i < ids.length; i++) {
            console2.log("isAsk", isAsks[i]);
            console2.log("id: %d, amount0: %d, amount1: %d", ids[i], amount0s[i], amount1s[i]);
        }
    }

    fallback() external {
        uint8 isAskByte = uint8(parseCallData(18, 1));
        uint8 orderBookId = uint8(parseCallData(1, 1));
        uint8 batchSize = uint8(parseCallData(2, 1));
        uint256 amount = uint256(parseCallData(2, 8));
        uint256 price = uint256(parseCallData(10, 8));
        console2.log(isAskByte);
        console2.log(orderBookId);
        console2.log(batchSize);
        console2.log(price);
        console2.log(amount);
    }

    function parseCallData(uint256 startByte, uint256 length) private pure returns (uint256) {
        uint256 val;

        require(length <= 32, "Length limit is 32 bytes");

        require(length + startByte <= msg.data.length, "trying to read past end of calldata");

        assembly {
            val := calldataload(startByte)
        }

        val = val >> (256 - length * 8);

        return val;
    }
}
