/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

interface IArenaTokenManager {
    struct TokenParameters {
        uint128 curveScaler;
        uint16 a; // quadratic multiplier
        uint8 b; // linear multiplier
        bool lpDeployed;
        uint8 lpPercentage;
        uint8 salePercentage;
        uint8 creatorFeeBasisPoints;
        address creatorAddress;
        address pairAddress;
        address tokenContractAddress;
    }

    struct FeeData {
        uint256 protocolFee;
        uint256 creatorFee;
        uint256 referralFee;
        uint256 totalFeeAmount;
        address tokenCreator;
        address referrerAddress;
    }

    /**
     * @notice Buys tokens for the specified token.
     * @param amount The amount of tokens to buy.
     * @param _tokenId The ID of the token to buy tokens from.
     * @dev this function doesnt duplicate the whenNotPaused & lpNotDeployed modifiers
     * and relies on buy to enforce them. Any further development needs to keep that in mind.
     * @dev There is no slippage check and this intended.
     */
    function buyAndCreateLpIfPossible(uint256 amount, uint256 _tokenId) external payable;

    /**
     * @notice Sells tokens for the specified token.
     * @param amount The amount of tokens to sell.
     * @param _tokenId The ID of the token to sell tokens from.
     * @dev There is no slippage check and this intended.
     */
    function sell(uint256 amount, uint256 _tokenId) external;

    /**
     * @notice Returns the parameters of a token.
     * @param _tokenId The ID of the token.
     * @return The parameters of the token.
     */
    function tokenParams(uint256 _tokenId) external view returns (TokenParameters memory);

    /**
     * @notice Calculates the cost to buy a given amount of tokens for a token.
     * @param amountInToken amount in tokens (not in wei).
     * @param _tokenId The ID of the token.
     * @param totalSupply current tokenSupply in ether
     * @return The cost to buy the given amount of tokens and the current supply.
     */
    function calculateCostWithSupply(uint256 amountInToken, uint256 _tokenId, uint256 totalSupply) external view returns (uint256);

    /**
     * @notice Calculates the reward for selling a given amount of tokens for a token.
     * @param amount The amount of tokens to sell.
     * @param _tokenId The ID of the token.
     * @return The reward for selling the given amount of tokens.
     */
    function calculateRewardAndSupply(uint256 amount, uint256 _tokenId) external view returns (uint256, uint256);

    /**
     * @notice Calculates the fees for a given amount and referrer.
     * @param _rawCosts The amount to calculate fees for.
     * @param _tokenId token id.
     * @param _user to determine the referral fee.
     *
     * @return feeData the complete feeData.
     */
    function getFeeData(uint256 _tokenId, uint256 _rawCosts, address _user) external view returns (FeeData memory feeData);
}
