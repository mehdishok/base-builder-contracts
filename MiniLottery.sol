// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title MiniLottery
/// @notice Simple lottery with 0.001 ETH ticket price
contract MiniLottery {
    address public immutable owner;
    address[] public players;
    uint256 public constant TICKET_PRICE = 0.001 ether;
    bool public isOpen = true;
    address public lastWinner;
    uint256 public lastPrize;

    error NotOwner();
    error LotteryClosed();
    error IncorrectTicketPrice();
    error NoPlayers();
    error TransferFailed();

    event PlayerEntered(address indexed player);
    event WinnerPicked(address indexed winner, uint256 prize);
    event LotteryReset();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function enter() external payable {
        if (!isOpen) revert LotteryClosed();
        if (msg.value != TICKET_PRICE) revert IncorrectTicketPrice();

        players.push(msg.sender);
        emit PlayerEntered(msg.sender);
    }

    function getPlayers() external view returns (address[] memory) {
        return players;
    }

    function getPlayerCount() external view returns (uint256) {
        return players.length;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function pickWinner() external onlyOwner {
        if (players.length == 0) revert NoPlayers();
        if (!isOpen) revert LotteryClosed();

        uint256 index = uint256(
            keccak256(abi.encodePacked(block.timestamp, block.prevrandao, players.length, msg.sender))
        ) % players.length;

        address winner = players[index];
        uint256 prize = address(this).balance;

        isOpen = false;
        lastWinner = winner;
        lastPrize = prize;

        (bool success, ) = payable(winner).call{value: prize}("");
        if (!success) revert TransferFailed();

        emit WinnerPicked(winner, prize);
    }

    function resetLottery() external onlyOwner {
        delete players;
        isOpen = true;
        emit LotteryReset();
    }
}