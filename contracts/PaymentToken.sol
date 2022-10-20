// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 < 0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaymentToken is ERC20Permit, Ownable {
    constructor() 
    ERC20Permit("Payment Token") 
    ERC20("Payment Token", "PT") {
        _mint(msg.sender, 1000000000000000000000000);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}