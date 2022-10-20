// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 < 0.9.0;

interface ILottery {
    function buy(
        uint256 ticketId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s) external;

    function awardSurpriseWinner() external;

    function selectWinner() external;

    function claimRewards() external;
}