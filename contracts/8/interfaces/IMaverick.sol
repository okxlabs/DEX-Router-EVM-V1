// SPDX-License-Identifier: MIT
// https://github.com/maverickprotocol/maverick-v1-interfaces/blob/main/contracts/interfaces/IFactory.sol
pragma solidity ^0.8.0;

interface IPositionMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IPosition {
    event SetMetadata(IPositionMetadata metadata);
    /// @notice mint new position NFT

    function mint(address to) external returns (uint256 tokenId);
    /// @notice mint new position NFT
    function tokenOfOwnerByIndexExists(address owner, uint256 index)
        external
        view
        returns (bool);
}

interface IFactory {
    event PoolCreated(
        address poolAddress,
        uint256 fee,
        uint256 tickSpacing,
        int32 activeTick,
        int256 lookback,
        uint64 protocolFeeRatio,
        address tokenA,
        address tokenB
    );
    event SetFactoryProtocolFeeRatio(uint64 protocolFeeRatio);
    event SetFactoryOwner(address owner);
    /// @notice creates new pool
    /// @param _fee is a rate in prbmath 60x18 decimal format
    /// @param _tickSpacing  1.0001^tickSpacing is the bin width
    /// @param _activeTick initial activeTick of the pool
    /// @param _lookback TWAP lookback in whole seconds
    /// @param _tokenA ERC20 token
    /// @param _tokenB ERC20 token

    function create(
        uint256 _fee,
        uint256 _tickSpacing,
        int256 _lookback,
        int32 _activeTick,
        address _tokenA,
        address _tokenB
    ) external returns (IPool);
    function lookup(
        uint256 fee,
        uint256 tickSpacing,
        int256 lookback,
        address tokenA,
        address tokenB
    ) external view returns (IPool);
    function owner() external view returns (address);
    function position() external view returns (IPosition);
    /// @notice protocolFeeRatio ratio of the swap fee that is kept for the
    //protocol
    function protocolFeeRatio() external view returns (uint64);
    /// @notice lookup table for whether a pool is owned by the factory
    function isFactoryPool(IPool pool) external view returns (bool);
}

interface IPool {
    event Swap(
        address sender,
        address recipient,
        bool tokenAIn,
        bool exactOutput,
        uint256 amountIn,
        uint256 amountOut,
        int32 activeTick
    );
    event AddLiquidity(
        address indexed sender, uint256 indexed tokenId, BinDelta[] binDeltas
    );
    event MigrateBinsUpStack(address indexed sender, uint128 binId, uint32 maxRecursion);
    event TransferLiquidity(
        uint256 fromTokenId, uint256 toTokenId, RemoveLiquidityParams[] params
    );
    event RemoveLiquidity(
        address indexed sender,
        address indexed recipient,
        uint256 indexed tokenId,
        BinDelta[] binDeltas
    );
    event BinMerged(
        uint128 indexed binId, uint128 reserveA, uint128 reserveB, uint128 mergeId
    );
    event BinMoved(uint128 indexed binId, int128 previousTick, int128 newTick);
    event ProtocolFeeCollected(uint256 protocolFee, bool isTokenA);
    event SetProtocolFeeRatio(uint256 protocolFee);
    /// @notice return parameters for Add/Remove liquidity
    /// @param binId of the bin that changed
    /// @param kind one of the 4 Kinds (0=static, 1=right, 2=left, 3=both)
    /// @param isActive bool to indicate whether the bin is still active
    /// @param lowerTick is the lower price tick of the bin in its current state
    /// @param deltaA amount of A token that has been added or removed
    /// @param deltaB amount of B token that has been added or removed
    /// @param deltaLpToken amount of LP balance that has increase (add) or decreased (remove)

    struct BinDelta {
        uint128 deltaA;
        uint128 deltaB;
        uint256 deltaLpBalance;
        uint128 binId;
        uint8 kind;
        int32 lowerTick;
        bool isActive;
    }
    /// @notice time weighted average state
    /// @param twa the twa at the last update instant
    /// @param value the new value that was passed in at the last update
    /// @param lastTimestamp timestamp of the last update in seconds
    /// @param lookback time in seconds

    struct TwaState {
        int96 twa;
        int96 value;
        uint64 lastTimestamp;
    }
    /// @notice bin state parameters
    /// @param kind one of the 4 Kinds (0=static, 1=right, 2=left, 3=both)
    /// @param lowerTick is the lower price tick of the bin in its current state
    /// @param mergeId binId of the bin that this bin has merged in to
    /// @param reserveA amount of A token in bin
    /// @param reserveB amount of B token in bin
    /// @param totalSupply total amount of LP tokens in this bin
    /// @param mergeBinBalance LP token balance that this bin posseses of the merge bin

    struct BinState {
        uint128 reserveA;
        uint128 reserveB;
        uint128 mergeBinBalance;
        uint128 mergeId;
        uint128 totalSupply;
        uint8 kind;
        int32 lowerTick;
    }
    /// @notice Parameters for each bin that will get new liquidity
    /// @param kind one of the 4 Kinds (0=static, 1=right, 2=left, 3=both)
    /// @param pos bin position
    /// @param isDelta bool that indicates whether the bin position is relative
    //to the current bin or an absolute position
    /// @param deltaA amount of A token to add
    /// @param deltaB amount of B token to add

