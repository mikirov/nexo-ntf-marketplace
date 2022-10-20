// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "./interfaces/ILottery.sol";
import "./Ticket.sol";
import "./interfaces/IPaymentToken.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Lottery is ILottery, OwnableUpgradeable {

    /// @notice cannot be declared public or immutable since we are setting it up in the initialer for upgradability
    uint256 public saleStartTime;
    uint256 public saleDuration;


    uint256 public ticketPrice;
    address public winner;

    IPaymentToken public paymentToken;
    Ticket public ticket;

    error TicketSaleEnded();
    error TicketSaleNotEnded();

    modifier onlyWinner() {
        require(msg.sender == winner, "Only winner can call this function");
        _;
    }

    function initialize(bytes32 salt, address paymentTokenAddress) initializer public {
        __Ownable_init();

        saleStartTime = block.timestamp;
        saleDuration = 1 days;
        paymentToken = IPaymentToken(paymentTokenAddress);

        /// @notice specifying salt uses create2 opcode under the hood
        ticket = new Ticket{salt: salt}();

        /// @notice deploy a new ticket contract with create2
        // assembly {
        //     ticket := create2(0, add(type(Ticket).creationCode, 0x20), mload(code), salt)
        //     if iszero(extcodesize(ticket)) {
        //         revert(0, 0)
        //     }
        // }
    }

    function setTicketPrice(uint256 newTicketPrice) external onlyOwner {
        ticketPrice = newTicketPrice;
    }

    function setSaleDuration(uint256 newSaleDuration) external onlyOwner {
        saleDuration = newSaleDuration;
    }

    /// @notice function that allows a user to buy a ticket using an ERC20 token
    /// @notice we are using an ERC20 with permit so we can save gas from the otherwise used approve transaction
    /// @param ticketId - externaly stored id for our ticket. Stored inside the ticket URI
    /// @param deadline - deadline for the permit
    /// @param v - r - s - sig for permit
    function buy(
        uint256 ticketId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (block.timestamp > saleStartTime + saleDuration)
            revert TicketSaleEnded();

        paymentToken.permit(
            msg.sender,
            address(this),
            ticketPrice,
            deadline,
            v,
            r,
            s
        );

        bool success = paymentToken.transferFrom(
            msg.sender,
            address(this),
            ticketPrice
        );
        require(success);

        /// @notice we can set up and external ID primary key for the ticket that is stored in its URI
        ticket.mint(ticketId, msg.sender);
    }

    function _awardWinner(address winner, uint256 tokenAmount) internal {
        bool success = paymentToken.transferFrom(
            address(this),
            winner,
            tokenAmount
        );
        require(success);
    }

    function awardSurpriseWinner() external onlyOwner {
        /// @notice blockhash can be manipulated for block numbers in the past, this is not true randomness
        /// for true randomness use an oracle
        address currentWinner = ticket.ownerOf(ticket.tokenByIndex(uint(blockhash(block.number - 1)) % ticket.totalSupply()));
        
        _awardWinner(currentWinner, paymentToken.balanceOf(address(this)) / 2);
    }

    function selectWinner() external onlyOwner {
        if (block.timestamp < saleStartTime + saleDuration)
            revert TicketSaleNotEnded();

        winner = ticket.ownerOf(ticket.tokenByIndex(uint(blockhash(block.number - 1)) % ticket.totalSupply()));
    }

    function claimRewards() external onlyWinner {
        _awardWinner(msg.sender, paymentToken.balanceOf(address(this)) / 2);
    }
}
