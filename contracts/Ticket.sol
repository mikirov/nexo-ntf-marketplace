// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 < 0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./interfaces/ITicket.sol";

contract Ticket is ITicket, Ownable, ERC721Enumerable, ERC721Burnable {
 
    constructor() ERC721("Ticket", "TICKET") {}

    function mint(
        uint256 tokenId,
        address to
    ) external onlyOwner {
        _mint(to, tokenId);
    }

    function burn(uint256 tokenId) public override(ITicket, ERC721Burnable) onlyOwner {
        _burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable, ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}