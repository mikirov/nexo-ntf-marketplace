// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 < 0.9.0;

interface ITicket
{
    function mint(
        uint256 tokenId,
        address to
    ) external;
}