    struct AddLiquidityParams {
        uint8 kind;
        int32 pos;
        bool isDelta;
        uint128 deltaA;
        uint128 deltaB;
    }
    /// @notice Parameters for each bin that will have liquidity removed
    /// @param binId index of the bin losing liquidity
    /// @param amount LP balance amount to remove

    struct RemoveLiquidityParams {
        uint128 binId;
        uint128 amount;
    }
    /// @notice State of the pool
    /// @param activeTick  current bin position that contains the active bins
    /// @param status pool status.  e.g. locked or unlocked; status values
    //defined in Pool.sol
    /// @param binCounter index of the last bin created
    /// @param protocolFeeRatio ratio of the swap fee that is kept for the
    //protocol

    struct State {
        int32 activeTick;
        uint8 status;
        uint128 binCounter;
        uint64 protocolFeeRatio;
    }
    /// @notice fee for pool in 18 decimal format

    function fee() external view returns (uint256);
    /// @notice tickSpacing of pool where 1.0001^tickSpacing is the bin width
    function tickSpacing() external view returns (uint256);
    /// @notice address of token A
    function tokenA() external view returns (address);
    /// @notice address of token B
    function tokenB() external view returns (address);
    /// @notice address of Factory
    function factory() external view returns (IFactory);
    /// @notice bitmap of active bins
    function binMap(int32 tick) external view returns (uint256);
    /// @notice mapping of tick/kind to binId
    function binPositions(int32 tick, uint256 kind) external view returns (uint128);
    /// @notice internal accounting of the sum tokenA balance across bins
    function binBalanceA() external view returns (uint128);
    /// @notice internal accounting of the sum tokenB balance across bins
    function binBalanceB() external view returns (uint128);
    /// @notice Twa state values
    function getTwa() external view returns (TwaState memory);
    /// @notice log base binWidth of the time weighted average price
    function getCurrentTwa() external view returns (int256);
    /// @notice pool state
    function getState() external view returns (State memory);
    /// @notice Add liquidity to a pool.
    /// @param tokenId NFT token ID that will hold the position
    /// @param params array of AddLiquidityParams that specify the mode and
    //position of the liquidity
    /// @param data callback function that addLiquidity will call so that the
    //caller can transfer tokens
    function addLiquidity(
        uint256 tokenId,
        AddLiquidityParams[] calldata params,
        bytes calldata data
    )
        external
        returns (uint256 tokenAAmount, uint256 tokenBAmount, BinDelta[] memory binDeltas);
    /// @notice Transfer liquidity in an array of bins from one nft tokenId
    //to another
    /// @param fromTokenId NFT token ID that holds the position being transferred
    /// @param toTokenId NFT token ID that is receiving liquidity
    /// @param params array of binIds and amounts to transfer
    function transferLiquidity(
        uint256 fromTokenId,
        uint256 toTokenId,
        RemoveLiquidityParams[] calldata params
    ) external;
    /// @notice Remove liquidity from a pool.
    /// @param recipient address that will receive the removed tokens
    /// @param tokenId NFT token ID that holds the position being removed
    /// @param params array of RemoveLiquidityParams that specify the bins,
    //and amounts
    function removeLiquidity(
        address recipient,
        uint256 tokenId,
        RemoveLiquidityParams[] calldata params
    )
        external
        returns (uint256 tokenAOut, uint256 tokenBOut, BinDelta[] memory binDeltas);
    /// @notice Migrate bins up the linked list of merged bins so that its
    //mergeId is the currrent active bin.
    /// @param binId is an array of the binIds to be migrated
    /// @param maxRecursion is the maximum recursion depth of the migration. set to
    //zero to recurse until the active bin is found.
    function migrateBinUpStack(uint128 binId, uint32 maxRecursion) external;
    /// @notice swap tokens
    /// @param recipient address that will receive the output tokens
    /// @param amount amount of token that is either the input if exactOutput
    //is false or the output if exactOutput is true
    /// @param tokenAIn bool indicating whether tokenA is the input
    /// @param exactOutput bool indicating whether the amount specified is the
    //exact output amount (true)
    /// @param sqrtPriceLimit limiting sqrt price of the swap.  A value of 0
    //indicates no limit.  Limit is only engaged for exactOutput=false.  If the
    //limit is reached only part of the input amount will be swapped and the
    //callback will only require that amount of the swap to be paid.
    /// @param data callback function that swap will call so that the
    //caller can transfer tokens
    function swap(
        address recipient,
        uint256 amount,
        bool tokenAIn,
        bool exactOutput,
        uint256 sqrtPriceLimit,
        bytes calldata data
    ) external returns (uint256 amountIn, uint256 amountOut);
    /// @notice bin information for a given binId
    function getBin(uint128 binId) external view returns (BinState memory bin);
    /// @notice LP token balance for a given tokenId at a given binId
    function balanceOf(uint256 tokenId, uint128 binId)
        external
        view
        returns (uint256 lpToken);
    /// @notice tokenA scale value
    /// @dev msb is a flag to indicate whether tokenA has more or less than 18
    //decimals.  Scale is used in conjuction with Math.toScale/Math.fromScale
    //functions to convert from token amounts to D18 scale internal pool
    //accounting.
    function tokenAScale() external view returns (uint256);
    /// @notice tokenB scale value
    /// @dev msb is a flag to indicate whether tokenA has more or less than 18
    //decimals.  Scale is used in conjuction with Math.toScale/Math.fromScale
    //functions to convert from token amounts to D18 scale internal pool
    //accounting.
    function tokenBScale() external view returns (uint256);
}
