// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC6909Claims {
    event OperatorSet(address indexed owner, address indexed operator, bool approved);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id, uint256 amount);

    event Transfer(address caller, address indexed from, address indexed to, uint256 indexed id, uint256 amount);

    function balanceOf(address owner, uint256 id) external view returns (uint256 amount);

    function allowance(address owner, address spender, uint256 id) external view returns (uint256 amount);

    function isOperator(address owner, address spender) external view returns (bool approved);

    function transfer(address receiver, uint256 id, uint256 amount) external returns (bool);

    function transferFrom(address sender, address receiver, uint256 id, uint256 amount) external returns (bool);

    function approve(address spender, uint256 id, uint256 amount) external returns (bool);

    function setOperator(address operator, bool approved) external returns (bool);
}