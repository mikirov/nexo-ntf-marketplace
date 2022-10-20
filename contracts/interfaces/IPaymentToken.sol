// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 < 0.9.0;

interface IPaymentToken
{
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external; 

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);
}