// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IAdapter.sol";
import "../interfaces/IPolygonMigration.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWETH.sol";
import "../libraries/SafeERC20.sol";

contract PolygonMigrationAdapter is IAdapter {

    address public immutable PolygonMigration;
    address public immutable MATIC;
    address public immutable POL;

    constructor (
        address _PolygonMigration,
        address _MATIC,
        address _POL
    ) {
        PolygonMigration = _PolygonMigration;
        MATIC = _MATIC;
        POL = _POL;
    }

    // fromToken == MATIC
    function sellBase(
        address to,
        address ,
        bytes memory
    ) external override {
        uint256 amountIn = IERC20(MATIC).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(MATIC),
            PolygonMigration,
            amountIn
        );
        IPolygonMigration(PolygonMigration).migrate(amountIn);
        SafeERC20.safeTransfer(
            IERC20(POL),
            to,
            IERC20(POL).balanceOf(address(this))
        );
    }

    // fromToken == POL
    function sellQuote(
        address to,
        address ,
        bytes memory
    ) external override {
        uint256 amountIn = IERC20(POL).balanceOf(address(this));
        SafeERC20.safeApprove(
            IERC20(POL),
            PolygonMigration,
            amountIn
        );
        IPolygonMigration(PolygonMigration).unmigrateTo(to, amountIn);
    }
}