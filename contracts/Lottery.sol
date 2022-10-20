// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 <0.9.0;

import "./interfaces/ILottery.sol";
import "./Ticket.sol";
import "./interfaces/IPaymentToken.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "hardhat/console.sol";
contract Lottery is ILottery, OwnableUpgradeable {

    /// @notice cannot be declared public or immutable since we are setting it up in the initialer for upgradability
    uint256 public saleStartTime;
    uint256 public saleDuration;


    uint256 public ticketPrice;
    address public winner;
    uint256 public winnerTicketId;

    IPaymentToken public paymentToken;
    Ticket public ticket;

    error TicketSaleEnded();
    error TicketSaleNotEnded();
    error NoTicketsSold();
    error NoWinnerTicketId();

    modifier onlyWinner() {
        require(msg.sender == winner, "Only winner can call this function");
        _;
    }

    function initialize(bytes32 salt, address paymentTokenAddress, uint256 newTicketPrice) initializer public {
        __Ownable_init();

        saleStartTime = block.timestamp;
        saleDuration = 1 days;
        ticketPrice = newTicketPrice;
        paymentToken = IPaymentToken(paymentTokenAddress);
        paymentToken.approve(address(this), type(uint256).max);

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
    function buyPermit(
        uint256 ticketId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        paymentToken.permit(
            msg.sender,
            address(this),
            ticketPrice,
            deadline,
            v,
            r,
            s
        );

        _buy(ticketId);
    }

    function buy(uint256 ticketId) external
    {
        _buy(ticketId);
    }

    function _buy(uint256 ticketId) internal
    {
        console.log('current contract address: ', address(this));
        if (block.timestamp > saleStartTime + saleDuration)
            revert TicketSaleEnded();

        bool success = paymentToken.transferFrom(
            msg.sender,
            address(this),
            ticketPrice
        );
        require(success);

        /// @notice we can set up and external ID primary key for the ticket that is stored in its URI
        ticket.mint(ticketId, msg.sender);
    }

    function awardSurpriseWinner() external onlyOwner {
        if(ticket.totalSupply() == 0)
            revert NoTicketsSold();

        /// @notice blockhash can be manipulated for block numbers in the past, this is not true randomness
        /// for true randomness use an oracle
        uint256 winnerIndex = uint(blockhash(block.number - 1)) % ticket.totalSupply();
        uint256 tickedId = ticket.tokenByIndex(winnerIndex % ticket.totalSupply());
        address currentWinner = ticket.ownerOf(tickedId);

        _awardWinner(currentWinner, tickedId, paymentToken.balanceOf(address(this)) / 2);
    }

    function selectWinner() external onlyOwner {
        if (block.timestamp < saleStartTime + saleDuration)
            revert TicketSaleNotEnded();

        if(ticket.totalSupply() == 0)
            revert NoTicketsSold();
        /// @notice blockhash can be manipulated for block numbers in the past, this is not true randomness
        /// for true randomness use an oracle
        uint256 winnerIndex = uint(blockhash(block.number - 1)) % ticket.totalSupply();
        winnerTicketId = ticket.tokenByIndex(winnerIndex % ticket.totalSupply());
        winner = ticket.ownerOf(winnerTicketId);
    }

    function claimRewards() external onlyWinner {
        if(winnerTicketId == 0)
            revert NoWinnerTicketId();

        if(ticket.balanceOf(msg.sender) == 0)
            revert NoTicketsSold();

        _awardWinner(msg.sender, winnerTicketId, paymentToken.balanceOf(address(this)));

        winnerTicketId = 0;
        winner = address(0);
    }

    function _awardWinner(address account, uint256 ticketId, uint256 tokenAmount) internal {
        bool success = paymentToken.transferFrom(
            address(this),
            account,
            tokenAmount
        );
        require(success);

        ticket.burn(ticketId);
    }
}
