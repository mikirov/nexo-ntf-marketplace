// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 < 0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./interfaces/ITicket.sol";

contract Ticket is ITicket, Ownable, ERC721Enumerable {
 
    constructor() ERC721("Ticket", "TICKET") {}

    function mint(
        uint256 tokenId,
        address to
    ) external onlyOwner {
        _safeMint(to, tokenId);
    }
}