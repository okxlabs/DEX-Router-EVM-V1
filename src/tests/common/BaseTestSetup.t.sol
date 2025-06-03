// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "@dex/DexRouter.sol";
import "@dex/DexRouterExactOut.sol";
import "@dex/TokenApprove.sol";
import "@dex/TokenApproveProxy.sol";
import "@dex/utils/WNativeRelayer.sol";
import "@dex/interfaces/IWETH.sol";
import "@dex/interfaces/IUniswapV2Factory.sol";
import "@dex/interfaces/IUniswapV2Router02.sol";
import "@dex/interfaces/IUniswapV2Pair.sol";
import "@dex/interfaces/uniV3/IUniswapV3Factory.sol";
import "@dex/interfaces/uniV3/IUniswapV3Pool.sol";
import "@dex/interfaces/uniV3/INonfungiblePositionManager.sol";
import { MockERC20 } from "@dex/mock/MockERC20.sol";
import { CustomERC20 } from "@dex/mock/MeMeERC20.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

interface IUniswapV3MintCallback {
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

contract BaseTestSetup is Test, IUniswapV3MintCallback {
    DexRouterExactOut dexRouterExactOut;
    TokenApprove tokenApprove = TokenApprove(0x40aA958dd87FC8305b97f2BA922CDdCa374bcD7f);
    TokenApproveProxy tokenApproveProxy = TokenApproveProxy(0x70cBb871E8f30Fc8Ce23609E9E0Ea87B6b222F58);
    WNativeRelayer wNativeRelayer = WNativeRelayer(payable(0x5703B683c7F928b721CA95Da988d73a3299d4757));
    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Factory factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    IUniswapV3Factory v3Factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    INonfungiblePositionManager positionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address constant ETH = address(0);
    address constant COMMISSION_ETH = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    uint256 constant FOREVER = 2000000000;
    uint256 constant _WETH_UNWRAP_MASK = 1 << 253;

    MockERC20[] tokens;
    // address[][] pairs;
    address whale = makeAddr("whale");
    address amy = makeAddr("amy");
    address refererAddress = makeAddr("refererAddress");
    address refererAddress2 = makeAddr("refererAddress2");
    address admin = makeAddr("admin");
    
    address[][] public pairMatrix;
    address[][] public v3PairMatrix;
    
    uint256 internal constant FROM_TOKEN_COMMISSION =
        0x3ca20afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 internal constant TO_TOKEN_COMMISSION =
        0x3ca20afc2bbb0000000000000000000000000000000000000000000000000000;
    uint256 internal constant FROM_TOKEN_COMMISSION_DUAL =
        0x22220afc2aaa0000000000000000000000000000000000000000000000000000;
    uint256 internal constant TO_TOKEN_COMMISSION_DUAL =
        0x22220afc2bbb0000000000000000000000000000000000000000000000000000;
    
    // 设置测试环境
    function setUp() public virtual {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 21799331);
        
        setUpOKContracts();
        setUpMockTokens();
        setUpSwap();
    }

    function _buildPool(
        address sourceToken,
        address targetToken,
        address pool,
        bool isToETH
    ) 
    internal view returns (bytes32) {
        address token0 = IUniswapV2Pair(pool).token0();
        address token1 = IUniswapV2Pair(pool).token1();
        uint8 flag;
        uint8 flag2;
        if (sourceToken == token0) {
            require(targetToken == token1, "sourceToken is token0, targetToken must be token1");
            flag = uint8(0x00);
        } else {
            require(targetToken == token0, "sourceToken is token1, targetToken must be token0");
            flag = uint8(0x80);
        }
        if (isToETH) {
            require(targetToken == address(weth), "targetToken must be WETH");
            flag2 = uint8(0x40);
        }
        bytes32 poolData = bytes32(abi.encodePacked(uint8(flag2+flag), uint56(0), uint32(997000000), address(pool)));
        return poolData;
    }

