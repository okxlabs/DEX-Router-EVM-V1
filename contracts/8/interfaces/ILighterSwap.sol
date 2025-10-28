/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface ILighterRouter {
    struct LimitOrder {
        uint32 id;
        address owner;
        uint256 amount0;
        uint256 amount1;
    }

    function getBestBid(uint8 orderBookId) external view returns (LimitOrder memory);

    function getBestAsk(uint8 orderBookId) external view returns (LimitOrder memory);

    function createMarketOrder(uint8 orderBookId, uint64 amount0Base, uint64 priceBase, bool isAsk) external;
}

interface ILighterPool {
    function orderBookId() external view returns (uint8);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function priceMultiplier() external view returns (uint256);

    function getLimitOrders()
        external
        view
        returns (uint32[] memory, address[] memory, uint256[] memory, uint256[] memory, bool[] memory);

    function sizeTick() external view returns (uint);

    function priceTick() external view returns (uint);
}
