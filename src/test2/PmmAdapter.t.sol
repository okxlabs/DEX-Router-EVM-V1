// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import {ECDSA, OrderRFQLib, TestHelper} from "./helpers/RFQTestHelper.sol";
import {PMMAdapter} from "@dex/adapter/PmmAdapter.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// These helper contracts are used only by pmm adapter so we put them here.

contract MockERC20 is ERC20 {
    uint8 private _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

interface IPMMProtocol {
    struct OrderRFQ {
        uint256 rfqId; // 0x00
        uint256 expiry; // 0x20
        address makerAsset; // 0x40
        address takerAsset; // 0x60
        address makerAddress; // 0x80
        uint256 makerAmount; // 0xa0
        uint256 takerAmount; // 0xc0
        bool usePermit2; // 0xe0;
    }
    function fillOrderRFQTo(
        OrderRFQ memory order,
        bytes calldata signature,
        uint256 flagsAndAmount,
        address target
    ) external returns (uint256, uint256, bytes32);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


contract MockWETH is IWETH {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    receive() external payable {
        deposit();
    }

    function deposit() public payable override {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
        emit Transfer(address(0), msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public override {
        require(balanceOf[msg.sender] >= wad, "Insufficient balance");
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
        emit Transfer(msg.sender, address(0), wad);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad, "Insufficient balance");

        if (
            src != msg.sender && allowance[src][msg.sender] != type(uint256).max
        ) {
            require(
                allowance[src][msg.sender] >= wad,
                "Insufficient allowance"
            );
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);
        return true;
    }

    // Helper function for tests
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}

library Errors {
    error RFQ_InvalidMsgValue(uint256 rfqId);
    error RFQ_ETHTransferFailed(uint256 rfqId);
    error RFQ_EthDepositRejected();
    error RFQ_ZeroTargetIsForbidden(uint256 rfqId);
    error RFQ_BadSignature(uint256 rfqId);
    error RFQ_OrderExpired(uint256 rfqId);
    error RFQ_MakerAmountExceeded(uint256 rfqId);
    error RFQ_TakerAmountExceeded(uint256 rfqId);
    error RFQ_SwapWithZeroAmount(uint256 rfqId);
    error RFQ_InvalidatedOrder(uint256 rfqId);
}

contract MockErrorWrapper {
    function errorWrapperCall(address target, bytes memory data) public {
        (bool success, bytes memory res) = target.call(data);
        // require(success, string(res));
        if (!success) {
            _revert(res);
        }
    }

    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            assembly ("memory-safe") {
                revert(add(returndata, 0x20), mload(returndata))
            }
        } else {
            revert("adapter call failed");
        }
    }
}

contract PmmAdapterTest is TestHelper {
    PMMAdapter adapter;
    IPMMProtocol public pmmProtocol;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    MockWETH public weth;
    // // MockPMMSettler public settler; // Not needed as settler functionality is not implemented

    MockErrorWrapper errorWrapper;

    address public maker;
    address public taker;
    address public treasury;

    uint256 public constant INITIAL_BALANCE = 1000 * 1e18;
    uint256 public constant ORDER_ID = 1;
    uint256 public constant MAKING_AMOUNT = 100 * 1e18;
    uint256 public constant TAKING_AMOUNT = 200 * 1e18;

    function setUp() public {
        vm.createSelectFork("https://arb1.arbitrum.io/rpc", 365440142);
        adapter = new PMMAdapter();
        errorWrapper = new MockErrorWrapper();

        // 部署mock合约
        tokenA = new MockERC20("Token A", "TKNA", 18);
        tokenB = new MockERC20("Token B", "TKNB", 18);
        weth = new MockWETH();
        // settler = new MockPMMSettler(address(weth)); // Not needed as settler functionality is not implemented

        // fork arb pmm protocol address
        pmmProtocol = IPMMProtocol(0xECB4af3d1D3Ae2Ee0e3175e6C04fb69D824f062c);

        // 设置地址
        maker = MAKER_ADDRESS;
        taker = TAKER_ADDRESS;
    //     treasury = makeAddr("treasury");

        // 设置settler
        // settler.setTreasury(treasury); // Not needed as settler functionality is not implemented

        // 初始化余额
        tokenA.mint(maker, INITIAL_BALANCE);
        tokenB.mint(taker, INITIAL_BALANCE);
        tokenB.mint(address(adapter), INITIAL_BALANCE);
        weth.mint(maker, INITIAL_BALANCE);
        weth.mint(treasury, INITIAL_BALANCE);

        // 设置授权
        vm.prank(maker);
        tokenA.approve(address(pmmProtocol), type(uint256).max);

        vm.prank(maker);
        weth.approve(address(pmmProtocol), type(uint256).max);

        vm.prank(taker);
        tokenB.approve(address(pmmProtocol), type(uint256).max);

        // vm.prank(treasury);
        // tokenA.approve(address(settler), type(uint256).max);

        // vm.prank(treasury);
        // weth.approve(address(settler), type(uint256).max);
        // Settler approvals not needed as settler functionality is not implemented
    }

    function testSellBase() public {
        // 创建订单
        OrderRFQLib.OrderRFQ memory order = createOrder(
            1322341231,
            getFutureTimestamp(1 hours),
            address(tokenA),
            address(tokenB),
            maker,
            MAKING_AMOUNT,
            INITIAL_BALANCE,
            false
        );

        // 签名
        bytes memory signature = signOrder(
            order,
            pmmProtocol.DOMAIN_SEPARATOR(),
            MAKER_PRIVATE_KEY
        );

        // 记录初始余额
        uint256 makerTokenABefore = tokenA.balanceOf(maker);
        uint256 makerTokenBBefore = tokenB.balanceOf(maker);
        uint256 takerTokenABefore = tokenA.balanceOf(address(adapter));
        uint256 takerTokenBBefore = tokenB.balanceOf(address(adapter));

        console2.log(makerTokenABefore);
        console2.log(makerTokenBBefore);
        console2.log(takerTokenABefore);
        console2.log(takerTokenBBefore);


        // 执行交易
        // vm.prank(taker);
        // (
        //     uint256 filledMakingAmount,
        //     uint256 filledTakingAmount,
        //     bytes32 orderHash
        // ) = pmmProtocol.fillOrderRFQ(order, signature, 0);
        bytes memory moreInfo = abi.encode(order, signature, 0);
        adapter.sellBase(address(adapter), address(pmmProtocol), moreInfo);
        uint256 makerTokenAAfter = tokenA.balanceOf(maker);
        uint256 makerTokenBAfter = tokenB.balanceOf(maker);
        uint256 takerTokenAAfter = tokenA.balanceOf(address(adapter));
        uint256 takerTokenBAfter = tokenB.balanceOf(address(adapter));

        console2.log(makerTokenAAfter);
        console2.log(makerTokenBAfter);
        console2.log(takerTokenAAfter);
        console2.log(takerTokenBAfter);
    }

    function testBubbleRevert() public {
        // 创建订单
        OrderRFQLib.OrderRFQ memory order = createOrder(
            1322341231,
            getFutureTimestamp(1 hours),
            address(tokenA),
            address(tokenB),
            maker,
            MAKING_AMOUNT,
            TAKING_AMOUNT,
            false
        );

        // 签名
        bytes memory signature = signOrder(
            order,
            pmmProtocol.DOMAIN_SEPARATOR(),
            MAKER_PRIVATE_KEY
        );

        // 记录初始余额
        uint256 makerTokenABefore = tokenA.balanceOf(maker);
        uint256 makerTokenBBefore = tokenB.balanceOf(maker);
        uint256 takerTokenABefore = tokenA.balanceOf(taker);
        uint256 takerTokenBBefore = tokenB.balanceOf(taker);

        // 执行交易
        // vm.prank(taker);
        // (
        //     uint256 filledMakingAmount,
        //     uint256 filledTakingAmount,
        //     bytes32 orderHash
        // ) = pmmProtocol.fillOrderRFQ(order, signature, 0);
        bytes memory moreInfo = abi.encode(order, signature, 0);
        // adapter.sellBase(address(this), address(pmmProtocol), moreInfo);

        // NOTE: UNCOMMENT following code to test bubble revert

        // errorWrapper.errorWrapperCall(
        //     address(adapter),
        //     abi.encodeWithSelector(
        //         PMMAdapter.sellBase.selector,
        //         address(this),
        //         address(pmmProtocol),
        //         moreInfo
        //     )
        // );
    }
}
