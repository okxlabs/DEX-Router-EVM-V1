pragma solidity 0.8.19;

import "@dex/adapter/SyncSwapAdapter.sol";
import "forge-std/console2.sol";
import "forge-std/test.sol";

contract SyncSwapAdapterTest is Test {
    SyncSwapAdapter adapter;
    address BUSD = 0x7d43AABC515C356145049227CeE54B608342c0ad;
    address WETH_BUSD = 0x7f72E0D8e9AbF9133A92322b8B50BD8e0F9dcFCB;
    address WETH = 0xe5D7C2a44FfDDf6b295A15c148167daaAf5Cf34f;
    address constant VAULT = 0x7160570BB153Edd0Ea1775EC2b2Ac9b65F1aB61B;

    function setUp() public {
        vm.createSelectFork(vm.envString("LINEA_RPC_URL"), 49184);
        adapter = new SyncSwapAdapter();
        deal(WETH, address(this), 0.03 ether);
    }

    function test_gasConsumption() public {
        IERC20(WETH).transfer(address(VAULT), 0.03 ether);
        uint256 gas = gasleft();
        adapter.sellBase(address(this), WETH_BUSD, abi.encode(WETH));
        console2.log("gas", gas - gasleft()); //143976
    }
}
