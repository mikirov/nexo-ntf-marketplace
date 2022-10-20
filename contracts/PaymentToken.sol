// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPaymentToken.sol";

contract PaymentToken is ERC20Permit, Ownable, IPaymentToken {
    constructor() ERC20Permit("Payment Token") ERC20("Payment Token", "PT") {}

    /// @notice we are allowing anyone to mint tokens for example purposes
    /// since this token is created by a contract that lives behind a proxy
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override(ERC20Permit, IPaymentToken)
{
        super.permit(owner, spender, value, deadline, v, r, s);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override(ERC20, IPaymentToken)
returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    function approve(address spender, uint256 amount) public override(ERC20, IPaymentToken) returns (bool) {
        return super.approve(spender, amount);
    }

    function balanceOf(address account) public view override(ERC20, IPaymentToken) returns (uint256) {
        return super.balanceOf(account);
    }
}