    // Unified commission info builder for both single and dual commission
    // isFromTokenCommission和isToTokenCommission 不能同时为true和false
    // commissionRate和refererAddress必须同时有值
    // commissionRate2和refererAddress2必须同时有值
    function _buildCommissionInfoUnified(
        bool isFromTokenCommission,
        bool isToTokenCommission,
        address token,
        uint256 commissionRate,
        address refererAddress,
        uint256 commissionRate2,
        address refererAddress2
    ) internal pure returns (bytes memory) {
        // 校验 isFromTokenCommission 和 isToTokenCommission 不能同时为true或同时为false
        require(
            isFromTokenCommission != isToTokenCommission,
            "Exactly one of isFromTokenCommission or isToTokenCommission must be true"
        );
        // 校验 commissionRate 和 refererAddress 必须同时有值
        require(
            (commissionRate == 0 && refererAddress == address(0)) ||
            (commissionRate > 0 && refererAddress != address(0)),
            "commissionRate and refererAddress must both be set or both be unset"
        );
        // 校验 commissionRate2 和 refererAddress2 必须同时有值
        require(
            (commissionRate2 == 0 && refererAddress2 == address(0)) ||
            (commissionRate2 > 0 && refererAddress2 != address(0)),
            "commissionRate2 and refererAddress2 must both be set or both be unset"
        );
        if (refererAddress2 == address(0)) {
            // Single commission logic
            uint256 flagValue;
            if (isFromTokenCommission) {
                flagValue = FROM_TOKEN_COMMISSION;
            } else if (isToTokenCommission) {
                flagValue = TO_TOKEN_COMMISSION;
            } else {
                // unreachable, already checked
                return abi.encodePacked(token, bytes32(0));
            }
            return abi.encodePacked(
                token,
                bytes32(
                    (flagValue & 0xffffffffffff0000000000000000000000000000000000000000000000000000) |
                    ((uint256(commissionRate) << 160) & 0x000000000000ffffffffffff0000000000000000000000000000000000000000) |
                    (uint256(uint160(refererAddress)) & 0x00000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)
                )
            );
        } else {
            // Dual commission logic
            uint256 flagValue;
            if (isFromTokenCommission) {
                flagValue = FROM_TOKEN_COMMISSION_DUAL;
            } else if (isToTokenCommission) {
                flagValue = TO_TOKEN_COMMISSION_DUAL;
            } else {
                flagValue = FROM_TOKEN_COMMISSION_DUAL;
            }
            return abi.encodePacked(
                bytes32(
                    (flagValue & 0xffffffffffff0000000000000000000000000000000000000000000000000000) |
                    ((uint256(commissionRate2) << 160) & 0x000000000000ffffffffffff0000000000000000000000000000000000000000) |
                    (uint256(uint160(refererAddress2)) & 0x00000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)
                ),
                bytes32(uint256(uint160(token))),
                bytes32(
                    (flagValue & 0xffffffffffff0000000000000000000000000000000000000000000000000000) |
                    ((uint256(commissionRate) << 160) & 0x000000000000ffffffffffff0000000000000000000000000000000000000000) |
                    (uint256(uint160(refererAddress)) & 0x00000000000000000000000000ffffffffffffffffffffffffffffffffffffffff)
                )
            );
        }
    }

    function setUpMockTokens() internal {
        uint256 amountMint = 10000000000e18;
        uint256 amountTransfer = 10000e18;
        vm.startPrank(whale);
            tokens = new MockERC20[](5);
            MockERC20 mockWeth = MockERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
            vm.deal(whale, amountMint * 2);
            weth.deposit{value: amountMint}();
            MockERC20 aToken = new MockERC20("AToken", "aToken", amountMint);
            MockERC20 bToken = new MockERC20("BToken", "bToken", amountMint);
            MockERC20 cToken = new MockERC20("CToken", "cToken", amountMint);
            CustomERC20 _moonToken = new CustomERC20(whale, amountMint, "safemoon", "safemoon", uint8(18), 500,500,address(1),true);
            MockERC20 moonToken = MockERC20(address(_moonToken));
            tokens[0] = mockWeth;
            tokens[1] = aToken;
            tokens[2] = bToken;
            tokens[3] = cToken;
            tokens[4] = moonToken;

            weth.transfer(whale, amountTransfer);
            aToken.transfer(whale, amountTransfer);
            bToken.transfer(whale, amountTransfer);
            cToken.transfer(whale, amountTransfer);
            moonToken.transfer(whale, amountTransfer);
            vm.deal(amy, amountTransfer);
            mockWeth.transfer(amy, amountTransfer);
            aToken.transfer(amy, amountTransfer);
            bToken.transfer(amy, amountTransfer);
            cToken.transfer(amy, amountTransfer);
            moonToken.transfer(amy, amountTransfer);
        vm.stopPrank();
    }

