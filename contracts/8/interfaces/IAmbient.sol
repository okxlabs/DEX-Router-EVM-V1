// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IAmbient {

    /* @notice Swaps between two tokens within a single liquidity pool.
     *
     * @dev This is the most gas optimized swap call, since it avoids calling out to any
     *      proxy contract. However there's a possibility in the future that this call 
     *      path could be disabled to support upgraded logic. In which case the caller 
     *      should be able to swap through using a userCmd() call on the HOT_PATH proxy
     *      call path.
     * 
     * @param base The base-side token of the pair. (For native Ethereum use 0x0)
     * @param quote The quote-side token of the pair.
     * @param poolIdx The index of the pool type to execute on.
     * @param isBuy If true the direction of the swap is for the user to send base tokens
     *              and receive back quote tokens.
     * @param inBaseQty If true the quantity is denominated in base-side tokens. If not
     *                  use quote-side tokens.
     * @param qty The quantity of tokens to swap. End result could be less if the pool 
     *            price reaches limitPrice before exhausting.
     * @param tip A user-designated liquidity fee paid to the LPs in the pool. If set to
     *            0, just defaults to the standard pool rate. Otherwise represents the
     *            proposed LP fee in units of 1/1,000,000. Not used in standard swap 
     *            calls, but may be used in certain permissioned or dynamic fee pools.
     * @param limitPrice The worse price the user is willing to pay on the margin. Swap
     *                   will execute up to this price, but not any worse. Average fill 
     *                   price will always be equal or better, because this is calculated
     *                   at the marginal unit of quantity.
     * @param minOut The minimum output the user expects from the swap. If less is 
     *               returned, the transaction will revert. (Alternatively if the swap
     *               is fixed in terms of output, this is the maximum input.)
     * @param reserveFlags Bitwise flags to indicate if the user wants to pay/receive in
     *                     terms of surplus collateral balance held at the dex contract.
     *                          0x1 - Base token is paid/received from surplus collateral
     *                          0x2 - Quote token is paid/received from surplus collateral
     * @return The token base and quote token flows associated with this swap action. 
     *         (Negative indicates a credit paid to the user, positive a debit collected
     *         from the user) */
    function swap (address base, address quote,
                   uint256 poolIdx, bool isBuy, bool inBaseQty, uint128 qty, uint16 tip,
                   uint128 limitPrice, uint128 minOut,
                   uint8 reserveFlags) 
        external payable returns (int128 baseQuote, int128 quoteFlow);
    
    /* @notice Consolidated method for protocol control related commands.
     * @dev    We consolidate multiple protocol control types into a single method to 
     *         reduce the contract size in the main contract by paring down methods.
     * 
     * @param callpath The proxy sidecar callpath called into. (Calls into proxyCmd() on
     *                 the respective sidecare contract)
     * @param cmd      The arbitrary byte calldata corresponding to the command. Format
     *                 dependent on the specific callpath.
     * @param sudo     If true, indicates that the command should be called with elevated
     *                 privileges. */
    function protocolCmd (uint16 callpath, bytes calldata cmd, bool sudo)
        external payable;

    /* @notice Calls an arbitrary command on one of the sidecar proxy contracts at a specific
     *         index. Not all proxy slots may have a contract attached. If so, this call will
     *         fail.
     *
     * @param callpath The index of the proxy sidecar the command is being called on.
     * @param cmd The arbitrary call data the client is calling the proxy sidecar.
     * @return Arbitrary byte data (if any) returned by the command. */
    function userCmd (uint16 callpath, bytes calldata cmd)
        external payable returns (bytes memory);
    
    /* @notice Calls an arbitrary command on behalf of another user who has signed an 
     *         EIP-712 off-chain transaction. Same general call logic as userCmd(), but
     *         with additional args for conditions, and relayer payment.
     *
     * @param callpath The index of the proxy sidecar the command is being called on.
     * @param cmd The arbitrary call data the client is calling the proxy sidecar.
     * @param conds An ABI encoded list of evaluation conditions that are required for 
     *              this command to execute. See AgentMask.sol for format of this data.
     * @param relayerTip An ABI encoded directive for tipping the relayer on behalf of
     *                   the underlying client, for having mined the transaction. If this
     *                   byte array is empty no calldata. See AgentMask.sol for format 
     *                   details.
     * @param signature The ERC-712 signature of the above parameters signed by the 
     *                  private key of the public address the command is being executed 
     *                  for.
     * @return Arbitrary byte data (if any) returned by the command. */
    function userCmdRelayer (uint16 callpath, bytes calldata cmd,
                             bytes calldata conds, bytes calldata relayerTip, 
                             bytes calldata signature)
        external payable returns (bytes memory);

    /* @notice Calls an arbitrary command on behalf of a user from a (pre-approved) 
     *         external router contract acting as an agent on the user's behalf.
     *
     * @dev This can only be called when the underlying user has previously approved the
     *      msg.sender address as a router on its behalf.
     *
     * @param callpath The index of the proxy sidecar the command is being called on.
     * @param cmd The arbitrary call data the client is calling the proxy sidecar.
     * @param client The address of the client the router is calling on behalf of.
     * @return Arbitrary byte data (if any) returned by the command. */
    function userCmdRouter (uint16 callpath, bytes calldata cmd, address client)
        external payable returns (bytes memory);

    /* @notice General purpose query fuction for reading arbitrary data from the dex.
     * @dev    This function is bare bones, because we're trying to keep the size 
     *         footprint of CrocSwapDex down. See SlotLocations.sol and QueryHelper.sol 
     *         for syntactic sugar around accessing/parsing specific data. */
    function readSlot (uint256 slot)
        external view returns (uint256 data);

}