    function setUpSwap() internal {
        uint256 liquidity = 10000e18;
        
        pairMatrix = new address[][](tokens.length);
        v3PairMatrix = new address[][](tokens.length);
        for(uint i = 0; i < tokens.length; i++) {
            pairMatrix[i] = new address[](tokens.length);
            v3PairMatrix[i] = new address[](tokens.length);
        }
        
        vm.startPrank(whale);
        for(uint i = 0; i < tokens.length; i++) {
            for(uint j = i + 1; j < tokens.length; j++) {
                address pair = factory.createPair(address(tokens[i]), address(tokens[j]));
                pairMatrix[i][j] = pair;
                pairMatrix[j][i] = pair;
                tokens[i].approve(address(router), liquidity);
                tokens[j].approve(address(router), liquidity);

                router.addLiquidity(
                    address(tokens[i]),
                    address(tokens[j]),
                    liquidity,
                    liquidity,
                    0,
                    0,
                    whale,
                    block.timestamp + 1
                );

                address v3Pair = v3Factory.createPool(address(tokens[i]), address(tokens[j]), 3000);

                v3PairMatrix[i][j] = v3Pair;
                v3PairMatrix[j][i] = v3Pair;
                
                uint160 sqrtPriceX96 = 79228162514264337593543950336;
                IUniswapV3Pool(v3Pair).initialize(sqrtPriceX96);
                
                tokens[i].approve(address(positionManager), type(uint256).max);
                tokens[j].approve(address(positionManager), type(uint256).max);
                
                int24 tickLower = -887220;
                int24 tickUpper = 887220;
                
                (address token0, address token1) = address(tokens[i]) < address(tokens[j]) 
                    ? (address(tokens[i]), address(tokens[j])) 
                    : (address(tokens[j]), address(tokens[i]));
                
                INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
                    token0: token0,
                    token1: token1,
                    fee: 3000,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    amount0Desired: liquidity,
                    amount1Desired: liquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    recipient: whale,
                    deadline: block.timestamp + 1
                });
                
                try positionManager.mint(params) 
                // returns (
                    // uint256 tokenId,
                    // uint128 liquidityAmount,
                    // uint256 amount0,
                    // uint256 amount1
                // )
                 {
                } catch {
                    console2.log("Failed to add liquidity to V3 pool for pair:", token0, token1);
                }
            }
        }
        // pairs = pairMatrix;
        vm.stopPrank();
    }

    // 获取pair地址的辅助函数
    function getPairAddress(uint i, uint j) public view returns (address) {
        require(i < tokens.length && j < tokens.length, "Index out of bounds");
        return pairMatrix[i][j];
    }

    function setUpOKContracts() internal {
        vm.startPrank(admin);
        dexRouterExactOut = new DexRouterExactOut();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(address(dexRouterExactOut), address(admin), abi.encodeWithSelector(DexRouterExactOut.initialize.selector));
        dexRouterExactOut = DexRouterExactOut(payable(address(proxy)));
        vm.stopPrank();
        address tokenApproveProxyOwner = tokenApproveProxy.owner();
        vm.startPrank(tokenApproveProxyOwner);
            tokenApproveProxy.addProxy(address(dexRouterExactOut));
            address[] memory whitelistedCallers = new address[](1);
            whitelistedCallers[0] = address(dexRouterExactOut);
            wNativeRelayer.setCallerOk(whitelistedCallers, true);
        vm.stopPrank();
    }

    // 实现UniswapV3MintCallback接口
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override {
        address payer = abi.decode(data, (address));
        
        address token0 = IUniswapV3Pool(msg.sender).token0();
        address token1 = IUniswapV3Pool(msg.sender).token1();
        
        if (amount0Owed > 0) {
            vm.startPrank(payer);
            MockERC20(token0).transfer(msg.sender, amount0Owed);
            vm.stopPrank();
        }
        
        if (amount1Owed > 0) {
            vm.startPrank(payer);
            MockERC20(token1).transfer(msg.sender, amount1Owed);
            vm.stopPrank();
        }
    }
} 